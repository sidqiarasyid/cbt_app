import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/models/exam_result_response_model.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/services/offline_exam_storage.dart';
import 'package:cbt_app/services/offline_sync_service.dart';
import 'package:cbt_app/utils/helpers.dart';

class UjianController {
  final ExamService _examService = ExamService();
  final OfflineSyncService _syncService = OfflineSyncService();

  /// Mengambil daftar ujian untuk siswa
  Future<ExamResponseModel> getExamList() {
    return _examService.getStudentExams();
  }

  /// Mengambil daftar hasil ujian siswa
  Future<ExamResultListResponse> getExamResults() {
    return _examService.getStudentExamResults();
  }

  /// Mengunduh data ujian (soal + opsi) untuk disimpan secara offline.
  /// Memanggil startExam API → cache data ke SharedPreferences.
  /// Timer mulai berjalan dari sini.
  Future<ExamModel> downloadExam(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
  ) async {
    final examModel = await startExam(examParticipant, examName, startDate);
    // Tandai bahwa ujian sudah diunduh
    await OfflineExamStorage.markExamDownloaded(examParticipant.exam.examId);
    return examModel;
  }

  /// Memulai ujian dari cache offline (jika tersedia).
  /// Digunakan ketika tidak bisa menghubungi server (offline).
  Future<ExamModel?> startExamFromCache(int examId) async {
    final cachedExam = await OfflineExamStorage.getCachedExamData(examId);
    if (cachedExam == null) return null;

    // Recalculate remaining time based on cached startTime
    if (cachedExam.startTime != null && cachedExam.durationMinutes > 0) {
      final elapsed = DateTime.now().difference(cachedExam.startTime!);
      final totalDuration = Duration(minutes: cachedExam.durationMinutes);
      final remaining = totalDuration - elapsed;

      if (remaining.inSeconds <= 0) {
        // Timer sudah habis
        return ExamModel(
          examId: cachedExam.examId,
          subject: cachedExam.subject,
          grade: cachedExam.grade,
          date: cachedExam.date,
          teacher: cachedExam.teacher,
          type: cachedExam.type,
          examImage: cachedExam.examImage,
          quizList: cachedExam.quizList,
          examParticipantId: cachedExam.examParticipantId,
          durationMinutes: cachedExam.durationMinutes,
          startTime: cachedExam.startTime,
          endDate: cachedExam.endDate,
          remainingSeconds: 0,
        );
      }

      return ExamModel(
        examId: cachedExam.examId,
        subject: cachedExam.subject,
        grade: cachedExam.grade,
        date: cachedExam.date,
        teacher: cachedExam.teacher,
        type: cachedExam.type,
        examImage: cachedExam.examImage,
        quizList: cachedExam.quizList,
        examParticipantId: cachedExam.examParticipantId,
        durationMinutes: cachedExam.durationMinutes,
        startTime: cachedExam.startTime,
        endDate: cachedExam.endDate,
        remainingSeconds: remaining.inSeconds,
      );
    }

    return cachedExam;
  }

  /// Memulai ujian dan return ExamModel yang siap digunakan.
  /// Juga menyimpan cache data ujian untuk dukungan offline.
  Future<ExamModel> startExam(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
  ) async {
    final startExamResponse = await _examService.startExam(
      examParticipant.exam.examId,
    );

    List<QuizModel> quizList = startExamResponse.questionList.map((examQuestion) {
      return QuizModel.fromSoalUjian(examQuestion);
    }).toList();

    final examModel = ExamModel(
      examId: examParticipant.exam.examId,
      subject: examName,
      grade: examParticipant.exam.gradeLevel,
      date: DateFormatter.formatDateFromString(startDate.toString()),
      teacher: examParticipant.exam.subject,
      type: ExamTypeHelper.getExamType(examName),
      examImage: 'assets/images/c1.jpg',
      quizList: quizList,
      examParticipantId: startExamResponse.examParticipant.examParticipantId,
      durationMinutes: startExamResponse.examParticipant.durationMinutes,
      startTime: startExamResponse.examParticipant.startTime,
      endDate: examParticipant.exam.endDate,
      remainingSeconds: startExamResponse.remainingSeconds,
    );

    // Cache exam data for offline support
    await OfflineExamStorage.cacheExamData(examModel);
    // Mark this exam participant as pending finish (for offline sync)
    await OfflineExamStorage.markPendingFinish(examModel.examParticipantId);

    return examModel;
  }

