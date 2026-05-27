import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Numbered cell in the quiz picker grid.
/// Shows answer state (current/answered/empty) and a tiny icon hinting at
/// the question type so students can spot essays at a glance.
class PickerItem extends StatelessWidget {
  static const _primary = Color(0xFF11B1E2);
  static const _success = Color(0xFF22C55E);

  final VoidCallback pickerTap;
  final String cont;
  final bool isCurrent;
  final bool isAnswered;
  final String questionType;

  const PickerItem({
    super.key,
    required this.pickerTap,
    required this.cont,
    required this.isCurrent,
    required this.isAnswered,
    required this.questionType,
  });

  Color get _bg {
    if (isCurrent) return _primary;
    if (isAnswered) return _success;
    return Colors.white;
  }

  Color get _fg {
    if (isCurrent || isAnswered) return Colors.white;
    return Colors.black87;
  }

  Color get _border {
    if (isCurrent) return _primary;
    if (isAnswered) return _success;
    return Colors.grey[300]!;
  }

  IconData? get _typeIcon {
    switch (questionType) {
      case 'ESSAY':
        return Icons.edit_note_rounded;
      case 'MULTIPLE_CHOICE':
        return Icons.checklist_rounded;
      case 'SINGLE_CHOICE':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: pickerTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.4),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    cont,
                    style: TextStyle(
                      color: _fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_typeIcon != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      _typeIcon,
                      size: 11,
                      color: _fg.withValues(alpha: 0.7),
                    ),
                  ),
                if (isAnswered && !isCurrent)
                  const Positioned(
                    bottom: 3,
                    right: 3,
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isCurrent) return tile;
    // Subtle pulse for the active cell so students spot it on open.
    return tile
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}
