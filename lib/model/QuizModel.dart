class QuizModel {
  String question;
  String quizType;
  bool isFinished;
  List<String>? answersPilgan;
  int? rightAnswerPilgan;
  String? answerEssay;
  String? image; 

  QuizModel({
    required this.question,
    required this.quizType,
    required this.isFinished, 
    this.rightAnswerPilgan,
    this.answersPilgan,
    this.image,
    this.answerEssay
  });
}
