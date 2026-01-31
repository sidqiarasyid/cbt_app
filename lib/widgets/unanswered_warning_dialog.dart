import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class UnansweredWarningDialog extends StatelessWidget {
  final int unansweredCount;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  
  const UnansweredWarningDialog({
    super.key, 
    required this.unansweredCount,
    required this.onContinue, 
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
              Icon(Icons.block, size: 50, color: Colors.red),
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
                "Jika keluar sekarang, anda akan TERBLOKIR dari ujian ini.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Jawaban yang sudah tersimpan akan tetap dihitung saat ujian berakhir (auto-complete).",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Apakah anda yakin ingin keluar?",
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
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onContinue,
                      child: Text(
                        "Tetap Keluar", 
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
