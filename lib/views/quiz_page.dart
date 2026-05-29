import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/providers/exam_session_provider.dart';
import 'package:cbt_app/utils/page_transitions.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_end_page.dart';
import 'package:cbt_app/views/quiz_picker.dart';
import 'package:cbt_app/widgets/dialogs/end_quiz_dialog.dart';
import 'package:cbt_app/widgets/dialogs/exit_all_answered_dialog.dart';
import 'package:cbt_app/widgets/dialogs/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/widgets/dialogs/unanswered_finish_warning_dialog.dart';
import 'package:cbt_app/widgets/dialogs/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/quiz/anti_cheat_observer.dart';
import 'package:cbt_app/widgets/quiz/quiz_bottom_nav.dart';
import 'package:cbt_app/widgets/quiz/quiz_header.dart';
import 'package:cbt_app/widgets/quiz/quiz_question_card.dart';
import 'package:cbt_app/widgets/quiz/quiz_recovery_dialogs.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.exam});
  final ExamModel exam;

  @override
  Widget build(BuildContext context) {
    if (exam.quizList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Tidak ada soal tersedia untuk ujian ini'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return ChangeNotifierProvider<ExamSessionProvider>(
      create: (_) => ExamSessionProvider()..start(exam),
      child: const AntiCheatObserver(child: _QuizPageBody()),
    );
  }
}

class _QuizPageBody extends StatefulWidget {
  const _QuizPageBody();

  @override
  State<_QuizPageBody> createState() => _QuizPageBodyState();
}

class _QuizPageBodyState extends State<_QuizPageBody> {
  final TextEditingController _essayController = TextEditingController();
  ExamSessionProvider? _session;
  int _lastQuestion = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<ExamSessionProvider>();
    if (_session != session) {
      _session?.removeListener(_onSessionChanged);
      _session = session;
      _session!.addListener(_onSessionChanged);
      _syncEssayController(session);
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _essayController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    final session = _session;
    if (session == null || !mounted) return;
    _syncEssayController(session);
    _maybeHandleBlock(session);
    _maybeHandleFinish(session);
    _maybeHandleAutoFinishFailure(session);
  }

  void _syncEssayController(ExamSessionProvider session) {
    if (session.currentQuestion == _lastQuestion) return;
    _lastQuestion = session.currentQuestion;
    final qList = session.exam.quizList;
    if (qList.isEmpty || _lastQuestion < 0 || _lastQuestion >= qList.length) {
      return;
    }
    final quiz = qList[_lastQuestion];
    if (quiz.quizType == 'ESSAY') {
      _essayController.text = quiz.answerEssay ?? '';
    }
  }

  void _maybeHandleBlock(ExamSessionProvider session) {
    if (session.pendingBlockViolationType == null) return;
    session.consumeBlockNavigation();
    Navigator.pushAndRemoveUntil(
      context,
      fadeSlideRoute(
        QuizBlockedPage(
          examName: session.exam.subject,
          violationTime: DateTime.now(),
        ),
      ),
      (route) => false,
    );
  }

  void _maybeHandleFinish(ExamSessionProvider session) {
    if (!session.finishedSuccessfully) return;
    Navigator.pushReplacement(
      context,
      fadeSlideRoute(
        QuizEndPage(exam: session.exam, submittedAt: DateTime.now()),
      ),
    );
  }

  void _maybeHandleAutoFinishFailure(ExamSessionProvider session) {
    if (!session.autoFinishFailed) return;
    showQuizRecoveryDialog(
      context,
      icon: Icons.timer_off_rounded,
      iconColor: Colors.red.shade400,
      title: 'Waktu Ujian Habis',
      content:
          'Waktu ujian telah habis, tetapi pengiriman ke server gagal. Hubungkan internet lalu coba lagi.',
      actionLabel: 'Kirim Ujian',
      actionIcon: Icons.send,
      actionColor: const Color(0xFF4CAF50),
      onAction: () => session.triggerAutoFinish(),
    );
  }

  void _onEssayChanged() {
    final session = _session!;
    final qList = session.exam.quizList;
    final idx = session.currentQuestion;
    if (idx < 0 || idx >= qList.length) return;
    qList[idx].answerEssay = _essayController.text;
    session.submitCurrentAnswer();
  }

