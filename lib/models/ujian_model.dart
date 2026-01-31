import 'package:cbt_app/models/quiz_model.dart';

class UjianModel {
  int ujianId;
  String subject;
  String grade;
  String date;
  String teacher;
  String type;
  String ujianImage;
  String? teacherImage;
  List<QuizModel> quizList;
  
  // Tambahan untuk integrasi API
  int pesertaUjianId;
  int durasiMenit;
  DateTime? waktuMulai;
  DateTime? tanggalSelesai; // Waktu deadline ujian dari server

  UjianModel({
    required this.ujianId,
    required this.subject,
    required this.grade,
    required this.date,
    required this.teacher,
    required this.type,
    required this.ujianImage,
    required this.quizList,
    required this.pesertaUjianId,
    required this.durasiMenit,
    this.waktuMulai,
    this.tanggalSelesai,
    this.teacherImage,
  });
}