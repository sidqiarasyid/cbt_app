
import 'package:cbt_app/style/style.dart';

import 'package:flutter/material.dart';

class QuizPilganPage extends StatefulWidget {
  final String question;
  final List<String> answerList;
  final int? initialSelectedIndex;
  final List<int>? initialSelectedIndices;
  final bool isMultipleChoice;
  final Function(int?, {List<int>? selectedIndices}) onAnswerSelected;
  
  const QuizPilganPage({
    super.key,
    required this.question, 
    required this.answerList,
    this.initialSelectedIndex,
    this.initialSelectedIndices,
    this.isMultipleChoice = false,
    required this.onAnswerSelected,
  });

  @override
  State<QuizPilganPage> createState() => _QuizPilganPageState();
}

class _QuizPilganPageState extends State<QuizPilganPage> {
  int? activeButton;
  List<int> activeButtons = [];

  @override
  void initState() {
    super.initState();
    _syncStateFromWidget();
  }

  @override
  void didUpdateWidget(QuizPilganPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state when widget props change (e.g., when navigating to different question)
    if (oldWidget.initialSelectedIndex != widget.initialSelectedIndex ||
        oldWidget.initialSelectedIndices != widget.initialSelectedIndices ||
        oldWidget.question != widget.question) {
      print('🔄 QuizPilganPage didUpdateWidget: syncing state');
      print('   Old: single=${oldWidget.initialSelectedIndex}, multiple=${oldWidget.initialSelectedIndices}');
      print('   New: single=${widget.initialSelectedIndex}, multiple=${widget.initialSelectedIndices}');
      setState(() {
        _syncStateFromWidget();
      });
    }
  }

  void _syncStateFromWidget() {
    if (widget.isMultipleChoice) {
      activeButtons = widget.initialSelectedIndices != null 
          ? List.from(widget.initialSelectedIndices!)
          : [];
      print('📋 Synced multiple choice: $activeButtons');
    } else {
      activeButton = widget.initialSelectedIndex;
      print('📋 Synced single choice: $activeButton');
    }
  }

  void toggleButton(int index){
    setState(() {
      if (widget.isMultipleChoice) {
        // Multiple choice logic
        if (activeButtons.contains(index)) {
          activeButtons.remove(index);
          print('🔄 Multiple choice UNSELECT: removed index $index, remaining: $activeButtons');
        } else {
          activeButtons.add(index);
          print('✅ Multiple choice SELECT: added index $index, current: $activeButtons');
        }
        widget.onAnswerSelected(null, selectedIndices: activeButtons.isEmpty ? null : List.from(activeButtons));
      } else {
        // Single choice logic
        if (activeButton == index) {
          activeButton = null;
          print('🔄 Single choice UNSELECT: cleared index $index');
          widget.onAnswerSelected(null);
        } else {
          final oldButton = activeButton;
          activeButton = index;
          print('✅ Single choice SELECT: changed from $oldButton to $index');
          widget.onAnswerSelected(index);
        }
      }
    });
  }

  Widget buildButton(int index, String cont){
    final bool isActive = widget.isMultipleChoice 
        ? activeButtons.contains(index)
        : activeButton == index;
    
    return GestureDetector(
      onTap: () => toggleButton(index),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? ColorsApp.primaryColor : Color(0xffECEFF5)),
          borderRadius: BorderRadius.circular(10),
          color: isActive ? Color(0xffF3FBFE) : Color(0xffECEFF5)
        ),
        child: Row(
          children: [
            if (widget.isMultipleChoice)
              Icon(
                isActive ? Icons.check_box : Icons.check_box_outline_blank,
                color: isActive ? ColorsApp.primaryColor : Colors.grey,
              ),
            if (widget.isMultipleChoice) SizedBox(width: 10),
            Expanded(
              child: Text(
                cont, 
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  color: isActive ? ColorsApp.primaryColor : Colors.black
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
  



  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
              height: MediaQuery.of(context).size.height * 0.5,
              child: widget.answerList.isEmpty 
                ? Center(
                    child: Text(
                      'Tidak ada opsi jawaban',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      widget.answerList.length,

                      (index) => Column(children: [
                        buildButton(index, widget.answerList[index]),
                        SizedBox(height: 10,)
                      ],),
                    ),
                  ),
            ),
            
            
          ],
        ),
    );
  }
}