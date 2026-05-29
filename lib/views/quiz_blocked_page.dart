import 'package:cbt_app/controllers/exam_controller.dart';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/views/quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../utils/page_transitions.dart';

class QuizBlockedPage extends StatefulWidget {
  final String? examName;
  final DateTime? violationTime;
  final ExamParticipant? examParticipant;

  const QuizBlockedPage({
    super.key,
    this.examName,
    this.violationTime,
    this.examParticipant,
  });

  @override
  State<QuizBlockedPage> createState() => _QuizBlockedPageState();
}

class _QuizBlockedPageState extends State<QuizBlockedPage> {
  static const Color _primaryBlue = Color(0xFF11B1E2);

  final TextEditingController _codeController = TextEditingController();
  bool _isUnlocking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _formatViolationTime() {
    final dt = widget.violationTime ?? DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm';
  }

  Future<void> _submitUnlockCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Masukkan kode unlock terlebih dahulu');
      return;
    }
    if (widget.examParticipant == null) {
      setState(() => _errorMessage = 'Data ujian tidak tersedia');
      return;
    }

    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
    });

    try {
      final controller = ExamController();
      final exam = await controller.startExamWithCode(
        widget.examParticipant!,
        widget.examName ?? '',
        widget.examParticipant!.exam.startDate,
        unlockCode: code,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        fadeSlideRoute(QuizPage(exam: exam)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _isUnlocking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final examLabel = widget.examName != null ? '"${widget.examName}"' : 'ujian';
    final canUnlock = widget.examParticipant != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Blocked icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF44336), Color(0xFFC62828)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF44336).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.block_rounded, color: Colors.white, size: 60),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.06, 1.06),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              const Text(
                'Anda Terblokir',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC62828),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 20),

              // Violation info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF44336).withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFC62828)),
                        const SizedBox(width: 8),
                        const Text(
                          'Pelanggaran Terdeteksi',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC62828)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ujian $examLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatViolationTime(),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instruction card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey[500]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Minta kode unlock kepada guru/admin, lalu masukkan di bawah untuk melanjutkan ujian.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              if (canUnlock) ...[
                const SizedBox(height: 24),
                // Unlock code section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.key_rounded, size: 18, color: _primaryBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Masukkan Kode Unlock',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0E8FB5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        enabled: !_isUnlocking,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          _UpperCaseTextFormatter(),
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'AB12CD',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[400],
                            letterSpacing: 6,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _errorMessage != null ? Colors.red[300]! : Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        onSubmitted: (_) => _submitUnlockCode(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.error_outline, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isUnlocking ? null : _submitUnlockCode,
                            icon: _isUnlocking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.lock_open_rounded, size: 20),
                            label: Text(
                              _isUnlocking ? 'Membuka...' : 'Buka & Lanjutkan Ujian',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // Back to home button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      fadeSlideRoute(const MyHomePage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_rounded, size: 20, color: Colors.grey),
                  label: const Text(
                    'Kembali ke Menu Utama',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
