import 'package:flutter/material.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:cbt_app/widgets/exam_card.dart';

class ExamListSection extends StatelessWidget {
  final List<ExamParticipant> examList;
  final Function(String) formatDate;
  final Function(ExamParticipant, String, DateTime, int) onStartExam;
  final Function(ExamParticipant, String, DateTime, int)? onDownloadExam;
  final Set<int> downloadedExamIds;
  final Set<int> downloadingExamIds;

  const ExamListSection({
    super.key,
    required this.examList,
    required this.formatDate,
    required this.onStartExam,
    this.onDownloadExam,
    this.downloadedExamIds = const {},
    this.downloadingExamIds = const {},
  });

  // Use shared helper from utils/helpers.dart

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
                  color: Color(0xFF11B1E2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${examList.length} Ujian',
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
          child: examList.isEmpty
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
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
                  itemCount: examList.length,
                  itemBuilder: (context, index) {
                    final examParticipant = examList[index];
                    final exam = examParticipant.exam;

                    String examType = ExamTypeHelper.getExamType(exam.examName);
                    String gradeText = '${exam.gradeLevel} ${exam.major ?? ''}';

                    return ExamCard(
                      date: formatDate(exam.startDate.toString()),
                      subject: exam.examName,
                      school: examType,
                      teacher: exam.subject,
                      grade: gradeText,
                      imageUrl: 'assets/images/c${(index % 2) + 1}.jpg',
                      status: examParticipant.examStatus,
                      score: examParticipant.result?.finalScore,
                      isDownloaded: downloadedExamIds.contains(exam.examId),
                      isDownloading: downloadingExamIds.contains(exam.examId),
                      onDownloadPressed: onDownloadExam != null
                          ? () => onDownloadExam!(
                              examParticipant,
                              exam.examName,
                              exam.startDate,
                              exam.durationMinutes,
                            )
                          : null,
                      onBtnPressed: (examParticipant.examStatus == 'GRADED' || examParticipant.examStatus == 'COMPLETED')
                          ? () {}
                          : () => onStartExam(
                              examParticipant,
                              exam.examName,
                              exam.startDate,
                              exam.durationMinutes,
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
