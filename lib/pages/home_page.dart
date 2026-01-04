import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/model/ujian_response_model.dart';
import 'package:cbt_app/pages/quiz_page.dart';
import 'package:cbt_app/services/UjianService.dart';
import 'package:cbt_app/widgets/StartDialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ExamCard.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UjianService _ujianService = UjianService();
  late Future<UjianResponseModel> _futureUjians;

  @override
  void initState() {
    super.initState();
    _futureUjians = _ujianService.getUjianSiswa();
  }

  String _formatDate(DateTime date) {
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


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UjianResponseModel>(
      future: _futureUjians,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF11B1E2)),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data ujian...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _futureUjians = _ujianService.getUjianSiswa();
                        });
                      },
                      icon: Icon(Icons.refresh_rounded),
                      label: Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF11B1E2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final ujianData = snapshot.data!;
        final ujianList = ujianData.ujians;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header with Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF11B1E2).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      FutureBuilder<SharedPreferences>(
                                        future: SharedPreferences.getInstance(),
                                        builder: (context, asyncSnapshot) {
                                          String? name = asyncSnapshot.data
                                              ?.getString('username');
                                          return Text(
                                            name ?? 'Siswa',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFF11B1E2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Jadwal Ujian',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF11B1E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${ujianList.length} Ujian',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF11B1E2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Exam List
                Expanded(
                  child: ujianList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada ujian tersedia',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: ujianList.length,
                          itemBuilder: (context, index) {
                            final pesertaUjian = ujianList[index];
                            final ujian = pesertaUjian.ujian;

                            // Determine exam type/name from namaUjian
                            String examType = 'Ujian';
                            if (ujian.namaUjian.toUpperCase().contains('UTS')) {
                              examType = 'UTS';
                            } else if (ujian.namaUjian.toUpperCase().contains(
                              'UAS',
                            )) {
                              examType = 'UAS';
                            } else if (ujian.namaUjian.toUpperCase().contains(
                              'ULANGAN',
                            )) {
                              examType = 'Ulangan';
                            }

                            // Format grade
                            String gradeText =
                                '${ujian.tingkat} ${ujian.jurusan}';

                            return ExamCard(
                              date: _formatDate(ujian.tanggalMulai),
                              subject: ujian.namaUjian,
                              school: examType,
                              teacher: ujian
                                  .mataPelajaran, // Using subject as teacher for now
                              grade: gradeText,
                              imageUrl: 'assets/images/c${(index % 2) + 1}.jpg',
                              status: pesertaUjian.statusUjian,
                              score: pesertaUjian.hasil?.nilaiAkhir,
                              onBtnPressed:
                                  pesertaUjian.statusUjian == 'DINILAI'
                                  ? () {
                                      // Show result dialog
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Hasil Ujian'),
                                            content: Text(
                                              'Nilai: ${pesertaUjian.hasil?.nilaiAkhir ?? 0}\n'
                                              'Status: Sudah dinilai',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  : () {
                                      // Start quiz dengan API
                                      _startUjianWithAPI(
                                        context,
                                        pesertaUjian,
                                        ujian.namaUjian,
                                        ujian.tanggalMulai,
                                        ujian.durasiMenit,
                                      );
                                    },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 16);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method untuk start ujian dengan API call
  void _startUjianWithAPI(
    BuildContext context,
    PesertaUjian pesertaUjian,
    String namaUjian,
    DateTime tanggalMulai,
    int durasiMenit,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StartDialog(
          okText: "Mulai Ujian",
          subject: namaUjian,
          examDate: tanggalMulai,
          btnPressed: () async {
            Navigator.pop(context); // Close dialog

            // Show loading
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
                      Text(
                        'Memuat soal ujian...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );

            try {
              // Call API startUjian
              final startUjianResponse = await _ujianService.startUjian(
                pesertaUjian.pesertaUjianId,
              );

              print('📥 API Response received');
              print(
                'Total soal from API: ${startUjianResponse.soalList.length}',
              );

              // Convert soal dari API ke QuizModel
              List<QuizModel> quizList = startUjianResponse.soalList.map((
                soalUjian,
              ) {
                try {
                  return QuizModel.fromSoalUjian(soalUjian);
                } catch (e) {
                  print('❌ Error converting soal ${soalUjian.soal.soalId}: $e');
                  rethrow;
                }
              }).toList();

              print('✅ QuizList created: ${quizList.length} items');

              // Create UjianModel untuk QuizPage
              UjianModel ujianModel = UjianModel(
                subject: namaUjian,
                grade: pesertaUjian.ujian.tingkat,
                date: _formatDate(tanggalMulai),
                teacher: pesertaUjian.ujian.mataPelajaran,
                type: 'Ujian',
                ujianImage: 'assets/images/c1.jpg',
                quizList: quizList,
                pesertaUjianId: pesertaUjian.pesertaUjianId,
                durasiMenit: startUjianResponse.pesertaUjian.durasiMenit,
                waktuMulai: startUjianResponse.pesertaUjian.waktuMulai,
                tanggalSelesai: pesertaUjian.ujian.tanggalSelesai, // Waktu deadline ujian
              );

              // Close loading
              if (context.mounted) {
                Navigator.pop(context);

                // Navigate to QuizPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(ujian: ujianModel),
                  ),
                ).then((_) {
                  // Refresh data when back from quiz
                  setState(() {
                    _futureUjians = _ujianService.getUjianSiswa();
                  });
                });
              }
            } catch (e) {
              // Close loading
              if (context.mounted) {
                Navigator.pop(context);

                // Show error dialog
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
                    content: Text(e.toString().replaceAll('Exception: ', '')),
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
          },
        );
      },
    );
  }
}

startQuiz(
  BuildContext context,
  String sub,
  DateTime examDate,
  VoidCallback btnPressed,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StartDialog(
        okText: "Mulai Ujian",
        subject: sub,
        examDate: examDate,
        btnPressed: btnPressed,
      );
    },
  );
}
