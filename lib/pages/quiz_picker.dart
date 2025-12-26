
import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/PickerItem.dart';
import 'package:flutter/material.dart';

class QuizPicker extends StatefulWidget {
  final List<QuizModel> quizList;
  final int currItem;
  final UjianModel ujian;
  const QuizPicker({super.key, required this.quizList, required this.currItem, required this.ujian});

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
            Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      }, 
                      icon: Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                    Expanded(
                      child: Text(
                        widget.ujian.subject,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4)
                    ),
                  ),
                  SizedBox(width:  MediaQuery.of(context).size.width * 0.01,),
                  Text("Dijawab"),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02,),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFF03356C),
                      borderRadius: BorderRadius.circular(4)
                    ),
                  ),
                  SizedBox(width:  MediaQuery.of(context).size.width * 0.01,),
                  Text("Saat ini"),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02,),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.black
                      )
                    ),
                  ),
                  SizedBox(width:  MediaQuery.of(context).size.width * 0.01,),
                  Text("Belum dijawab")
                ],
              ),
            ),
            SizedBox(height: 30,),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: GridView.builder(
                  itemCount: widget.quizList.length, // Adjust this number based on your needs
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 15
                  ), 
                  itemBuilder: (context, index) {
                    QuizModel qItem = widget.quizList[index];
                    bool isAnswered = qItem.hasAnswer;
                    
                    return PickerItem(
                      cont: "${index + 1}",
                      bgColor: 
                        (index == widget.currItem) ? Color(0xff03356C) :
                        (isAnswered) ? Colors.green :
                        ColorsApp.secondaryColor,
                      contColor: 
                        (index == widget.currItem) ? ColorsApp.backgroundColor :
                        (isAnswered) ? ColorsApp.backgroundColor :
                        Colors.black,
                      brdColor: 
                        (index == widget.currItem) ? ColorsApp.backgroundColor :
                        (isAnswered) ? ColorsApp.backgroundColor :
                        Colors.black,
                      pickerTap: (){
                        Navigator.pop(context, index);
                      },
                    );  
                  },
                ),
              ),
            )
          ],
        )
        ),
    );
  }
}