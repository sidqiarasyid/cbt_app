import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:flutter/material.dart';

class HistoryCard extends StatelessWidget {
  final String examName;
  final String subject;
  final String gradeLevel;
  final String major;
  final String status;
  final double? finalScore;
  final DateTime submitDate;
  final DateTime startDate;
  final DateTime endDate;
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const HistoryCard({
    super.key,
    required this.examName,
    required this.subject,
    required this.gradeLevel,
    required this.major,
    required this.status,
    this.finalScore,
    required this.submitDate,
    required this.startDate,
    required this.endDate,
    required this.isExpanded,
    required this.onExpandToggle,
  });

  bool get _isFullyGraded => status == 'GRADED';
  bool get _isCompleted => status == 'COMPLETED'; // essay not yet graded
  bool get _isGraded => _isFullyGraded || _isCompleted;
  bool get _isNotAttempted => status == 'NOT_ATTEMPTED';
  bool get _isExamEnded => endDate.isBefore(DateTime.now());
  bool get _hasScore => finalScore != null && _isFullyGraded && _isExamEnded;

  Color get _statusColor {
    if (_isNotAttempted) return const Color(0xFF9E9E9E);
    if (_isGraded && !_isExamEnded) return const Color(0xFFF57F17);
    if (_isCompleted && _isExamEnded) return const Color(0xFFE65100); // essay not graded
    if (_isFullyGraded) return ColorsApp.primaryColor;
    return ColorsApp.pillStrokeColorRed;
  }

  Color get _statusBgColor {
    if (_isNotAttempted) return Colors.grey[100]!;
    if (_isGraded && !_isExamEnded) return const Color(0xFFFFF8E1);
    if (_isCompleted && _isExamEnded) return const Color(0xFFFFF3E0); // essay not graded
    if (_isFullyGraded) return ColorsApp.pillFillColorGreen;
    return ColorsApp.pillFillColorRed;
  }

  String get _statusLabel {
    if (_isNotAttempted) return 'Tidak Mengerjakan';
    if (_isGraded && !_isExamEnded) return 'Menunggu Tenggat';
    if (_isCompleted && _isExamEnded) return 'Menunggu Penilaian';
    if (_isFullyGraded) return 'Selesai';
    return 'Belum Dinilai';
  }

  IconData get _statusIcon {
    if (_isNotAttempted) return Icons.cancel_rounded;
    if (_isGraded && !_isExamEnded) return Icons.schedule_rounded;
    if (_isCompleted && _isExamEnded) return Icons.rate_review_rounded;
    if (_isFullyGraded) return Icons.check_circle_rounded;
    return Icons.pending_rounded;
  }

  Color get _scoreColor {
    if (finalScore == null) return Colors.grey;
    if (finalScore! >= 80) return const Color(0xFF2E7D32);
    if (finalScore! >= 60) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool canExpand = (_isGraded || _isNotAttempted) && _isExamEnded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: canExpand ? onExpandToggle : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(),
            if (canExpand) _buildExpandableSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Exam name + Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isNotAttempted
                      ? Colors.grey.withValues(alpha: 0.1)
                      : ColorsApp.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isNotAttempted
                      ? Icons.assignment_late_rounded
                      : Icons.assignment_rounded,
                  color: _isNotAttempted
                      ? Colors.grey
                      : ColorsApp.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Exam name + subject
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: _isNotAttempted
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          // Info chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.school_rounded, gradeLevel),
              if (major.isNotEmpty)
                _buildInfoChip(Icons.category_rounded, major),
              _buildInfoChip(
                Icons.calendar_today_rounded,
                DateFormatter.formatDate(submitDate),
              ),
              _buildInfoChip(
                Icons.access_time_rounded,
                '${_formatTime(startDate)} - ${_formatTime(endDate)}',
              ),
            ],
          ),
          // Score preview (only for graded with score)
          if (_hasScore) ...[
            const SizedBox(height: 14),
            _buildScorePreview(),
          ],
          // Waiting for deadline notice
          if (_isGraded && !_isExamEnded && !_isNotAttempted) ...[
            const SizedBox(height: 14),
            _buildWaitingDeadlineNotice(),
          ],
          // Essay not graded notice (exam ended but essay not graded)
          if (_isCompleted && _isExamEnded && !_isNotAttempted) ...[
            const SizedBox(height: 14),
            _buildEssayNotGradedNotice(),
          ],
          // Not attempted notice
          if (_isNotAttempted) ...[
            const SizedBox(height: 14),
            _buildNotAttemptedNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 14, color: _statusColor),
          const SizedBox(width: 4),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, size: 20, color: _scoreColor),
          const SizedBox(width: 10),
          Text(
            'Nilai: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            finalScore!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingDeadlineNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFFF57F17)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nilai akan tersedia setelah tenggat ujian berakhir',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssayNotGradedNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review_rounded, size: 20, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Soal essay belum selesai dinilai. Nilai akan muncul setelah guru menyelesaikan penilaian.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAttemptedNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ujian tidak dikerjakan. Nilai tidak tersedia.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection() {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey[200]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpanded ? 'Sembunyikan detail' : 'Lihat detail',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ColorsApp.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: ColorsApp.primaryColor,
              ),
            ],
          ),
        ),
        // Expanded details
        if (isExpanded) ...[
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Ujian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Nama Ujian', examName),
                _buildDetailRow('Mata Pelajaran', subject),
                _buildDetailRow('Kelas', gradeLevel),
                if (major.isNotEmpty) _buildDetailRow('Jurusan', major),
                _buildDetailRow(
                  _isNotAttempted ? 'Berakhir Pada' : 'Tanggal Selesai',
                  DateFormatter.formatDate(submitDate),
                ),
                _buildDetailRow(
                  'Status',
                  _isNotAttempted ? 'Tidak Mengerjakan' : 'Selesai',
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  'Nilai Akhir',
                  finalScore != null
                      ? finalScore!.toStringAsFixed(1)
                      : '-',
                  isBold: true,
                  valueColor: finalScore != null ? _scoreColor : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
