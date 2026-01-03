import 'package:cbt_app/main.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class QuizBlockedPage extends StatefulWidget {
  const QuizBlockedPage({super.key});

  @override
  State<QuizBlockedPage> createState() => _QuizBlockedPageState();
}

class _QuizBlockedPageState extends State<QuizBlockedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.secondaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Color(0xffFF6B6B),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, color: Colors.white, size: 120),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Anda melakukan pelanggaran di ujian pada 8 September 2024, 12:37',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10,),
              Text(
                'Konsultasi  ke guru pengawas atau Admin untuk mendapatkan kode ujian untuk membuka block',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20,),
              SizedBox(height: 20,),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsApp.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => MyHomePage()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Kembali ke menu utama',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}