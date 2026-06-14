import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class ExamCard extends StatelessWidget {
  final String date;
  final String? endDate;
  final String subject;
  final String school;
  final String teacher;
  final String grade;
  final String imageUrl;
  final VoidCallback onBtnPressed;
  final VoidCallback? onDownloadPressed;
  final String? status;
  final double? score;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isBlocked;

  const ExamCard({
    super.key,
    required this.date,
    this.endDate,
    required this.subject,
    required this.school,
    required this.teacher,
    required this.grade,
    required this.imageUrl,
    required this.onBtnPressed,
    this.onDownloadPressed,
    this.status,
    this.score,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.isBlocked = false,
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
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

  IconData _statusIcon(String s) {
    switch (s) {
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

  String _statusText(String s) {
    switch (s) {
      case 'NOT_STARTED':
        return 'Belum Mulai';
      case 'IN_PROGRESS':
        return 'Berlangsung';
      case 'GRADED':
        return 'Sudah Dinilai';
      case 'COMPLETED':
        return 'Selesai';
      default:
        return s;
    }
  }

  String _buttonText() {
    if (isBlocked) return 'Masukkan Kode';
    if (status == 'GRADED') return 'Lihat Nilai';
    if (status == 'IN_PROGRESS') return 'Lanjutkan';
    return 'Mulai Ujian';
  }

  // ── badge widget (uniform size) ──────────────────────────────────────────

  Widget _badge({
    required Color color,
    required IconData icon,
    required String text,
    Gradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = status == 'GRADED' || status == 'COMPLETED';

    return Container(
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDone ? 0.04 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image with overlays ──────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ColorFiltered(
                  colorFilter: isDone
                      ? const ColorFilter.matrix([
                          0.3, 0.59, 0.11, 0, 0,
                          0.3, 0.59, 0.11, 0, 0,
                          0.3, 0.59, 0.11, 0, 0,
                          0,   0,    0,    1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.orange[200],
                        child: const Icon(Icons.landscape, size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              // Status badge (top-left)
              if (status != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: isBlocked
                      ? _badge(
                          color: Colors.red.shade700,
                          icon: Icons.lock_rounded,
                          text: 'Terblokir',
                        )
                      : _badge(
                          color: _statusColor(status!),
                          icon: _statusIcon(status!),
                          text: _statusText(status!),
                        ),
                ),

              // Date badge(s) - top-right
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _badge(
                      color: Colors.transparent,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                      ),
                      icon: Icons.calendar_today_rounded,
                      text: date,
                    ),
                    if (endDate != null && endDate!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _badge(
                        color: Colors.black54,
                        icon: Icons.event_busy_rounded,
                        text: endDate!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Subject + grade row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.grey.shade600 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorsApp.primaryColor.withValues(alpha: isDone ? 0.05 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              school,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDone ? Colors.grey.shade500 : ColorsApp.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (score != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 13, color: Colors.orange.shade600),
                                  const SizedBox(width: 3),
                                  Text(
                                    score!.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 11,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.grey.shade100 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDone ? Colors.grey.shade500 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Teacher / subject info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: isDone
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                            ),
                      color: isDone ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: isDone ? Colors.grey.shade500 : Colors.white,
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
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          teacher,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDone ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────────────────────────
          if (!isDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  // Blocked shortcut button
                  if (isBlocked)
                    _actionButton(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      ),
                      icon: Icons.lock_open_rounded,
                      label: 'Masukkan Kode Unlock',
                      onPressed: onBtnPressed,
                    )
                  else ...[
                    // Download button
                    if (status == 'NOT_STARTED' && !isDownloaded)
                      _actionButton(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        ),
                        icon: isDownloading ? null : Icons.download_rounded,
                        loadingIndicator: isDownloading,
                        label: isDownloading ? 'Mengunduh...' : 'Unduh Ujian',
                        onPressed: isDownloading ? null : onDownloadPressed,
                        margin: const EdgeInsets.only(bottom: 8),
                      ),

                    // Downloaded badge
                    if (isDownloaded && status == 'NOT_STARTED')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 15, color: Colors.green.shade700),
                            const SizedBox(width: 5),
                            Text(
                              'Ujian sudah diunduh - siap offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Start / continue button
                    if (isDownloaded || status == 'IN_PROGRESS')
                      _actionButton(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                        ),
                        icon: Icons.arrow_forward_rounded,
                        label: _buttonText(),
                        onPressed: onBtnPressed,
                        iconTrailing: true,
                      ),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Gradient gradient,
    IconData? icon,
    bool loadingIndicator = false,
    required String label,
    VoidCallback? onPressed,
    bool iconTrailing = false,
    EdgeInsets? margin,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!iconTrailing) ...[
          if (loadingIndicator)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else if (icon != null)
            Icon(icon, size: 18),
          if (icon != null || loadingIndicator) const SizedBox(width: 7),
        ],
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        if (iconTrailing && icon != null) ...[
          const SizedBox(width: 7),
          Icon(icon, size: 18),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      ),
    );
  }
}
