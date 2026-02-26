import 'package:cbt_app/models/quiz_model.dart';

class ExamModel {
  int examId;
  String subject;
  String grade;
  String date;
  String teacher;
  String type;
  String examImage;
  String? teacherImage;
  List<QuizModel> quizList;
  
  // Tambahan untuk integrasi API
  int examParticipantId;
  int durationMinutes;
  DateTime? startTime;
  DateTime? endDate; // Exam deadline time from server
  int? remainingSeconds; // From backend startExam response

  ExamModel({
    required this.examId,
    required this.subject,
    required this.grade,
    required this.date,
    required this.teacher,
    required this.type,
    required this.examImage,
    required this.quizList,
    required this.examParticipantId,
    required this.durationMinutes,
    this.startTime,
    this.endDate,
    this.teacherImage,
    this.remainingSeconds,
  });
}