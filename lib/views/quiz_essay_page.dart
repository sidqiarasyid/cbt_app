import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cbt_app/style/style.dart';

/// Konten untuk soal esai (dengan/atau tanpa gambar).
/// - Parent mengirim: [formKey] dan [controller] agar bisa validasi dari luar.
/// - [imageAsset] opsional (untuk soal bergambar).
class QuizEssayPage extends StatefulWidget {
  final String question;
  final TextEditingController controller;
  final VoidCallback? onChanged;
  
  const QuizEssayPage({
    super.key,
    required this.question,
    required this.controller,
    this.onChanged,
  });

  @override
  State<QuizEssayPage> createState() => _QuizEssayPageState();
}

class _QuizEssayPageState extends State<QuizEssayPage> {
  Timer? _debounceTimer;
  bool _isSaving = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _characterCount = widget.controller.text.length;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {
      _characterCount = value.length;
      _isSaving = true;
    });
    
    // Cancel previous timer if exists
    _debounceTimer?.cancel();
    
    // Start new timer (2 seconds debounce)
    _debounceTimer = Timer(Duration(seconds: 2), () {
      if (widget.onChanged != null) {
        widget.onChanged!();
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ 
          // Question Box
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xffF3FBFE),
              borderRadius: BorderRadius.circular(8),
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
          
          const SizedBox(height: 16),
          
          // Save Status Indicator
          Row(
            children: [
              Text(
                'Jawaban Anda:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 10),
              if (_isSaving)
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Menyimpan...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else if (widget.controller.text.trim().isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Tersimpan otomatis',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Answer Text Field
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
                onChanged: _onTextChanged,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Ketik jawaban Anda di sini...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Jawaban tidak boleh kosong'
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Character Count
          Text(
            '$_characterCount karakter',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
