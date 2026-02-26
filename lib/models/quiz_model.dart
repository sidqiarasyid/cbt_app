import 'package:cbt_app/models/start_exam_response_model.dart';

class QuizModel {
  final int questionId;
  final int examQuestionId;
  final int sequence;
  final String question;
  final String quizType; // SINGLE_CHOICE, MULTIPLE_CHOICE, ESSAY
  bool isFinished;
  bool isSaved; // Indicator whether the answer has been saved to server
  List<AnswerOption>? answerOptions; // Untuk pilihan ganda
  int? selectedAnswerIndex; // For SINGLE_CHOICE
  List<int>? selectedAnswerIndices; // For MULTIPLE_CHOICE
  String? answerEssay;
  String? image;

  QuizModel({
    required this.questionId,
    required this.examQuestionId,
    required this.sequence,
    required this.question,
    required this.quizType,
    this.isFinished = false,
    this.isSaved = false,
    this.answerOptions,
    this.selectedAnswerIndex,
    this.selectedAnswerIndices,
    this.image,
    this.answerEssay,
  });

  // Factory untuk convert dari ExamQuestion API response
  factory QuizModel.fromSoalUjian(ExamQuestion examQuestion) {
    // Check jika sudah ada jawaban sebelumnya
    bool isFinished = examQuestion.myAnswer != null;
    bool isSaved = examQuestion.myAnswer != null;
    
    int? selectedAnswerIndex;
    List<int>? selectedAnswerIndices;
    String? answerEssay;

    if (examQuestion.myAnswer != null) {
      // Untuk SINGLE_CHOICE
      if (examQuestion.myAnswer!.answerOptionId != null) {
        // Cari index dari opsi yang dipilih
        final idx = examQuestion.question.answerOptions.indexWhere(
          (option) => option.optionId == examQuestion.myAnswer!.answerOptionId
        );
        selectedAnswerIndex = idx != -1 ? idx : null;
      }
      
      // Untuk MULTIPLE_CHOICE
      if (examQuestion.myAnswer!.answerOptionIds != null) {
        selectedAnswerIndices = examQuestion.myAnswer!.answerOptionIds!
            .map((optionId) {
              return examQuestion.question.answerOptions.indexWhere(
                (option) => option.optionId == optionId
              );
            })
            .where((index) => index != -1)
            .toList();
      }
      
      // Untuk ESSAY
      answerEssay = examQuestion.myAnswer!.answerText;
    }

    return QuizModel(
      questionId: examQuestion.question.questionId,
      examQuestionId: examQuestion.examQuestionId,
      sequence: examQuestion.sequence,
      question: examQuestion.question.questionText,
      quizType: examQuestion.question.questionType,
      isFinished: isFinished,
      isSaved: isSaved,
      answerOptions: examQuestion.question.answerOptions.isNotEmpty 
          ? examQuestion.question.answerOptions 
          : null,
      selectedAnswerIndex: selectedAnswerIndex,
      selectedAnswerIndices: selectedAnswerIndices,
      image: examQuestion.question.questionImage,
      answerEssay: answerEssay,
    );
  }

  // Helper untuk cek apakah soal sudah dijawab
  bool get hasAnswer {
    if (quizType == 'ESSAY') {
      return answerEssay != null && answerEssay!.trim().isNotEmpty;
    } else if (quizType == 'SINGLE_CHOICE') {
      return selectedAnswerIndex != null;
    } else if (quizType == 'MULTIPLE_CHOICE') {
      return selectedAnswerIndices != null && selectedAnswerIndices!.isNotEmpty;
    }
    return false;
  }
}

