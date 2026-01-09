import 'package:flutter/material.dart';
import 'package:cbt_app/model/ujian_response_model.dart';
import 'package:cbt_app/widgets/ExamCard.dart';

class ExamListSection extends StatelessWidget {
  final List<PesertaUjian> ujianList;
  final Function(String) formatDate;
  final Function(PesertaUjian, String, DateTime, int) onStartExam;

  const ExamListSection({
    super.key,
    required this.ujianList,
    required this.formatDate,
    required this.onStartExam,
  });

  String _getExamType(String namaUjian) {
    String examType = 'Ujian';
    if (namaUjian.toUpperCase().contains('UTS')) {
      examType = 'UTS';
    } else if (namaUjian.toUpperCase().contains('UAS')) {
      examType = 'UAS';
    } else if (namaUjian.toUpperCase().contains('ULANGAN')) {
      examType = 'Ulangan';
    }
    return examType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        Expanded(
          child: ujianList.isEmpty
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
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
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: ujianList.length,
                  itemBuilder: (context, index) {
                    final pesertaUjian = ujianList[index];
                    final ujian = pesertaUjian.ujian;

                    String examType = _getExamType(ujian.namaUjian);
                    String gradeText = '${ujian.tingkat} ${ujian.jurusan}';

                    return ExamCard(
                      date: formatDate(ujian.tanggalMulai.toString()),
                      subject: ujian.namaUjian,
                      school: examType,
                      teacher: ujian.mataPelajaran,
                      grade: gradeText,
                      imageUrl: 'assets/images/c${(index % 2) + 1}.jpg',
                      status: pesertaUjian.statusUjian,
                      score: pesertaUjian.hasil?.nilaiAkhir,
                      onBtnPressed: pesertaUjian.statusUjian == 'DINILAI'
                          ? () {}
                          : () => onStartExam(
                              pesertaUjian,
                              ujian.namaUjian,
                              ujian.tanggalMulai,
                              ujian.durasiMenit,
                            ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                ),
        ),
      ],
    );
  }
}