  Future<void> _openPicker() async {
    final session = _session!;
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (pickerContext) => QuizPicker(
          quizList: session.exam.quizList,
          currItem: session.currentQuestion,
          exam: session.exam,
          initialRemainingTime: session.remaining,
          onFinishQuiz: () async {
            Navigator.pop(pickerContext);
            if (!mounted) return;
            await _finishQuiz();
          },
          onExitQuiz: () {
            Navigator.pop(pickerContext);
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
    );
    if (!mounted) return;
    session.goToQuestion(result ?? session.currentQuestion);
  }

  void _showExitConfirmation() {
    final session = _session!;
    final qList = session.exam.quizList;
    if (qList[session.currentQuestion].quizType == 'ESSAY') {
      session.submitCurrentAnswer();
    }
    final answered = qList.where((q) => q.hasAnswer).length;
    final unanswered = qList.length - answered;
    if (unanswered == 0) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ExitAllAnsweredDialog(
          onFinish: _showFinishConfirmation,
          onExitWithoutFinish: () {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (innerContext) => EndQuizDialog(
                onYesPressed: () {
                  Navigator.pop(innerContext);
                  Navigator.pop(context);
                },
                onNoPressed: () => Navigator.pop(innerContext),
              ),
            );
          },
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => UnansweredWarningDialog(
          unansweredCount: unanswered,
          onContinue: () async {
            await session.markExitedAndBlock();
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              fadeSlideRoute(
                QuizBlockedPage(
                  examName: session.exam.subject,
                  violationTime: DateTime.now(),
                ),
              ),
              (route) => false,
            );
          },
          onBack: () => Navigator.pop(dialogContext),
        ),
      );
    }
  }

  void _showFinishConfirmation() {
    final session = _session!;
    final qList = session.exam.quizList;
    final unanswered = qList.where((q) => !q.hasAnswer).length;
    if (unanswered == 0) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => FinishQuizDialog(
          onYesPressed: () async {
            Navigator.pop(dialogContext);
            await _finishQuiz();
          },
          onNoPressed: () => Navigator.pop(dialogContext),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => UnansweredFinishWarningDialog(
          unansweredCount: unanswered,
          onContinueFinish: () async {
            Navigator.pop(dialogContext);
            await _finishQuiz();
          },
          onBack: () => Navigator.pop(dialogContext),
        ),
      );
    }
  }

  Future<void> _finishQuiz() async {
    final session = _session!;
    if (!await session.hasInternet()) {
      if (!mounted) return;
      showQuizRecoveryDialog(
        context,
        icon: Icons.wifi_off_rounded,
        iconColor: Colors.red.shade400,
        title: 'Tidak Ada Koneksi Internet',
        content:
            'Koneksi internet diperlukan untuk mengirim hasil ujian. Hubungkan ke internet lalu coba lagi.\n\nJawaban Anda tetap tersimpan di perangkat.',
        actionLabel: 'Coba Lagi',
        actionIcon: Icons.refresh,
        actionColor: const Color(0xFF11B1E2),
        onAction: _finishQuiz,
        cancelLabel: 'Kembali ke Ujian',
      );
      return;
    }

    if (!mounted) return;
    showLoadingDialog(
      context,
      message: 'Mengirim jawaban...',
      gradientColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    );

    final result = await session.finishQuiz();
    if (!mounted) return;
    Navigator.pop(context);

    switch (result.kind) {
      case FinishResultKind.success:
        // Navigation handled by _maybeHandleFinish listener.
        break;
      case FinishResultKind.networkError:
        showQuizRecoveryDialog(
          context,
          icon: Icons.cloud_off_rounded,
          iconColor: Colors.orange.shade400,
          title: 'Koneksi Terputus',
          content:
              'Koneksi internet terputus saat mengirim ujian. Jawaban Anda sudah tersimpan. Hubungkan kembali dan coba lagi.',
          actionLabel: 'Coba Lagi',
          actionIcon: Icons.refresh,
          actionColor: const Color(0xFF11B1E2),
          onAction: _finishQuiz,
          cancelLabel: 'Kembali ke Ujian',
        );
        break;
      case FinishResultKind.noInternet:
        showQuizRecoveryDialog(
          context,
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.red.shade400,
          title: 'Tidak Ada Koneksi Internet',
          content:
              'Koneksi internet diperlukan untuk mengirim hasil ujian. Hubungkan ke internet lalu coba lagi.',
          actionLabel: 'Coba Lagi',
          actionIcon: Icons.refresh,
          actionColor: const Color(0xFF11B1E2),
          onAction: _finishQuiz,
          cancelLabel: 'Kembali ke Ujian',
        );
        break;
      case FinishResultKind.otherError:
        showErrorDialog(
            context, 'Gagal menyelesaikan ujian: ${result.message}');
        break;
    }
  }

  void _onNextPressed() {
    final session = _session!;
    final qList = session.exam.quizList;
    if (session.currentQuestion + 1 >= qList.length) {
      _showFinishConfirmation();
    } else {
      session.nextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ExamSessionProvider>();
    final qList = session.exam.quizList;
    if (qList.isEmpty) {
      return const Scaffold(body: Center(child: Text('Tidak ada soal tersedia')));
    }
    final idx = session.currentQuestion.clamp(0, qList.length - 1);
    final QuizModel quiz = qList[idx];
    final unansweredCount = qList.where((q) => !q.hasAnswer).length;
    final isLast = idx + 1 >= qList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                QuizHeader(
                  unansweredCount: unansweredCount,
                  onBack: _showExitConfirmation,
                  onOpenPicker: _openPicker,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('q_${quiz.questionId}_$idx'),
                        child: QuizQuestionCard(
                          quiz: quiz,
                          currentQuestion: idx,
                          essayController: _essayController,
                          onEssayChanged: _onEssayChanged,
                          onAnswerSelected: (selectedIndex, {selectedIndices}) {
                            session.selectAnswer(selectedIndex,
                                selectedIndices: selectedIndices);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuizBottomNav(
                hasPrevious: idx > 0,
                isLast: isLast,
                onPrevious: session.previousQuestion,
                onNext: _onNextPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
