class QuizModel {
  String question;
  String quizType;
  List<String> answers;
  int rightAnswer;
  String? image; 
  bool isFinished;

  QuizModel({
    required this.question,
    required this.quizType, 
    required this.answers, 
    required this.rightAnswer,
    required this.isFinished
  });
}
