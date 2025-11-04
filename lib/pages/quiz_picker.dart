import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class QuizPicker extends StatefulWidget {
  const QuizPicker({super.key});

  @override
  State<QuizPicker> createState() => _QuizPickerState();
}

class _QuizPickerState extends State<QuizPicker> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: Navigator.of(context).pop, 
                  icon: Icon(Icons.arrow_back)
                ),
                Text("Ujian - Tipe Ujian")
              ],
            ),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  color: ColorsApp.primaryColor,
                ),
                Text("Selesai"),
                Container(
                  width: 20,
                  height: 20,
                  color: Color(0xFF03356C),
                ),
                Text("Soal saat ini"),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black
                    )
                  ),
                )
              ],
            )
          ],
        )
        ),
    );
  }
}