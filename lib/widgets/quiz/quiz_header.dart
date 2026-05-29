import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cbt_app/providers/exam_session_provider.dart';

class QuizHeader extends StatelessWidget {
  const QuizHeader({
    super.key,
    required this.unansweredCount,
    required this.onBack,
    required this.onOpenPicker,
  });

  final int unansweredCount;
  final VoidCallback onBack;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ExamSessionProvider>();
    final exam = session.exam;
    final remaining = session.remaining;
    final timeLow = remaining.inMinutes < 5;
    final timeCritical = remaining.inMinutes < 1;

    const primary = Color(0xFF11B1E2);
    final timerColor = timeCritical
        ? const Color(0xFFEF4444)
        : (timeLow ? const Color(0xFFF59E0B) : primary);

    Widget timerChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: timerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            timeCritical
                ? Icons.warning_amber_rounded
                : Icons.access_time_rounded,
            size: 14,
            color: timerColor,
          ),
          const SizedBox(width: 5),
          Text(
            session.formatRemaining(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: timerColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
    if (timeCritical) {
      timerChip = timerChip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 600.ms,
            curve: Curves.easeInOut,
          );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 24,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Soal ${session.currentQuestion + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            ' / ${exam.quizList.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        exam.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.isOffline) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 12, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                timerChip,
                const SizedBox(width: 4),
                _PickerButton(
                  unansweredCount: unansweredCount,
                  onTap: onOpenPicker,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: session.timerProgress,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(timerColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.unansweredCount, required this.onTap});

  final int unansweredCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          icon: const Icon(Icons.grid_view_rounded, size: 24),
          color: Colors.black87,
        ),
        if (unansweredCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unansweredCount > 99 ? '99+' : '$unansweredCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
