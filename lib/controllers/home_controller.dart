import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/model/ujian_response_model.dart';
import 'package:cbt_app/services/UjianService.dart';

class HomeController {
  final UjianService _ujianService = UjianService();

  Future<UjianResponseModel> getUjianList() {
    return _ujianService.getUjianSiswa();
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }


  Future<UjianModel> startUjian(
    PesertaUjian pesertaUjian,
    String namaUjian,
    DateTime tanggalMulai,
  ) async {
    final startUjianResponse = await _ujianService.startUjian(
      pesertaUjian.pesertaUjianId,
    );

    print('📥 API Response received');
    print('Total soal from API: ${startUjianResponse.soalList.length}');

    List<QuizModel> quizList = startUjianResponse.soalList.map((soalUjian) {
      try {
        return QuizModel.fromSoalUjian(soalUjian);
      } catch (e) {
        print('❌ Error converting soal ${soalUjian.soal.soalId}: $e');
        rethrow;
      }
    }).toList();

    print('✅ QuizList created: ${quizList.length} items');

    return UjianModel(
      ujianId: pesertaUjian.ujian.ujianId,
      subject: namaUjian,
      grade: pesertaUjian.ujian.tingkat,
      date: formatDate(tanggalMulai.toString()),
      teacher: pesertaUjian.ujian.mataPelajaran,
      type: 'Ujian',
      ujianImage: 'assets/images/c1.jpg',
      quizList: quizList,
      pesertaUjianId: pesertaUjian.pesertaUjianId,
      durasiMenit: startUjianResponse.pesertaUjian.durasiMenit,
      waktuMulai: startUjianResponse.pesertaUjian.waktuMulai,
      tanggalSelesai: pesertaUjian.ujian.tanggalSelesai,
    );
  }

  Future<bool> checkBlockStatus(int ujianId) async {
    SharedPreferences myPref = await SharedPreferences.getInstance();
    return myPref.getBool("blockKey $ujianId") ?? false;
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF11B1E2)),
              SizedBox(height: 16),
              Text('Memuat soal ujian...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Gagal'),
          ],
        ),
        content: Text(error.replaceAll('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
