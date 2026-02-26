import 'package:flutter/material.dart';

/// Dialog shown when the user presses back and all questions are answered.
///
/// Offers three actions:
/// 1. Finish the exam
/// 2. Exit without finishing (triggers block)
/// 3. Cancel (go back to quiz)
class ExitAllAnsweredDialog extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onExitWithoutFinish;

  const ExitAllAnsweredDialog({
    super.key,
    required this.onFinish,
    required this.onExitWithoutFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "Keluar Ujian?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: Text(
                "✓ Semua soal telah dijawab",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Apakah anda ingin:",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Finish Button
            _buildGradientButton(
              label: "Selesaikan Ujian",
              gradientColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              onPressed: () {
                Navigator.pop(context);
                onFinish();
              },
            ),
            const SizedBox(height: 10),
            // Exit without finish button
            _buildGradientButton(
              label: "Keluar Tanpa Menyelesaikan",
              gradientColors: const [Color(0xFFF44336), Color(0xFFC62828)],
              onPressed: () {
                Navigator.pop(context);
                onExitWithoutFinish();
              },
            ),
            const SizedBox(height: 10),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
