
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/AnswerBtn.dart';
import 'package:flutter/material.dart';

class QuizPilganPage extends StatefulWidget {
  final String question;
  final List<String> answerList;
  const QuizPilganPage({
    super.key,
    required this.question, 
    required this.answerList
    });

  @override
  State<QuizPilganPage> createState() => _QuizPilganPageState();
}

class _QuizPilganPageState extends State<QuizPilganPage> {
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffF3FBFE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorsApp.primaryColor)
              ),
              child: Text(widget.question,
              style: TextStyle(fontWeight: FontWeight.w600, color: ColorsApp.primaryColor),),
            ),
            SizedBox(height: 5,),
            Container(
              height: MediaQuery.of(context).size.height * 0.38,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnswerBtn(
                    content: widget.answerList[0], 
                    ),
                  AnswerBtn(
                    content: widget.answerList[1], 
                    ),
                  AnswerBtn(
                    content: widget.answerList[2], 
                    ),
                  AnswerBtn(
                    content: widget.answerList[3], 
                    ),      
                    
                ],
              ),
            ),
            
            
          ],
        ),
    );
  }
}