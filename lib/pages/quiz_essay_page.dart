import 'package:flutter/material.dart';
import 'package:cbt_app/style/style.dart';

/// Konten untuk soal esai (dengan/atau tanpa gambar).
/// - Parent mengirim: [formKey] dan [controller] agar bisa validasi dari luar.
/// - [imageAsset] opsional (untuk soal bergambar).
class QuizEssayPage extends StatefulWidget {
  final String question;
  final String? imageAsset;
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;

  const QuizEssayPage({
    super.key,
    required this.question,
    required this.formKey,
    required this.controller,
    this.imageAsset,
  });

  @override
  State<QuizEssayPage> createState() => _QuizEssayPageState();
}

class _QuizEssayPageState extends State<QuizEssayPage> {
  bool _bannerShown = false;

  void _showSavedBanner() {
    if (_bannerShown) return;
    _bannerShown = true;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: ColorsApp.backgroundColor,
        content: const Text(
          'Jawaban tersimpan sementara. Kamu bisa lanjut ke soal berikutnya.',
        ),
        leading: const Icon(Icons.check_circle_outline),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // card pertanyaan
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorsApp.secondaryColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ColorsApp.primaryColor),
              ),
              child: Text(
                widget.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Gambar
            if (widget.imageAsset != null && widget.imageAsset!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(widget.imageAsset!, fit: BoxFit.cover),
              ),

            if (widget.imageAsset != null) const SizedBox(height: 10),

            // Form jawaban
            Form(
              key: widget.formKey,
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
                  onChanged: (_) => _showSavedBanner(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
