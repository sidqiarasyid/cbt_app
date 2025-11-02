
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class QuizPilganPage extends StatefulWidget {
  final String question;
  final int rightAnswer;
  final List<String> answerList;
  const QuizPilganPage({
    super.key,
    required this.question, 
    required this.rightAnswer, 
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xffECEFF5)
                    ),
                    child: Text(widget.answerList[0], 
                    style: TextStyle(fontWeight: FontWeight.w500),),
                  ),
                    Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffECEFF5)
                  ),
                  child: Text(widget.answerList[1], 
                  style: TextStyle(fontWeight: FontWeight.w500),),
                ),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffECEFF5)
                  ),
                  child: Text(widget.answerList[2], 
                  style: TextStyle(fontWeight: FontWeight.w500),),
                ),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffECEFF5)
                  ),
                  child: Text(widget.answerList[3], 
                  style: TextStyle(fontWeight: FontWeight.w500),),
                ),
              
                ],
              ),
            ),
            
            
          ],
        ),
    );
  }
}