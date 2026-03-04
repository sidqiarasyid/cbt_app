import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/services/offline_exam_storage.dart';

/// Service untuk mensinkronkan data offline ke server saat kembali online.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final ExamService _examService = ExamService();
  bool _isSyncing = false;
  Timer? _syncTimer;

  /// Callback yang dipanggil saat sync berhasil
  VoidCallback? onSyncComplete;

  /// Callback yang dipanggil saat sync gagal
  Function(String error)? onSyncError;

  /// Callback untuk update status sync
  Function(String status)? onSyncStatusChanged;

  /// Mulai periodic sync check (setiap 30 detik)
  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAllPending();
    });
  }

  /// Berhenti periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Cek koneksi internet
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sinkronkan semua pending data (jawaban + finish)
  Future<SyncResult> syncAllPending() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sinkronisasi sedang berjalan',
      );
    }

    _isSyncing = true;
    onSyncStatusChanged?.call('Memeriksa koneksi...');

    try {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return SyncResult(
          success: false,
          message: 'Tidak ada koneksi internet',
        );
      }

      onSyncStatusChanged?.call('Mensinkronkan jawaban...');

      int syncedAnswers = 0;
      int failedAnswers = 0;
      int syncedFinish = 0;
      int failedFinish = 0;

      // 1. Sync pending answers
      // We need to get all possible exam participant IDs from pending finish list
      final pendingFinishIds = await OfflineExamStorage.getPendingFinishExams();
      
      for (final participantId in pendingFinishIds) {
        final pendingAnswers = await OfflineExamStorage.getPendingAnswers(participantId);
        
        for (final answer in pendingAnswers) {
          try {
            final quizType = answer['quiz_type'] as String?;
            
            if (quizType == 'ESSAY') {
              await _examService.submitAnswer(
                examParticipantId: answer['exam_participant_id'] as int,
                questionId: answer['question_id'] as int,
                answerText: answer['answer_text'] as String?,
              );
            } else if (quizType == 'SINGLE_CHOICE') {
              await _examService.submitAnswer(
                examParticipantId: answer['exam_participant_id'] as int,
                questionId: answer['question_id'] as int,
                answerOptionId: answer['answer_option_id'] as int?,
              );
            } else if (quizType == 'MULTIPLE_CHOICE') {
              final optionIds = answer['answer_option_ids'] != null
                  ? List<int>.from(answer['answer_option_ids'])
                  : <int>[];
              await _examService.submitAnswer(
                examParticipantId: answer['exam_participant_id'] as int,
                questionId: answer['question_id'] as int,
                answerOptionIds: optionIds,
              );
            }

            await OfflineExamStorage.removePendingAnswer(
              answer['exam_participant_id'] as int,
              answer['question_id'] as int,
            );
            syncedAnswers++;
          } catch (e) {
            debugPrint('[OfflineSync] Failed to sync answer: $e');
            failedAnswers++;
          }
        }
      }

      // 2. Sync pending finish exams
      onSyncStatusChanged?.call('Menyelesaikan ujian pending...');

      for (final participantId in pendingFinishIds) {
        try {
          // Check if there are still pending answers for this exam
          final remaining = await OfflineExamStorage.getPendingAnswers(participantId);
          if (remaining.isNotEmpty) {
            debugPrint('[OfflineSync] Skipping finish for $participantId - still has ${remaining.length} pending answers');
            continue;
          }

          await _examService.finishExam(participantId);
          await OfflineExamStorage.removePendingFinish(participantId);
          syncedFinish++;
        } catch (e) {
          debugPrint('[OfflineSync] Failed to finish exam $participantId: $e');
          failedFinish++;
        }
      }

      final message = 'Sync selesai: $syncedAnswers jawaban disinkronkan'
          '${failedAnswers > 0 ? ', $failedAnswers gagal' : ''}'
          '${syncedFinish > 0 ? ', $syncedFinish ujian diselesaikan' : ''}'
          '${failedFinish > 0 ? ', $failedFinish ujian gagal diselesaikan' : ''}';

      onSyncStatusChanged?.call(message);

      if (syncedAnswers > 0 || syncedFinish > 0) {
        onSyncComplete?.call();
      }

      return SyncResult(
        success: failedAnswers == 0 && failedFinish == 0,
        message: message,
        syncedAnswers: syncedAnswers,
        failedAnswers: failedAnswers,
        syncedFinish: syncedFinish,
        failedFinish: failedFinish,
      );
    } catch (e) {
      final errorMsg = 'Gagal sinkronisasi: $e';
      onSyncError?.call(errorMsg);
      return SyncResult(success: false, message: errorMsg);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sinkronkan jawaban untuk satu ujian tertentu
  Future<bool> syncAnswersForExam(int examParticipantId) async {
    try {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) return false;

      final pendingAnswers = await OfflineExamStorage.getPendingAnswers(examParticipantId);

      for (final answer in pendingAnswers) {
        final quizType = answer['quiz_type'] as String?;

        if (quizType == 'ESSAY') {
          await _examService.submitAnswer(
            examParticipantId: examParticipantId,
            questionId: answer['question_id'] as int,
            answerText: answer['answer_text'] as String?,
          );
        } else if (quizType == 'SINGLE_CHOICE') {
          await _examService.submitAnswer(
            examParticipantId: examParticipantId,
            questionId: answer['question_id'] as int,
            answerOptionId: answer['answer_option_id'] as int?,
          );
        } else if (quizType == 'MULTIPLE_CHOICE') {
          final optionIds = answer['answer_option_ids'] != null
              ? List<int>.from(answer['answer_option_ids'])
              : <int>[];
          await _examService.submitAnswer(
            examParticipantId: examParticipantId,
            questionId: answer['question_id'] as int,
            answerOptionIds: optionIds,
          );
        }

        await OfflineExamStorage.removePendingAnswer(
          examParticipantId,
          answer['question_id'] as int,
        );
      }

      return true;
    } catch (e) {
      debugPrint('[OfflineSync] syncAnswersForExam failed: $e');
      return false;
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedAnswers;
  final int failedAnswers;
  final int syncedFinish;
  final int failedFinish;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedAnswers = 0,
    this.failedAnswers = 0,
    this.syncedFinish = 0,
    this.failedFinish = 0,
  });
}
