import 'package:flutter/material.dart';

/// Generic helper used by the quiz finish/auto-finish flow.
Future<void> showQuizRecoveryDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String content,
  required String actionLabel,
  required IconData actionIcon,
  required Color actionColor,
  required VoidCallback onAction,
  String? cancelLabel,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon, size: 48, color: iconColor),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel?.call();
            },
            child: Text(cancelLabel),
          ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            onAction();
          },
          icon: Icon(actionIcon, size: 18),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    ),
  );
}
