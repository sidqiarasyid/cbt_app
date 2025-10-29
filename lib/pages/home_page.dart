import 'package:flutter/material.dart';
import '../widgets/ExamCard.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selamat Datang Sidqi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.cyan[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/sekolah.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Jadwal Ujian',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                height: 597,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExamCard(
                        date: '31 Mar 2024',
                        subject: 'Bahasa Inggris: Advanced',
                        school: 'UTS',
                        teacher: 'Pak Budi',
                        grade: 'X IPS B',
                        imageUrl: 'https://picsum.photos/400/200',
                      ),
                      const SizedBox(height: 16),

                      ExamCard(
                        date: '31 Mar 2024',
                        subject: 'Bahasa Inggris: Advanced',
                        school: 'UTS',
                        teacher: 'Pak Budi',
                        grade: 'X IPS B',
                        imageUrl: 'https://picsum.photos/400/201',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
