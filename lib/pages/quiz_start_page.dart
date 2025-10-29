import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class QuizStartPage extends StatelessWidget {
  const QuizStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: Container(
          height: 230,
          width: 410,
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:ColorsApp.secondaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
               color: Colors.grey.withValues(alpha: 0.5),
               spreadRadius: 2,
               blurRadius: 2,
               offset: Offset(0, 3), // changes position of shadow
        ),
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("UAS - Bahasa Inggris", style: TextStyle(
                fontSize: 20,
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
                  onPressed: (){
                      
                  }, 
                  child: Text("Mulai Ujian", style: TextStyle(color: Colors.white, ),)
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }
}