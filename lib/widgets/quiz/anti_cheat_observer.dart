import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbt_app/providers/exam_session_provider.dart';

/// Watches the host app's lifecycle and forwards transitions into
/// [ExamSessionProvider] so it can apply anti-cheat rules. Wrap the quiz
/// scaffold with this; no UI of its own.
class AntiCheatObserver extends StatefulWidget {
  const AntiCheatObserver({super.key, required this.child});

  final Widget child;

  @override
  State<AntiCheatObserver> createState() => _AntiCheatObserverState();
}

class _AntiCheatObserverState extends State<AntiCheatObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = context.read<ExamSessionProvider>();
    switch (state) {
      case AppLifecycleState.paused:
        session.onAppBackgrounded();
        break;
      case AppLifecycleState.inactive:
        session.onAppInactive();
        break;
      case AppLifecycleState.resumed:
        session.onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
