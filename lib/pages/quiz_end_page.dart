import 'package:cbt_app/main.dart';
import 'package:flutter/material.dart';
import 'package:cbt_app/style/style.dart';

import 'package:cbt_app/model/UjianModel.dart';

class QuizEndPage extends StatelessWidget {
  final UjianModel ujian;
  final DateTime? submittedAt; 

  const QuizEndPage({
    super.key,
    required this.ujian,
    this.submittedAt,
  });


  String _formatIndo(DateTime dt) {
    const hari = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulan = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    final namaHari = hari[(dt.weekday - 1) % 7];
    final namaBulan = bulan[dt.month - 1];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$namaHari, ${dt.day} $namaBulan ${dt.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final now = submittedAt ?? DateTime.now();
    final title = '${ujian.type} - ${ujian.subject}';
    return Scaffold(
      backgroundColor: ColorsApp.secondaryColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
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
                  color: ColorsApp.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 120),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Ujian disubmit pada ${_formatIndo(now)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
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
    );
  }
}
