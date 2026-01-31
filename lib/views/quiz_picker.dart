
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/ujian_model.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/picker_item.dart';
import 'package:cbt_app/widgets/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/end_quiz_dialog.dart';
import 'package:flutter/material.dart';

class QuizPicker extends StatefulWidget {
  final List<QuizModel> quizList;
  final int currItem;
  final UjianModel ujian;
  final VoidCallback? onFinishQuiz;
  final VoidCallback? onExitQuiz;
  
  const QuizPicker({
    super.key, 
    required this.quizList, 
    required this.currItem, 
    required this.ujian,
    this.onFinishQuiz,
    this.onExitQuiz,
  });

  @override
  State<QuizPicker> createState() => _QuizPickerState();
}

class _QuizPickerState extends State<QuizPicker> {
  
  int get _answeredCount => widget.quizList.where((q) => q.hasAnswer).length;
  int get _totalCount => widget.quizList.length;
  int get _unansweredCount => _totalCount - _answeredCount;
  bool get _allAnswered => _unansweredCount == 0;
  
  void _handleFinishQuiz() {
    // Confirm finish - all questions answered
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinishQuizDialog(
        onYesPressed: () {
          Navigator.pop(context); // Close dialog
          if (widget.onFinishQuiz != null) {
            widget.onFinishQuiz!();
          }
        },
        onNoPressed: () {
          Navigator.pop(context); // Close dialog
        },
      ),
    );
  }
  
  void _handleExitWithoutSubmit() {
    // Exit without submitting - has unanswered questions
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnansweredWarningDialog(
        unansweredCount: _unansweredCount,
        onContinue: () {
          Navigator.pop(context); // Close warning dialog
          // Show final exit confirmation
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => EndQuizDialog(
              onYesPressed: () {
                Navigator.pop(context); // Close dialog
                if (widget.onExitQuiz != null) {
                  widget.onExitQuiz!();
                }
              },
              onNoPressed: () {
                Navigator.pop(context); // Close dialog
              },
            ),
          );
        },
        onBack: () {
          Navigator.pop(context); // Close warning dialog
        },
      ),
    );
  }
  
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
                    SizedBox(
                      width: 300,
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
            ),
            // Action Buttons Area
            Container(
              margin: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  // Progress Info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _allAnswered ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _allAnswered ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _allAnswered ? Icons.check_circle : Icons.info,
                          color: _allAnswered ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _allAnswered 
                            ? 'Semua soal telah dijawab! ($_answeredCount/$_totalCount)'
                            : 'Soal dijawab: $_answeredCount/$_totalCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _allAnswered ? Colors.green[800] : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Main Action Button
                  if (_allAnswered)
                    // Finish Quiz Button (Submit)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        onPressed: _handleFinishQuiz,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Selesaikan Ujian",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Exit Without Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _handleExitWithoutSubmit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.exit_to_app, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Keluar Tanpa Menyimpan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        )
        ),
    );
  }
}