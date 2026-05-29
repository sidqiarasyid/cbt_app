import 'package:flutter/material.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:cbt_app/widgets/cards/exam_card.dart';

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
                  color: const Color(0xFF11B1E2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Jadwal Ujian',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF11B1E2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${examList.length} Ujian',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF11B1E2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: examList.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada ujian tersedia',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 118),
                  itemCount: examList.length,
                  itemBuilder: (context, index) {
                    final examParticipant = examList[index];
                    final exam = examParticipant.exam;

                    final examType = ExamTypeHelper.getExamType(exam.examName);
                    final gradeText = '${exam.gradeLevel} ${exam.major ?? ''}';
                    final startLabel = formatDate(exam.startDate.toString());
                    final endLabel = formatDate(exam.endDate.toString());

                    return ExamCard(
                      date: startLabel,
                      endDate: endLabel,
                      subject: exam.examName,
                      school: examType,
                      teacher: exam.subject,
                      grade: gradeText,
                      imageUrl: 'assets/images/c${(index % 2) + 1}.jpg',
                      status: examParticipant.examStatus,
                      score: examParticipant.result?.finalScore,
                      isDownloaded: downloadedExamIds.contains(exam.examId),
                      isDownloading: downloadingExamIds.contains(exam.examId),
                      isBlocked: examParticipant.isBlocked,
                      onDownloadPressed: onDownloadExam != null
                          ? () => onDownloadExam!(
                                examParticipant,
                                exam.examName,
                                exam.startDate,
                                exam.durationMinutes,
                              )
                          : null,
                      onBtnPressed: (examParticipant.examStatus == 'GRADED' ||
                              examParticipant.examStatus == 'COMPLETED')
                          ? () {}
                          : () => onStartExam(
                                examParticipant,
                                exam.examName,
                                exam.startDate,
                                exam.durationMinutes,
                              ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                ),
        ),
      ],
    );
  }
}
