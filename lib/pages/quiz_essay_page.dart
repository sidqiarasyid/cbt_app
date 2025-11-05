import 'package:flutter/material.dart';
import 'package:cbt_app/style/style.dart';

/// Konten untuk soal esai (dengan/atau tanpa gambar).
/// - Parent mengirim: [formKey] dan [controller] agar bisa validasi dari luar.
/// - [imageAsset] opsional (untuk soal bergambar).
class QuizEssayPage extends StatefulWidget {
  final String question;
  final TextEditingController controller;
  const QuizEssayPage({
    super.key,
    required this.question,
    required this.controller,
  });

  @override
  State<QuizEssayPage> createState() => _QuizEssayPageState();
}

class _QuizEssayPageState extends State<QuizEssayPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 12),
          Form(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: ColorsApp.primaryColor.withOpacity(.3),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: widget.controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Type answer here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Jawaban tidak boleh kosong'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
