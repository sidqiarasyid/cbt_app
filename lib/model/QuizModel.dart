import 'package:cbt_app/model/start_ujian_response_model.dart';

class QuizModel {
  final int soalId;
  final int soalUjianId;
  final int urutan;
  final String question;
  final String quizType; // PILIHAN_GANDA_SINGLE, PILIHAN_GANDA_MULTIPLE, ESSAY
  bool isFinished;
  bool isSaved; // Indikator apakah jawaban sudah tersimpan di server
  List<OpsiJawaban>? opsiJawaban; // Untuk pilihan ganda
  int? selectedAnswerIndex; // For PILIHAN_GANDA_SINGLE
  List<int>? selectedAnswerIndices; // For PILIHAN_GANDA_MULTIPLE
  String? answerEssay;
  String? image;

  QuizModel({
    required this.soalId,
    required this.soalUjianId,
    required this.urutan,
    required this.question,
    required this.quizType,
    this.isFinished = false,
    this.isSaved = false,
    this.opsiJawaban,
    this.selectedAnswerIndex,
    this.selectedAnswerIndices,
    this.image,
    this.answerEssay,
  });

  // Factory untuk convert dari SoalUjian API response
  factory QuizModel.fromSoalUjian(SoalUjian soalUjian) {
    // Check jika sudah ada jawaban sebelumnya
    bool isFinished = soalUjian.jawabanSaya != null;
    bool isSaved = soalUjian.jawabanSaya != null;
    
    int? selectedAnswerIndex;
    List<int>? selectedAnswerIndices;
    String? answerEssay;

    if (soalUjian.jawabanSaya != null) {
      // Untuk PILIHAN_GANDA_SINGLE
      if (soalUjian.jawabanSaya!.opsiJawabanId != null) {
        // Cari index dari opsi yang dipilih
        selectedAnswerIndex = soalUjian.soal.opsiJawaban.indexWhere(
          (opsi) => opsi.opsiId == soalUjian.jawabanSaya!.opsiJawabanId
        );
      }
      
      // Untuk PILIHAN_GANDA_MULTIPLE
      if (soalUjian.jawabanSaya!.opsiJawabanIds != null) {
        selectedAnswerIndices = soalUjian.jawabanSaya!.opsiJawabanIds!
            .map((opsiId) {
              return soalUjian.soal.opsiJawaban.indexWhere(
                (opsi) => opsi.opsiId == opsiId
              );
            })
            .where((index) => index != -1)
            .toList();
      }
      
      // Untuk ESSAY
      answerEssay = soalUjian.jawabanSaya!.teksJawaban;
    }

    return QuizModel(
      soalId: soalUjian.soal.soalId,
      soalUjianId: soalUjian.soalUjianId,
      urutan: soalUjian.urutan,
      question: soalUjian.soal.teksSoal,
      quizType: soalUjian.soal.tipeSoal,
      isFinished: isFinished,
      isSaved: isSaved,
      opsiJawaban: soalUjian.soal.opsiJawaban.isNotEmpty 
          ? soalUjian.soal.opsiJawaban 
          : null,
      selectedAnswerIndex: selectedAnswerIndex,
      selectedAnswerIndices: selectedAnswerIndices,
      image: soalUjian.soal.soalGambar,
      answerEssay: answerEssay,
    );
  }

  // Helper untuk cek apakah soal sudah dijawab
  bool get hasAnswer {
    if (quizType == 'ESSAY') {
      return answerEssay != null && answerEssay!.trim().isNotEmpty;
    } else if (quizType == 'PILIHAN_GANDA_SINGLE') {
      return selectedAnswerIndex != null;
    } else if (quizType == 'PILIHAN_GANDA_MULTIPLE') {
      return selectedAnswerIndices != null && selectedAnswerIndices!.isNotEmpty;
    }
    return false;
  }
}

