import 'dart:async';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/widgets/picker_item.dart';
import 'package:cbt_app/widgets/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/end_quiz_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizPicker extends StatefulWidget {
  final List<QuizModel> quizList;
  final int currItem;
  final ExamModel exam;
  final Duration initialRemainingTime;
  final VoidCallback? onFinishQuiz;
  final VoidCallback? onExitQuiz;

  const QuizPicker({
    super.key,
    required this.quizList,
    required this.currItem,
    required this.exam,
    this.initialRemainingTime = Duration.zero,
    this.onFinishQuiz,
    this.onExitQuiz,
  });

  @override
  State<QuizPicker> createState() => _QuizPickerState();
}

class _QuizPickerState extends State<QuizPicker> {
  static const _primary = Color(0xFF11B1E2);
  static const _primaryDark = Color(0xFF0E8FB5);
  static const _success = Color(0xFF22C55E);
  static const _danger = Color(0xFFEF4444);

  Timer? _ticker;
  late Duration _remaining;

  int get _answeredCount => widget.quizList.where((q) => q.hasAnswer).length;
  int get _totalCount => widget.quizList.length;
  int get _unansweredCount => _totalCount - _answeredCount;
  bool get _allAnswered => _unansweredCount == 0;
  double get _progress => _totalCount == 0 ? 0 : _answeredCount / _totalCount;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialRemainingTime;
    if (_remaining > Duration.zero) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds <= 0) {
            _ticker?.cancel();
            return;
          }
          _remaining -= const Duration(seconds: 1);
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
  }

  void _handleFinishQuiz() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinishQuizDialog(
        onYesPressed: () {
          Navigator.pop(context);
          widget.onFinishQuiz?.call();
        },
        onNoPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _handleExitWithoutSubmit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnansweredWarningDialog(
        unansweredCount: _unansweredCount,
        onContinue: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => EndQuizDialog(
              onYesPressed: () {
                Navigator.pop(context);
                widget.onExitQuiz?.call();
              },
              onNoPressed: () => Navigator.pop(context),
            ),
          );
        },
        onBack: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLow = _remaining.inMinutes < 5 && _remaining > Duration.zero;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(),
            // ── Top stat card ──
            _buildStatCard(timeLow),
            const SizedBox(height: 12),
            // ── Legend ──
            _buildLegend(),
            const SizedBox(height: 16),
            // ── Grid ──
            Expanded(child: _buildGrid()),
            // ── Bottom action area ──
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 26,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Navigasi Soal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.exam.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(bool timeLow) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Jawaban',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_answeredCount / $_totalCount soal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                // Timer chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: timeLow ? _danger : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        timeLow ? Icons.warning_amber_rounded : Icons.access_time_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _remaining > Duration.zero ? _formatTime(_remaining) : '--:--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _legendChip(_primary, 'Saat ini'),
          _legendChip(_success, 'Dijawab'),
          _legendChip(Colors.white, 'Belum dijawab', borderColor: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.2)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    // Group items per 10 with section dividers
    final total = widget.quizList.length;
    final sections = <Widget>[];

    for (int start = 0; start < total; start += 10) {
      final end = (start + 10).clamp(0, total);
      sections.add(
        Padding(
          padding: EdgeInsets.fromLTRB(20, start == 0 ? 0 : 18, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Soal ${start + 1} – $end',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: end - start,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, idx) {
              final absoluteIdx = start + idx;
              final qItem = widget.quizList[absoluteIdx];
              return PickerItem(
                cont: '${absoluteIdx + 1}',
                isCurrent: absoluteIdx == widget.currItem,
                isAnswered: qItem.hasAnswer,
                questionType: qItem.quizType,
                pickerTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context, absoluteIdx);
                },
              );
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  _allAnswered ? _success : _primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _allAnswered ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _allAnswered ? _success : Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _allAnswered
                        ? 'Semua soal telah dijawab — siap dikirim'
                        : '$_unansweredCount soal belum dijawab',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _allAnswered ? _success : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _handleExitWithoutSubmit,
                    icon: Icon(Icons.logout_rounded, size: 18, color: _danger),
                    label: Text(
                      'Keluar',
                      style: TextStyle(
                        color: _danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: _danger.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _allAnswered ? _handleFinishQuiz : _handleExitWithoutSubmit,
                    icon: Icon(
                      _allAnswered ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      _allAnswered ? 'Selesaikan Ujian' : 'Lanjutkan Mengerjakan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allAnswered ? _success : _primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
