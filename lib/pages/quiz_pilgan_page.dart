
import 'package:cbt_app/style/style.dart';

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
  int? activeButton;

  void toggleButton(int index){
    setState(() {
      if(activeButton == index){
        activeButton = null;
      } else{
        activeButton = index;
      }
    });
  }

  Widget buildButton(int index, String cont){
    final bool isActive = activeButton == index;
    final bool isDisabled = activeButton != null && !isActive;
    final VoidCallback? onTap = isDisabled ? null : ()=> toggleButton(index);
    return GestureDetector(

      onTap: onTap,
      child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color:  isActive ? ColorsApp.primaryColor : Color(0xffECEFF5)),
                  borderRadius: BorderRadius.circular(10),
                  color: isActive ? Color(0xffF3FBFE) : Color(0xffECEFF5)
                ),
                child: Text(cont, 
                style: TextStyle(fontWeight: FontWeight.w500, color:  isActive ? ColorsApp.primaryColor : Colors.black),),
              )
    );
  }
  



  
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
                  buildButton(1, widget.answerList[0]),
                  buildButton(2, widget.answerList[1]),
                  buildButton(3, widget.answerList[2]),
                  buildButton(4, widget.answerList[3]),     
                ],
              ),
            ),
            
            
          ],
        ),
    );
  }
}