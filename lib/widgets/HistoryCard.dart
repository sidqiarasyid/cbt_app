import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class HistoryCard extends StatelessWidget {
  final String subject;
  final String grade;
  final String teacher;
  final String imageUrl;
  final String status; // 'selesai' or 'gagal'
  final bool isExpanded;
  final int? pilganScore;
  final String? essayStatus;
  final String? finalScore;
  final VoidCallback onExpandToggle;

  const HistoryCard({
    super.key,
    required this.subject,
    required this.grade,
    required this.teacher,
    required this.imageUrl,
    required this.status,
    required this.isExpanded,
    this.pilganScore,
    this.essayStatus,
    this.finalScore,
    required this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isSelesai = status.toLowerCase() == 'selesai';
    final statusColor = isSelesai
        ? ColorsApp.primaryColor
        : ColorsApp.pillStrokeColorRed;
    final statusBgColor = isSelesai ? Colors.white : Colors.white;
    final statusBorderColor = isSelesai
        ? ColorsApp.primaryColor
        : ColorsApp.pillStrokeColorRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSelesai ? onExpandToggle : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      child: Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.orange[200],
                            child: const Icon(
                              Icons.landscape,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Teacher
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              teacher,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status button
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              border: Border.all(
                                color: statusBorderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSelesai ? 'Selesai' : 'Gagal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Expandable section for "Selesai" status
            if (isSelesai) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Colors.grey[300]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lihat detail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              // Expanded details
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: Colors.grey[300]),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildScoreRow('Penjabaran Nilai', '', isHeader: true),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        'Nilai soal pilihan ganda',
                        pilganScore?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRow('Nilai soal essay', essayStatus ?? '-'),
                      const SizedBox(height: 8),
                      _buildScoreRow(
                        'Nilai Akhir',
                        finalScore ?? '-',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(
    String label,
    String value, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHeader ? 15 : 14,
            fontWeight: isHeader || isBold
                ? FontWeight.bold
                : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHeader ? 15 : 14,
            fontWeight: isHeader || isBold
                ? FontWeight.bold
                : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
