import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class StartDialog extends StatelessWidget {
  const StartDialog({super.key, required this.subject, required this.btnPressed});
  final VoidCallback btnPressed;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return Dialog(  
      backgroundColor: Colors.transparent,
      elevation: 0.0, 
      child:  Container(
          height: MediaQuery.of(context).size.height * 0.3,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsApp.secondaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(subject, textAlign: TextAlign.center, style:  TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),),
              SizedBox(height: 5,),
              Text("Ujian akan dimulai pada Kamis, \n 8 September 2024, 11:30", textAlign: TextAlign.center,),
              SizedBox(height: 15,),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsApp.primaryColor
                  ),
                  onPressed: btnPressed,
                  child: Text("Mulai Ujian", style: TextStyle(color: Colors.white, ),)
                  ),
              )
            ],
          ),
        ),
    );
  }
}