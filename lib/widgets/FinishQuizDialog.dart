import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class FinishQuizDialog extends StatelessWidget {
  final VoidCallback onYesPressed;
  final VoidCallback onNoPressed;
  const FinishQuizDialog({super.key, required this.onYesPressed, required this.onNoPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(  
      backgroundColor: Colors.transparent,
      elevation: 0.0, 
      child:  Container(
          height: MediaQuery.of(context).size.height * 0.25,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsApp.secondaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Selesaikan Ujian", textAlign: TextAlign.center, style:  TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),),
              SizedBox(height: 10,),
              Text("Semua soal telah dijawab.\n\nApakah anda yakin ingin \nmenyelesaikan ujian ini?", textAlign: TextAlign.center,),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200]
                      ),
                      onPressed: onNoPressed,
                      child: Text("Batal", style: TextStyle(),)
                      ),
                  ),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green
                      ),
                      onPressed: onYesPressed,
                      child: Text("Ya, Selesai", style: TextStyle(color: Colors.white, ),)
                      ),
                  ),
                ],
              )
            ],
          ),
        ),
    );
  }
}
