class QuizModel {
  String question;
  String quizType;
  List<String> answers;
  int rightAnswer;
  String? image; 

  QuizModel({
    required this.question,
    required this.quizType, 
    required this.answers, 
    required this.rightAnswer
  });
}