  /// Submit jawaban ujian per soal.
  /// Menyimpan jawaban secara offline terlebih dahulu, lalu mencoba kirim ke server.
  /// Jika gagal kirim ke server, jawaban tetap tersimpan lokal dan akan disinkronkan nanti.
  Future<bool> submitAnswer({
    required int examParticipantId,
    required int examId,
    required int questionId,
    required String quizType,
    int? answerOptionId,
    List<int>? answerOptionIds,
    String? answerText,
  }) async {
    // 1. Selalu simpan jawaban ke local storage dulu
    await OfflineExamStorage.savePendingAnswer(
      examParticipantId: examParticipantId,
      questionId: questionId,
      answerOptionId: answerOptionId,
      answerOptionIds: answerOptionIds,
      answerText: answerText,
      quizType: quizType,
    );

    // Update cached exam data
    await OfflineExamStorage.updateCachedAnswer(
      examId: examId,
      questionId: questionId,
      answerOptionId: answerOptionId,
      answerOptionIds: answerOptionIds,
      answerEssay: answerText,
    );

    // 2. Coba kirim ke server
    try {
      await _examService.submitAnswer(
        examParticipantId: examParticipantId,
        questionId: questionId,
        answerOptionId: answerOptionId,
        answerOptionIds: answerOptionIds,
        answerText: answerText,
      );

      // Berhasil: hapus dari pending
      await OfflineExamStorage.removePendingAnswer(examParticipantId, questionId);
      return true; // Online submit succeeded
    } on SocketException {
      debugPrint('[UjianController] Offline - jawaban disimpan lokal');
      return false; // Saved offline
    } catch (e) {
      if (e.toString().contains('Tidak dapat terhubung') || 
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        debugPrint('[UjianController] Offline - jawaban disimpan lokal');
        return false; // Saved offline
      }
      // Re-throw for non-network errors (but answer is still saved locally)
      rethrow;
    }
  }

  /// Selesaikan ujian.
  /// Mencoba sinkronkan semua jawaban pending terlebih dahulu, lalu finish.
  /// WAJIB INTERNET: Jika offline, akan melempar error agar UI menangani.
  Future<Map<String, dynamic>> finishExam(int examParticipantId) async {
    // Cek internet dulu
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      throw Exception('Koneksi internet diperlukan untuk mengirim hasil ujian.');
    }

    // 1. Sync pending answers dulu
    await _syncService.syncAnswersForExam(examParticipantId);

    // 2. Finish di server
    final result = await _examService.finishExam(examParticipantId);
    
    // Berhasil - bersihkan data offline
    await OfflineExamStorage.clearPendingAnswers(examParticipantId);
    await OfflineExamStorage.removePendingFinish(examParticipantId);
    
    return result;
  }

  /// Coba sinkronkan semua data offline ke server
  Future<SyncResult> syncOfflineData() async {
    return await _syncService.syncAllPending();
  }

  /// Cek apakah ada data offline yang belum tersinkron
  Future<bool> hasPendingOfflineData() async {
    final pendingFinish = await OfflineExamStorage.getPendingFinishExams();
    return pendingFinish.isNotEmpty;
  }

  /// Cek apakah ujian di-block (sudah pernah dikerjakan)
  Future<bool> checkBlockStatus(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("blockKey $examId") ?? false;
  }

  /// Set block status untuk ujian
  Future<void> setBlockStatus(int examId, bool blocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("blockKey $examId", blocked);
  }
}
