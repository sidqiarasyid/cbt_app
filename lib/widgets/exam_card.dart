import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class ExamCard extends StatelessWidget {
  final String date;
  final String subject;
  final String school;
  final String teacher;
  final String grade;
  final String imageUrl;
  final VoidCallback onBtnPressed;
  final String? status; // Optional status field
  final double? score; // Optional score field

  const ExamCard({
    super.key,
    required this.date,
    required this.subject,
    required this.school,
    required this.teacher,
    required this.grade,
    required this.imageUrl,
    required this.onBtnPressed,
    this.status,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Date overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[300]),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.orange[200],
                        child: const Icon(
                          Icons.landscape,
                          size: 50,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Date overlay
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF11B1E2).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Status badge (if available)
              if (status != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status!),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status!),
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getStatusText(status!),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Subject and Grade
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorsApp.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              school,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorsApp.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Show score if available
                          if (score != null) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.orange.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    score!.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Teacher Info
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mata Pelajaran',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          teacher,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button - Only show if not GRADED or COMPLETED
          if (status != 'GRADED' && status != 'COMPLETED')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF11B1E2).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onBtnPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getButtonText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper methods for status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return Colors.blue.shade600;
      case 'IN_PROGRESS':
        return Colors.orange.shade600;
      case 'GRADED':
        return Colors.green.shade600;
      case 'COMPLETED':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return Icons.schedule_rounded;
      case 'IN_PROGRESS':
        return Icons.pending_rounded;
      case 'GRADED':
        return Icons.check_circle_rounded;
      case 'COMPLETED':
        return Icons.done_all_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return 'Belum Mulai';
      case 'IN_PROGRESS':
        return 'Sedang Berlangsung';
      case 'GRADED':
        return 'Sudah Dinilai';
      case 'COMPLETED':
        return 'Selesai';
      default:
        return status;
    }
  }

  String _getButtonText() {
    if (status == 'GRADED') {
      return 'Lihat Nilai';
    } else if (status == 'IN_PROGRESS') {
      return 'Lanjutkan';
    }
    return 'Mulai Ujian';
  }
}
