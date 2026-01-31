import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class UnansweredFinishWarningDialog extends StatelessWidget {
  final int unansweredCount;
  final VoidCallback onContinueFinish;
  final VoidCallback onBack;
  
  const UnansweredFinishWarningDialog({
    super.key, 
    required this.unansweredCount,
    required this.onContinueFinish, 
    required this.onBack
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(  
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorsApp.secondaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
              SizedBox(height: 10),
              Text(
                "Perhatian!", 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Ada $unansweredCount soal yang belum dijawab.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Soal yang belum dijawab akan dinilai 0.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Soal yang belum dijawab akan dinilai 0.\n\nApakah anda yakin ingin menyelesaikan ujian sekarang?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onBack,
                      child: Text("Kembali", style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onContinueFinish,
                      child: Text(
                        "Ya, Selesaikan", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
