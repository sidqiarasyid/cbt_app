import 'package:cbt_app/model/QuizModel.dart';

class UjianModel {
  String subject;
  String grade;
  String date;
  String teacher;
  String type;
  String ujianImage;
  String? teacherImage;
  List<QuizModel> quizList;

  UjianModel({
    required this.subject,
    required this.grade,
    required this.date,
    required this.teacher,
    required this.type,
    required this.ujianImage,
    required this.quizList
  }
  );
}