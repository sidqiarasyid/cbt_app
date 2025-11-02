import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class AnswerBtn extends StatefulWidget {
  final String content;
  AnswerBtn({super.key, required this.content});

  @override
  State<AnswerBtn> createState() => _AnswerBtnState();
}

class _AnswerBtnState extends State<AnswerBtn> {
  Color bgColor = Color(0xffECEFF5);

  Color txtColor = Colors.black;

  Color borderColor = Color(0xffECEFF5);

  void btnPressed(){
    setState(() {
       if(bgColor == Color(0xffECEFF5)){
        bgColor = Color(0xffF3FBFE);
        txtColor = ColorsApp.primaryColor;
        borderColor = ColorsApp.primaryColor;
    } else {
      bgColor = Color(0xffECEFF5);
      borderColor = Color(0xffECEFF5);
      txtColor = Colors.black;
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => btnPressed(),
      child:  Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                    color: bgColor
                  ),
                  child: Text(widget.content, 
                  style: TextStyle(fontWeight: FontWeight.w500, color: txtColor),),
                ),
    );
  }
}