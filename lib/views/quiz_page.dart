import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_end_page.dart';
import 'package:cbt_app/views/quiz_essay_page.dart';
import 'package:cbt_app/views/quiz_picker.dart';
import 'package:cbt_app/views/quiz_multiple_choice_page.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/services/offline_exam_storage.dart';
import 'package:cbt_app/services/offline_sync_service.dart';
import 'package:cbt_app/widgets/dialogs/exit_all_answered_dialog.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/widgets/end_quiz_dialog.dart';
import 'package:cbt_app/widgets/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/unanswered_finish_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/page_transitions.dart';


class QuizPage extends StatefulWidget {
  final ExamModel exam;
  const QuizPage({super.key, required this.exam});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver{
  late String ques;
  late List<String> answer;
  int currentQuestion = 0;
  TextEditingController essayController = TextEditingController();
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  final ExamService _examService = ExamService();
  final OfflineSyncService _syncService = OfflineSyncService();
  bool _isBlocked = false;
  bool _isOffline = false;
  Timer? _inactiveTimer;
  Timer? _connectivityTimer;
  int _initialDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Debug check
    if (widget.exam.quizList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Tidak ada soal tersedia untuk ujian ini'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }
    
    loadCurrentQuestion();
    _initializeTimer();
    _startConnectivityCheck();
  }

  /// Memeriksa konektivitas secara periodik dan sinkronkan data offline
  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final wasOffline = _isOffline;
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        if (mounted) {
          setState(() {
            _isOffline = !isOnline;
          });
        }
        // If we just came back online, try to sync pending answers
        if (wasOffline && isOnline) {
          _syncService.syncAnswersForExam(widget.exam.examParticipantId);
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isBlocked) {
      // Already blocked — if user returns to app, navigate to blocked page
      if (state == AppLifecycleState.resumed) {
        _inactiveTimer?.cancel();
        _navigateToBlockedPage();
      }
      return;
    }

    if (state == AppLifecycleState.paused) {
      // User left the app (backgrounded, switched apps)
      _inactiveTimer?.cancel();
      _blockExam('APP_BACKGROUNDED');
    } else if (state == AppLifecycleState.inactive) {
      // Overlay detected (notification shade, split screen, PiP, etc.)
      // Use a short debounce: normal backgrounding goes inactive→paused in ~100ms,
      // but overlays stay in inactive state. 300ms filters out transient transitions.
      _inactiveTimer?.cancel();
      _inactiveTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_isBlocked && mounted) {
          _blockExam('OVERLAY_DETECTED');
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      // User returned — cancel any pending overlay block timer
      _inactiveTimer?.cancel();
    }
  }

  Future<void> _blockExam(String violationType) async {
    _isBlocked = true;
    _countdownTimer?.cancel();

    // 1. Persist block locally (works offline)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("blockKey ${widget.exam.examId}", true);

    // 2. Report violation to backend (fire-and-forget)
    _examService.reportViolation(
      examParticipantId: widget.exam.examParticipantId,
      violationType: violationType,
    );

    // 3. Navigate to blocked page when app resumes
    // If already resumed (inactive → resumed happens quickly), navigate now
    if (mounted) {
      _navigateToBlockedPage();
    }
  }

