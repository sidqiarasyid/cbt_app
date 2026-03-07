import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/start_exam_response_model.dart';

/// Service untuk menyimpan dan mengambil data ujian secara offline.
/// Data disimpan menggunakan SharedPreferences dalam format JSON.
class OfflineExamStorage {
  // Keys
  static const String _examDataKey = 'offline_exam_data_';
  static const String _pendingAnswersKey = 'pending_answers_';
  static const String _pendingFinishKey = 'pending_finish_exams';
  static const String _offlineModeKey = 'offline_mode_';
  static const String _downloadedExamsKey = 'downloaded_exam_ids';

  // ==================== DOWNLOAD TRACKING ====================

  /// Tandai ujian sudah diunduh
  static Future<void> markExamDownloaded(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_downloadedExamsKey);
    final List<int> ids = jsonStr != null
        ? List<int>.from(jsonDecode(jsonStr))
        : [];
    if (!ids.contains(examId)) {
      ids.add(examId);
      await prefs.setString(_downloadedExamsKey, jsonEncode(ids));
    }
  }

  /// Cek apakah ujian sudah diunduh
  static Future<bool> isExamDownloaded(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_downloadedExamsKey);
    if (jsonStr == null) return false;
    final List<int> ids = List<int>.from(jsonDecode(jsonStr));
    return ids.contains(examId);
  }

  /// Ambil semua ID ujian yang sudah diunduh
  static Future<Set<int>> getDownloadedExamIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_downloadedExamsKey);
    if (jsonStr == null) return {};
    return Set<int>.from(jsonDecode(jsonStr));
  }

  /// Hapus tanda unduh ujian (setelah selesai/sync)
  static Future<void> removeDownloadedMark(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_downloadedExamsKey);
    if (jsonStr == null) return;
    final List<int> ids = List<int>.from(jsonDecode(jsonStr));
    ids.remove(examId);
    await prefs.setString(_downloadedExamsKey, jsonEncode(ids));
  }

  // ==================== EXAM DATA CACHING ====================

  /// Simpan data ujian lengkap (soal, opsi jawaban) untuk offline
  static Future<void> cacheExamData(ExamModel exam) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_examDataKey${exam.examId}';

    final examJson = {
      'exam_id': exam.examId,
      'subject': exam.subject,
      'grade': exam.grade,
      'date': exam.date,
      'teacher': exam.teacher,
      'type': exam.type,
      'exam_image': exam.examImage,
      'exam_participant_id': exam.examParticipantId,
      'duration_minutes': exam.durationMinutes,
      'start_time': exam.startTime?.toIso8601String(),
      'end_date': exam.endDate?.toIso8601String(),
      'remaining_seconds': exam.remainingSeconds,
      'cached_at': DateTime.now().toIso8601String(),
      'quiz_list': exam.quizList.map((q) {
        return {
          'question_id': q.questionId,
          'exam_question_id': q.examQuestionId,
          'sequence': q.sequence,
          'question': q.question,
          'quiz_type': q.quizType,
          'image': q.image,
          'answer_essay': q.answerEssay,
          'selected_answer_index': q.selectedAnswerIndex,
          'selected_answer_indices': q.selectedAnswerIndices,
          'is_finished': q.isFinished,
          'is_saved': q.isSaved,
          'answer_options': q.answerOptions?.map((opt) {
            return {
              'option_id': opt.optionId,
              'label': opt.label,
              'option_text': opt.optionText,
            };
          }).toList(),
        };
      }).toList(),
    };

    await prefs.setString(key, jsonEncode(examJson));
  }

  /// Ambil data ujian dari cache offline
  static Future<ExamModel?> getCachedExamData(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_examDataKey$examId';
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final quizList = (data['quiz_list'] as List).map((q) {
        final qMap = q as Map<String, dynamic>;
        final answerOptions = qMap['answer_options'] != null
            ? (qMap['answer_options'] as List).map((opt) {
                final optMap = opt as Map<String, dynamic>;
                return AnswerOption(
                  optionId: optMap['option_id'] as int,
                  label: optMap['label'] as String,
                  optionText: optMap['option_text'] as String,
                );
              }).toList()
            : null;

        return QuizModel(
          questionId: qMap['question_id'] as int,
          examQuestionId: qMap['exam_question_id'] as int,
          sequence: qMap['sequence'] as int,
          question: qMap['question'] as String,
          quizType: qMap['quiz_type'] as String,
          image: qMap['image'] as String?,
          answerEssay: qMap['answer_essay'] as String?,
          selectedAnswerIndex: qMap['selected_answer_index'] as int?,
          selectedAnswerIndices: qMap['selected_answer_indices'] != null
              ? List<int>.from(qMap['selected_answer_indices'])
              : null,
          isFinished: qMap['is_finished'] as bool? ?? false,
          isSaved: qMap['is_saved'] as bool? ?? false,
          answerOptions: answerOptions,
        );
      }).toList();

      return ExamModel(
        examId: data['exam_id'] as int,
        subject: data['subject'] as String,
        grade: data['grade'] as String,
        date: data['date'] as String,
        teacher: data['teacher'] as String,
        type: data['type'] as String,
        examImage: data['exam_image'] as String,
        examParticipantId: data['exam_participant_id'] as int,
        durationMinutes: data['duration_minutes'] as int,
        startTime: data['start_time'] != null
            ? DateTime.tryParse(data['start_time'])
            : null,
        endDate: data['end_date'] != null
            ? DateTime.tryParse(data['end_date'])
            : null,
        remainingSeconds: data['remaining_seconds'] as int?,
        quizList: quizList,
      );
    } catch (e) {
      return null;
    }
  }

  /// Hapus cache ujian
  static Future<void> clearCachedExamData(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_examDataKey$examId');
  }

  // ==================== PENDING ANSWERS ====================

  /// Simpan jawaban yang belum tersinkron ke server
  static Future<void> savePendingAnswer({
    required int examParticipantId,
    required int questionId,
    int? answerOptionId,
    List<int>? answerOptionIds,
    String? answerText,
    required String quizType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_pendingAnswersKey$examParticipantId';

    // Ambil pending answers yang sudah ada
    final existingJson = prefs.getString(key);
    final List<Map<String, dynamic>> pendingAnswers = existingJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(existingJson))
        : [];

    // Hapus jawaban lama untuk question_id yang sama (replace)
    pendingAnswers.removeWhere((a) => a['question_id'] == questionId);

    // Tambah jawaban baru
    pendingAnswers.add({
      'exam_participant_id': examParticipantId,
      'question_id': questionId,
      'answer_option_id': answerOptionId,
      'answer_option_ids': answerOptionIds,
      'answer_text': answerText,
      'quiz_type': quizType,
      'saved_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(key, jsonEncode(pendingAnswers));
  }

  /// Ambil semua jawaban yang belum tersinkron
  static Future<List<Map<String, dynamic>>> getPendingAnswers(int examParticipantId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_pendingAnswersKey$examParticipantId';
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return [];

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
    } catch (e) {
      return [];
    }
  }

  /// Hapus jawaban yang sudah berhasil disinkron
  static Future<void> removePendingAnswer(int examParticipantId, int questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_pendingAnswersKey$examParticipantId';
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return;

    try {
      final List<Map<String, dynamic>> pendingAnswers =
          List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
      pendingAnswers.removeWhere((a) => a['question_id'] == questionId);
      await prefs.setString(key, jsonEncode(pendingAnswers));
    } catch (_) {}
  }

  /// Hapus semua pending answers untuk sebuah ujian
  static Future<void> clearPendingAnswers(int examParticipantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pendingAnswersKey$examParticipantId');
  }

  /// Cek apakah ada pending answers
  static Future<bool> hasPendingAnswers(int examParticipantId) async {
    final answers = await getPendingAnswers(examParticipantId);
    return answers.isNotEmpty;
  }

  // ==================== PENDING FINISH ====================

  /// Tandai ujian yang perlu di-finish saat kembali online
  static Future<void> markPendingFinish(int examParticipantId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingFinishKey);
    final List<int> pendingIds = jsonStr != null
        ? List<int>.from(jsonDecode(jsonStr))
        : [];

    if (!pendingIds.contains(examParticipantId)) {
      pendingIds.add(examParticipantId);
      await prefs.setString(_pendingFinishKey, jsonEncode(pendingIds));
    }
  }

  /// Ambil semua ujian yang pending finish
  static Future<List<int>> getPendingFinishExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingFinishKey);
    if (jsonStr == null) return [];

    try {
      return List<int>.from(jsonDecode(jsonStr));
    } catch (e) {
      return [];
    }
  }

  /// Hapus ujian dari pending finish setelah berhasil disinkron
  static Future<void> removePendingFinish(int examParticipantId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingFinishKey);
    if (jsonStr == null) return;

    try {
      final List<int> pendingIds = List<int>.from(jsonDecode(jsonStr));
      pendingIds.remove(examParticipantId);
      await prefs.setString(_pendingFinishKey, jsonEncode(pendingIds));
    } catch (_) {}
  }

  // ==================== OFFLINE MODE TRACKING ====================

  /// Set status offline mode untuk sebuah ujian
  static Future<void> setOfflineMode(int examId, bool isOffline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_offlineModeKey$examId', isOffline);
  }

  /// Cek apakah ujian dalam offline mode
  static Future<bool> isOfflineMode(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_offlineModeKey$examId') ?? false;
  }

  // ==================== UPDATE CACHED ANSWERS ====================

  /// Update jawaban di cached exam data (untuk offline state tracking)
  static Future<void> updateCachedAnswer({
    required int examId,
    required int questionId,
    int? selectedAnswerIndex,
    List<int>? selectedAnswerIndices,
    int? answerOptionId,
    List<int>? answerOptionIds,
    String? answerEssay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_examDataKey$examId';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final quizList = data['quiz_list'] as List;

      for (int i = 0; i < quizList.length; i++) {
        if (quizList[i]['question_id'] == questionId) {
          // Resolve selectedAnswerIndex from answerOptionId if not provided directly
          int? resolvedIndex = selectedAnswerIndex;
          if (resolvedIndex == null && answerOptionId != null) {
            final options = quizList[i]['answer_options'] as List?;
            if (options != null) {
              for (int j = 0; j < options.length; j++) {
                if (options[j]['option_id'] == answerOptionId) {
                  resolvedIndex = j;
                  break;
                }
              }
            }
          }

          // Resolve selectedAnswerIndices from answerOptionIds if not provided
          List<int>? resolvedIndices = selectedAnswerIndices;
          if (resolvedIndices == null && answerOptionIds != null) {
            final options = quizList[i]['answer_options'] as List?;
            if (options != null) {
              resolvedIndices = [];
              for (final optId in answerOptionIds) {
                for (int j = 0; j < options.length; j++) {
                  if (options[j]['option_id'] == optId) {
                    resolvedIndices.add(j);
                    break;
                  }
                }
              }
            }
          }

          quizList[i]['selected_answer_index'] = resolvedIndex;
          quizList[i]['selected_answer_indices'] = resolvedIndices;
          quizList[i]['answer_essay'] = answerEssay;
          quizList[i]['is_saved'] = true;
          break;
        }
      }

      data['quiz_list'] = quizList;
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }
}
