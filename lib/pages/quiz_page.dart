import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/pages/quiz_end_page.dart';
import 'package:cbt_app/pages/quiz_picker.dart';
import 'package:cbt_app/pages/quiz_pilgan_page.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final UjianModel ujian;
  const QuizPage({super.key, required this.ujian});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late String ques;
  late int rAnswer;
  late List<String> answer;
  int currentQuestion = 0;

  @override
  void initState() {
    super.initState();
    List<QuizModel> qList = widget.ujian.quizList;
    ques = qList[currentQuestion].question;
    rAnswer = qList[currentQuestion].rightAnswer;
    answer = qList[currentQuestion].answers;
  }
  
  void nextQuestion(){
    List<QuizModel> qList = widget.ujian.quizList;
    setState(() {
      if(currentQuestion + 1 == qList.length){
        Navigator.push(context, 
          MaterialPageRoute(builder: (context) => QuizEndPage()
          )
        );
      } else {
        currentQuestion++;
      }
       ques = qList[currentQuestion].question;
       rAnswer = qList[currentQuestion].rightAnswer;
       answer = qList[currentQuestion].answers;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: (){
                        Navigator.pop(context);
                      }, 
                      icon: Icon(Icons.arrow_back), iconSize: 30,),
                      Text("Soal ${currentQuestion + 1}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            width: 1,
                            color: Colors.black
                          )
                        ),
                        child: Text("40:00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                      ),
                      IconButton(onPressed: (){
                        Navigator.push(context, 
                        MaterialPageRoute(builder: (context) => QuizPicker()));
                      }, 
                      icon: Icon(Icons.grid_view_outlined, size: 30,))
                    ],
                  )
                ],
              ),
            ),
            QuizPilganPage(question: ques, rightAnswer: rAnswer, answerList: answer,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(8)
                  ),
                  backgroundColor: ColorsApp.primaryColor
                ),
                onPressed: nextQuestion, 
                child: Text("Selanjutnya", style: TextStyle(color: ColorsApp.secondaryColor),)),
            )
          ],
        ),
      ),
    );
  }
}