  void _navigateToBlockedPage() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      fadeSlideRoute(
        QuizBlockedPage(
          examName: widget.exam.subject,
          violationTime: DateTime.now(),
        ),
      ),
      (route) => false,
    );
  }

  void _initializeTimer() {
    // Use per-student remaining_seconds from backend (accounts for individual start time + duration).
    // Falls back to global exam end_date only if remainingSeconds is not available.
    final int? remainingSec = widget.exam.remainingSeconds;
    final DateTime? endTime = widget.exam.endDate;

    Duration remaining;

    if (remainingSec != null && remainingSec > 0) {
      remaining = Duration(seconds: remainingSec);
    } else if (endTime != null) {
      remaining = endTime.difference(DateTime.now());
    } else {
      // No timer info available — default to 60 min safety net
      remaining = Duration(minutes: 60);
    }
    
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      _remainingTime = Duration.zero;
      _autoFinishUjian();
    } else {
      _remainingTime = remaining;
      _initialDurationSeconds = remaining.inSeconds;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds <= 0) {
          timer.cancel();
          _autoFinishUjian();
        } else {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        }
      });
    });
  }

  void _autoFinishUjian({int retryCount = 0}) async {
    const maxRetries = 5;

    // Cek internet sebelum mengirim
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      debugPrint('[AutoFinish] No internet (attempt ${retryCount + 1})');
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 3 * (retryCount + 1)));
        if (mounted) _autoFinishUjian(retryCount: retryCount + 1);
      } else {
        // All retries exhausted — show persistent dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(Icons.timer_off_rounded, size: 48, color: Colors.red.shade400),
            title: const Text(
              'Waktu Ujian Habis',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Waktu ujian telah habis, tetapi tidak ada koneksi internet '
              'untuk mengirim hasil ujian. Hubungkan internet lalu tekan tombol kirim.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  _autoFinishUjian(retryCount: 0);
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Kirim Ujian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      // Sync pending answers first
      await _syncService.syncAnswersForExam(widget.exam.examParticipantId);
      await _examService.finishExam(widget.exam.examParticipantId);

      // Clean up offline data
      await OfflineExamStorage.clearPendingAnswers(widget.exam.examParticipantId);
      await OfflineExamStorage.removePendingFinish(widget.exam.examParticipantId);
      await OfflineExamStorage.clearCachedExamData(widget.exam.examId);
      await OfflineExamStorage.removeDownloadedMark(widget.exam.examId);

      if (!mounted) return;
      
      // Capture messenger before navigation pops the page
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Waktu ujian habis. Ujian telah selesai.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('[AutoFinish] Failed (attempt ${retryCount + 1}): $e');
      if (retryCount < maxRetries) {
        // Retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        if (mounted) _autoFinishUjian(retryCount: retryCount + 1);
      } else {
        // All retries exhausted — show dialog to retry manually
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            title: const Text(
              'Gagal Mengirim Ujian',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Waktu ujian habis tetapi gagal mengirim ke server. '
              'Pastikan internet tersambung lalu coba lagi, atau hubungi pengawas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  _autoFinishUjian(retryCount: 0);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11B1E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _inactiveTimer?.cancel();
    _connectivityTimer?.cancel();
    essayController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void loadCurrentQuestion() {
    final qList = widget.exam.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      return;
    }
    
    ques = qList[currentQuestion].question;
    
    if (qList[currentQuestion].quizType == "ESSAY") {
      essayController.text = qList[currentQuestion].answerEssay ?? '';
    } else {
      // Convert answerOptions to String list for QuizPilganPage
      answer = qList[currentQuestion].answerOptions?.map((option) => option.optionText).toList() ?? [];
    }
  }

  Future<void> _submitAnswer() async {
    final qList = widget.exam.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      return;
    }
    
    final quiz = qList[currentQuestion];
    
    try {
      if (quiz.quizType == "ESSAY") {
        final text = essayController.text.trim().isEmpty ? null : essayController.text.trim();
        
        // Always save locally first
        await OfflineExamStorage.savePendingAnswer(
          examParticipantId: widget.exam.examParticipantId,
          questionId: quiz.questionId,
          answerText: text,
          quizType: quiz.quizType,
        );
        
        setState(() {
          quiz.answerEssay = text;
          quiz.isSaved = text != null;
        });
        
        // Try to sync to server
        try {
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerText: text,
          );
          await OfflineExamStorage.removePendingAnswer(
            widget.exam.examParticipantId, quiz.questionId);
          if (mounted && _isOffline) setState(() => _isOffline = false);
        } catch (e) {
          _handleSubmitError(e);
        }
      } else if (quiz.quizType == "SINGLE_CHOICE") {
        int? optionId;
        if (quiz.selectedAnswerIndex != null && quiz.answerOptions != null) {
          optionId = quiz.answerOptions![quiz.selectedAnswerIndex!].optionId;
        }
        
        // Always save locally first
        await OfflineExamStorage.savePendingAnswer(
          examParticipantId: widget.exam.examParticipantId,
          questionId: quiz.questionId,
          answerOptionId: optionId,
          quizType: quiz.quizType,
        );
        
        setState(() {
          quiz.isSaved = optionId != null;
        });
        
        // Try to sync to server
        try {
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionId: optionId,
          );
          await OfflineExamStorage.removePendingAnswer(
            widget.exam.examParticipantId, quiz.questionId);
          if (mounted && _isOffline) setState(() => _isOffline = false);
        } catch (e) {
          _handleSubmitError(e);
        }
      } else if (quiz.quizType == "MULTIPLE_CHOICE") {
        List<int>? optionIds;
        if (quiz.selectedAnswerIndices != null && 
            quiz.selectedAnswerIndices!.isNotEmpty && 
            quiz.answerOptions != null) {
          optionIds = quiz.selectedAnswerIndices!
              .map((index) => quiz.answerOptions![index].optionId)
              .toList();
        }
        
        // Always save locally first
        await OfflineExamStorage.savePendingAnswer(
          examParticipantId: widget.exam.examParticipantId,
          questionId: quiz.questionId,
          answerOptionIds: optionIds ?? [],
          quizType: quiz.quizType,
        );
        
        setState(() {
          quiz.isSaved = optionIds != null && optionIds.isNotEmpty;
        });
        
        // Try to sync to server
        try {
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionIds: optionIds ?? [],
          );
          await OfflineExamStorage.removePendingAnswer(
            widget.exam.examParticipantId, quiz.questionId);
          if (mounted && _isOffline) setState(() => _isOffline = false);
        } catch (e) {
          _handleSubmitError(e);
        }
      }
      
      // Update cached exam data for offline
      await OfflineExamStorage.cacheExamData(widget.exam);
    } catch (e) {
      debugPrint('[SubmitAnswer] Failed: $e');
      // Jawaban tetap tersimpan secara lokal
    }
  }

  void _handleSubmitError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('Tidak dapat terhubung') || 
        errorStr.contains('timeout') ||
        errorStr.contains('SocketException') ||
        e is SocketException) {
      if (mounted && !_isOffline) {
        setState(() => _isOffline = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Mode offline - jawaban disimpan lokal')),
              ],
            ),
            backgroundColor: Colors.orange[700],
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      debugPrint('[SubmitAnswer] Non-network error: $e');
    }
  }

  void _onAnswerSelected(int? selectedIndex, {List<int>? selectedIndices}) {
    final qList = widget.exam.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      return;
    }
    
    final quiz = qList[currentQuestion];
    
    
    setState(() {
      if (quiz.quizType == "SINGLE_CHOICE") {
        quiz.selectedAnswerIndex = selectedIndex;
      } else if (quiz.quizType == "MULTIPLE_CHOICE") {
        quiz.selectedAnswerIndices = selectedIndices;
      }
    });
    
    // Auto-save after selection (including unselect)
    _submitAnswer();
  }

  void nextQuestion() {
    List<QuizModel> qList = widget.exam.quizList;
    // Flush pending essay debounce before navigating
    if (qList[currentQuestion].quizType == "ESSAY") {
      _submitAnswer();
    }
    qList[currentQuestion].isFinished = true;
    if (currentQuestion + 1 >= qList.length) {
      _showFinishConfirmation();
    } else {
      currentQuestion++;
      setState(() {
        loadCurrentQuestion();
      });
    }
  }

  void previousQuestion() {
    if (currentQuestion > 0) {
      // Flush pending essay debounce before navigating
      List<QuizModel> qList = widget.exam.quizList;
      if (qList[currentQuestion].quizType == "ESSAY") {
        _submitAnswer();
      }
      currentQuestion--;
      setState(() {
        loadCurrentQuestion();
      });
    }
  }

  void _showExitConfirmation() {
    // F3: Flush pending essay debounce before showing exit dialog
    List<QuizModel> qList = widget.exam.quizList;
    if (qList[currentQuestion].quizType == "ESSAY") {
      _submitAnswer();
    }
    int answeredCount = qList.where((q) => q.hasAnswer).length;
    int totalCount = qList.length;
    int unansweredCount = totalCount - answeredCount;
    
    if (unansweredCount == 0) {
      // All answered — show exit dialog with finish/exit/cancel options
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExitAllAnsweredDialog(
          onFinish: () => _showFinishConfirmation(),
          onExitWithoutFinish: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => EndQuizDialog(
                onYesPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(this.context);
                },
                onNoPressed: () {
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => UnansweredWarningDialog(
          unansweredCount: unansweredCount,
          onContinue: () async{
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool("blockKey ${widget.exam.examId}", true);
            
            // Report to backend
            _examService.reportViolation(
              examParticipantId: widget.exam.examParticipantId,
              violationType: 'EXAM_EXITED',
            );
            
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext); 
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              fadeSlideRoute(
                QuizBlockedPage(
                  examName: widget.exam.subject,
                  violationTime: DateTime.now(),
                ),
              ),
              (route) => false,
            );
          },
          onBack: () {
            Navigator.pop(dialogContext);
          },
        ),
      );
    }
  }

  void _showFinishConfirmation() {
    List<QuizModel> qList = widget.exam.quizList;
    int answeredCount = qList.where((q) => q.hasAnswer).length;
    int totalCount = qList.length;
    int unansweredCount = totalCount - answeredCount;
    bool allAnswered = unansweredCount == 0;
    
    if (allAnswered) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return FinishQuizDialog(
            onYesPressed: () async {
              Navigator.pop(context); 
              await _finishQuiz();
            },
            onNoPressed: () {
              Navigator.pop(context);
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return UnansweredFinishWarningDialog(
            unansweredCount: unansweredCount,
            onContinueFinish: () async {
              Navigator.pop(context);
              await _finishQuiz(); 
            },
            onBack: () {
              Navigator.pop(context); 
            },
          );
        },
      );
    }
  }

  Future<void> _finishQuiz() async {
    // ===== WAJIB INTERNET: Cek koneksi sebelum submit =====
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
          title: const Text(
            'Tidak Ada Koneksi Internet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Koneksi internet diperlukan untuk mengirim hasil ujian. '
            'Hubungkan ke internet lalu coba lagi.\n\n'
            'Jawaban Anda tetap tersimpan di perangkat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kembali ke Ujian'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                // Retry after user confirms
                await _finishQuiz();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11B1E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    // Show loading with green gradient (submit theme)
    showLoadingDialog(
      context,
      message: 'Mengirim jawaban...',
      gradientColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    );
    
    try {
      // Sync all pending answers before finishing
      await _syncService.syncAnswersForExam(widget.exam.examParticipantId);
      
      // Finish exam on server
      await _examService.finishExam(widget.exam.examParticipantId);
      
      // Clean up offline data
      await OfflineExamStorage.clearPendingAnswers(widget.exam.examParticipantId);
      await OfflineExamStorage.removePendingFinish(widget.exam.examParticipantId);
      await OfflineExamStorage.clearCachedExamData(widget.exam.examId);
      await OfflineExamStorage.removeDownloadedMark(widget.exam.examId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      Navigator.pushReplacement(
        context,
        fadeSlideRoute(
          QuizEndPage(
            exam: widget.exam,
            submittedAt: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      final errorStr = e.toString();
      final isNetworkError = errorStr.contains('Tidak dapat terhubung') || 
          errorStr.contains('timeout') ||
          errorStr.contains('SocketException') ||
          e is SocketException;
      
      if (isNetworkError) {
        // Koneksi terputus saat proses - minta coba lagi
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange.shade400),
            title: const Text(
              'Koneksi Terputus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Koneksi internet terputus saat mengirim ujian. '
              'Jawaban Anda sudah tersimpan. '
              'Hubungkan kembali dan coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kembali ke Ujian'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _finishQuiz();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11B1E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      } else {
        showErrorDialog(context, 'Gagal menyelesaikan ujian: ${_sanitizeError(errorStr)}');
      }
    }
  }

  String _sanitizeError(String error) {
    final cleaned = error.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (cleaned.contains('SocketException') || cleaned.contains('HttpException')) {
      return 'Tidak dapat terhubung ke server.';
    }
    return cleaned;
  }

  Future<void> navigatePicker(
    BuildContext context,
    List<QuizModel> qList,
    int curItem,
  ) async {
    final parentContext = this.context;
    int? res;
    res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pickerContext) => QuizPicker(
          quizList: qList,
          currItem: curItem,
          exam: widget.exam,
          initialRemainingTime: _remainingTime,
          onFinishQuiz: () async {
            // Close picker
            Navigator.pop(pickerContext);
            // Finish quiz
            if (!mounted) return;
            await _finishQuiz();
          },
          onExitQuiz: () {
            // Close picker
            Navigator.pop(pickerContext);
            // Exit quiz page without finishing
            if (!mounted) return;
            Navigator.pop(parentContext);
          },
        ),
      ),
    );

    if (!context.mounted) return;
    res ??= curItem;
    setState(() {
      currentQuestion = res!;
      loadCurrentQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (widget.exam.quizList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('Tidak ada soal tersedia'),
        ),
      );
    }
    
    // Ensure currentQuestion is valid
    if (currentQuestion >= widget.exam.quizList.length) {
      currentQuestion = widget.exam.quizList.length - 1;
    }
    if (currentQuestion < 0) {
      currentQuestion = 0;
    }
    
    final quiz = widget.exam.quizList[currentQuestion];
    final totalQuestions = widget.exam.quizList.length;
    final isLast = currentQuestion + 1 >= totalQuestions;
    final unansweredCount = widget.exam.quizList.where((q) => !q.hasAnswer).length;
    final timeLow = _remainingTime.inMinutes < 5;
    final timeCritical = _remainingTime.inMinutes < 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(quiz, totalQuestions, unansweredCount, timeLow, timeCritical),
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
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('q_${quiz.questionId}_$currentQuestion'),
                        child: _buildQuestionCard(quiz),
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
              child: _buildBottomNav(isLast),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (sticky) ────────────────────────────────────────────────────
  Widget _buildHeader(
    dynamic quiz,
    int totalQuestions,
    int unansweredCount,
    bool timeLow,
    bool timeCritical,
  ) {
    const primary = Color(0xFF11B1E2);
    final timerColor = timeCritical
        ? const Color(0xFFEF4444)
        : (timeLow ? const Color(0xFFF59E0B) : primary);
    final timerProgress = _initialDurationSeconds == 0
        ? 0.0
        : (_remainingTime.inSeconds / _initialDurationSeconds).clamp(0.0, 1.0);

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
            timeCritical ? Icons.warning_amber_rounded : Icons.access_time_rounded,
            size: 14,
            color: timerColor,
          ),
          const SizedBox(width: 5),
          Text(
            _formatTime(_remainingTime),
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
                  onPressed: _showExitConfirmation,
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
                            'Soal ${currentQuestion + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            ' / $totalQuestions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.exam.subject,
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
                if (_isOffline) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 12, color: Colors.orange[800]),
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
                _buildPickerButton(unansweredCount),
              ],
            ),
          ),
          // Linear time progress bar
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: timerProgress,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(timerColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton(int unansweredCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            navigatePicker(context, widget.exam.quizList, currentQuestion);
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

  // ─── Question card ──────────────────────────────────────────────────────
  Widget _buildQuestionCard(dynamic quiz) {
    final typeMeta = _typeMeta(quiz.quizType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type chip + saved indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeMeta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeMeta.icon, size: 12, color: typeMeta.color),
                    const SizedBox(width: 5),
                    Text(
                      typeMeta.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeMeta.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (quiz.hasAnswer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF22C55E)),
                      const SizedBox(width: 4),
                      Text(
                        quiz.isSaved ? 'Tersimpan' : 'Menyimpan…',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Question body
          quiz.quizType == "ESSAY"
              ? QuizEssayPage(
                  key: ValueKey('essay_${quiz.questionId}_$currentQuestion'),
                  question: ques,
                  controller: essayController,
                  questionImage: quiz.image,
                  onChanged: _submitAnswer,
                )
              : QuizPilganPage(
                  key: ValueKey('soal_${quiz.questionId}_$currentQuestion'),
                  question: ques,
                  answerList: answer,
                  questionImage: quiz.image,
                  initialSelectedIndex: quiz.selectedAnswerIndex,
                  initialSelectedIndices: quiz.selectedAnswerIndices,
                  isMultipleChoice: quiz.quizType == "MULTIPLE_CHOICE",
                  onAnswerSelected: (selectedIndex, {selectedIndices}) {
                    _onAnswerSelected(selectedIndex, selectedIndices: selectedIndices);
                  },
                ),
        ],
      ),
    );
  }

  _QuestionTypeMeta _typeMeta(String type) {
    switch (type) {
      case 'ESSAY':
        return const _QuestionTypeMeta(
          label: 'Esai',
          icon: Icons.edit_note_rounded,
          color: Color(0xFFA855F7),
        );
      case 'MULTIPLE_CHOICE':
        return const _QuestionTypeMeta(
          label: 'Pilihan Ganda Kompleks',
          icon: Icons.checklist_rounded,
          color: Color(0xFF0EA5E9),
        );
      case 'SINGLE_CHOICE':
      default:
        return const _QuestionTypeMeta(
          label: 'Pilihan Ganda',
          icon: Icons.radio_button_checked_rounded,
          color: Color(0xFF11B1E2),
        );
    }
  }

  // ─── Bottom navigation (floating) ───────────────────────────────────────
  Widget _buildBottomNav(bool isLast) {
    const primary = Color(0xFF11B1E2);
    const success = Color(0xFF22C55E);
    final hasPrev = currentQuestion > 0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (hasPrev)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        previousQuestion();
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Sebelumnya',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (hasPrev) const SizedBox(width: 10),
                Expanded(
                  flex: hasPrev ? 1 : 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      nextQuestion();
                    },
                    icon: Icon(
                      isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLast ? 'Selesaikan Ujian' : 'Selanjutnya',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast ? success : primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionTypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _QuestionTypeMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

