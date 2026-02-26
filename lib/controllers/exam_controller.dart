import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/models/exam_result_response_model.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/utils/helpers.dart';

class UjianController {
  final ExamService _examService = ExamService();

  /// Mengambil daftar ujian untuk siswa
  Future<ExamResponseModel> getExamList() {
    return _examService.getStudentExams();
  }

  /// Mengambil daftar hasil ujian siswa
  Future<ExamResultListResponse> getExamResults() {
    return _examService.getStudentExamResults();
  }

  /// Memulai ujian dan return ExamModel yang siap digunakan
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

    return ExamModel(
      examId: examParticipant.exam.examId,
      subject: examName,
      grade: examParticipant.exam.gradeLevel,
      date: DateFormatter.formatDateFromString(startDate.toString()),
      teacher: examParticipant.exam.subject, // Maps to mata pelajaran from API
      type: ExamTypeHelper.getExamType(examName),
      examImage: 'assets/images/c1.jpg',
      quizList: quizList,
      examParticipantId: startExamResponse.examParticipant.examParticipantId,
      durationMinutes: startExamResponse.examParticipant.durationMinutes,
      startTime: startExamResponse.examParticipant.startTime,
      endDate: examParticipant.exam.endDate,
      remainingSeconds: startExamResponse.remainingSeconds,
    );
  }

  /// Submit jawaban ujian per soal
  Future<void> submitAnswer({
    required int examParticipantId,
    required int questionId,
    int? answerOptionId,
    List<int>? answerOptionIds,
    String? answerText,
  }) async {
    await _examService.submitAnswer(
      examParticipantId: examParticipantId,
      questionId: questionId,
      answerOptionId: answerOptionId,
      answerOptionIds: answerOptionIds,
      answerText: answerText,
    );
  }

  /// Selesaikan ujian
  Future<Map<String, dynamic>> finishExam(int examParticipantId) async {
    return await _examService.finishExam(examParticipantId);
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
