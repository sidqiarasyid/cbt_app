
import 'package:cbt_app/style/style.dart';

import 'package:flutter/material.dart';

class QuizPilganPage extends StatefulWidget {
  final String question;
  final List<String> answerList;
  final int? initialSelectedIndex;
  final List<int>? initialSelectedIndices;
  final bool isMultipleChoice;
  final String? questionImage;
  final Function(int?, {List<int>? selectedIndices}) onAnswerSelected;
  
  const QuizPilganPage({
    super.key,
    required this.question, 
    required this.answerList,
    this.initialSelectedIndex,
    this.initialSelectedIndices,
    this.isMultipleChoice = false,
    this.questionImage,
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
    } else {
      activeButton = widget.initialSelectedIndex;
    }
  }

  void toggleButton(int index){
    setState(() {
      if (widget.isMultipleChoice) {
        // Multiple choice logic
        if (activeButtons.contains(index)) {
          activeButtons.remove(index);
        } else {
          activeButtons.add(index);
        }
        widget.onAnswerSelected(null, selectedIndices: activeButtons.isEmpty ? null : List.from(activeButtons));
      } else {
        // Single choice logic
        if (activeButton == index) {
          activeButton = null;
          widget.onAnswerSelected(null);
        } else {
          activeButton = index;
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  fontSize: 14,
                  height: 1.4,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Image (displayed above question text)
            if (widget.questionImage != null && widget.questionImage!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColorsApp.primaryColor.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.questionImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: ColorsApp.primaryColor,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        alignment: Alignment.center,
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            SizedBox(height: 4),
                            Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffF3FBFE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ColorsApp.primaryColor)
              ),
              child: Text(
                widget.question,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorsApp.primaryColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            widget.answerList.isEmpty 
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Tidak ada opsi jawaban',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.answerList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) => buildButton(index, widget.answerList[index]),
                ),
            
            
          ],
        ),
    );
  }
}