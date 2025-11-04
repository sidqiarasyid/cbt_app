import 'package:cbt_app/pages/home_page.dart';
import 'package:flutter/material.dart';

class QuizEndPage extends StatefulWidget {
  const QuizEndPage({super.key});

  @override
  State<QuizEndPage> createState() => _QuizEndPageState();
}

class _QuizEndPageState extends State<QuizEndPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
        }, 
        child: Text("Selesai")),
      ),
    );
  }
}