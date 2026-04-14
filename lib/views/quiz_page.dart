import 'dart:async';
import 'dart:io';
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
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/dialogs/exit_all_answered_dialog.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/widgets/end_quiz_dialog.dart';
import 'package:cbt_app/widgets/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/unanswered_finish_warning_dialog.dart';
import 'package:flutter/material.dart';
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
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _showExitConfirmation();
                        },
                        icon: Icon(Icons.arrow_back),
                        iconSize: 30,
                      ),
                      Text(
                        "Question ${currentQuestion + 1}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Offline indicator
                      if (_isOffline)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, size: 14, color: Colors.orange[800]),
                              SizedBox(width: 4),
                              Text('Offline', style: TextStyle(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      Container(
                        constraints: BoxConstraints(minWidth: 80),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            width: 1, 
                            color: _remainingTime.inMinutes < 5 ? Colors.red : Colors.black
                          ),
                        ),
                        child: Text(
                          _formatTime(_remainingTime),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _remainingTime.inMinutes < 5 ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          navigatePicker(
                            context,
                            widget.exam.quizList,
                            currentQuestion,
                          );
                        },
                        icon: Icon(Icons.grid_view_outlined, size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    widget.exam.quizList[currentQuestion].quizType == "ESSAY" 
                      ? QuizEssayPage(                          key: ValueKey('essay_${widget.exam.quizList[currentQuestion].questionId}_$currentQuestion'),                          question: ques, 
                          controller: essayController,
                          questionImage: widget.exam.quizList[currentQuestion].image,
                          onChanged: () {
                            // Auto-save essay after debounce
                            _submitAnswer();
                          },
                        ) 
                      : QuizPilganPage(
                          key: ValueKey('soal_${widget.exam.quizList[currentQuestion].questionId}_$currentQuestion'),
                          question: ques, 
                          answerList: answer,
                          questionImage: widget.exam.quizList[currentQuestion].image,
                          initialSelectedIndex: widget.exam.quizList[currentQuestion].selectedAnswerIndex,
                          initialSelectedIndices: widget.exam.quizList[currentQuestion].selectedAnswerIndices,
                          isMultipleChoice: widget.exam.quizList[currentQuestion].quizType == "MULTIPLE_CHOICE",
                          onAnswerSelected: (selectedIndex, {selectedIndices}) {
                            _onAnswerSelected(selectedIndex, selectedIndices: selectedIndices);
                          },
                        ),  
                    // Navigation Buttons
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      child: Row(
                        children: [
                          // Previous Button
                          if (currentQuestion > 0)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: Colors.grey[300],
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: previousQuestion,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          "Sebelumnya",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (currentQuestion > 0)
                            SizedBox(width: 10),
                          // Next/Finish Button
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: currentQuestion + 1 >= widget.exam.quizList.length 
                                    ? Colors.green 
                                    : ColorsApp.primaryColor,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: nextQuestion,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        currentQuestion + 1 >= widget.exam.quizList.length 
                                          ? "Selesaikan Ujian" 
                                          : "Selanjutnya",
                                        style: TextStyle(
                                          color: ColorsApp.secondaryColor,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      currentQuestion + 1 >= widget.exam.quizList.length 
                                        ? Icons.check_circle 
                                        : Icons.arrow_forward, 
                                      color: ColorsApp.secondaryColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

