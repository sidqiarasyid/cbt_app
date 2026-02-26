import 'dart:async';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_end_page.dart';
import 'package:cbt_app/views/quiz_essay_page.dart';
import 'package:cbt_app/views/quiz_picker.dart';
import 'package:cbt_app/views/quiz_multiple_choice_page.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/dialogs/exit_all_answered_dialog.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/widgets/end_quiz_dialog.dart';
import 'package:cbt_app/widgets/finish_quiz_dialog.dart';
import 'package:cbt_app/widgets/unanswered_warning_dialog.dart';
import 'package:cbt_app/widgets/unanswered_finish_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  bool _isBlocked = false;
  Timer? _inactiveTimer;

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
      MaterialPageRoute(
        builder: (context) => QuizBlockedPage(
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
    const maxRetries = 3;
    try {
      await _examService.finishExam(widget.exam.examParticipantId);
      if (!mounted) return;
      
      // Capture messenger before navigation pops the page
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(content: Text('Waktu ujian habis. Ujian telah selesai.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('[AutoFinish] Failed (attempt ${retryCount + 1}): $e');
      if (retryCount < maxRetries) {
        // Retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        if (mounted) _autoFinishUjian(retryCount: retryCount + 1);
      } else {
        // All retries exhausted — notify user
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Waktu habis. Gagal mengirim ujian otomatis, hubungi pengawas.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
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
        // Essay answer - submit even if empty to allow deletion
        await _examService.submitAnswer(
          examParticipantId: widget.exam.examParticipantId,
          questionId: quiz.questionId,
          answerText: essayController.text.trim().isEmpty ? null : essayController.text.trim(),
        );
        setState(() {
          quiz.answerEssay = essayController.text.trim().isEmpty ? null : essayController.text.trim();
          quiz.isSaved = essayController.text.trim().isNotEmpty;
        });
        if (essayController.text.trim().isEmpty) {
        } else {
        }
      } else if (quiz.quizType == "SINGLE_CHOICE") {
        if (quiz.selectedAnswerIndex != null && quiz.answerOptions != null) {
          // Submit selected answer
          final optionId = quiz.answerOptions![quiz.selectedAnswerIndex!].optionId;
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionId: optionId,
          );
          setState(() {
            quiz.isSaved = true;
          });
        } else {
          // No selection - delete existing answer
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionId: null,
          );
          setState(() {
            quiz.isSaved = false;
          });
        }
      } else if (quiz.quizType == "MULTIPLE_CHOICE") {
        if (quiz.selectedAnswerIndices != null && 
            quiz.selectedAnswerIndices!.isNotEmpty && 
            quiz.answerOptions != null) {
          // Submit selected answers
          final optionIds = quiz.selectedAnswerIndices!
              .map((index) => quiz.answerOptions![index].optionId)
              .toList();
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionIds: optionIds,
          );
          setState(() {
            quiz.isSaved = true;
          });
        } else {
          // No selection - delete existing answer
          await _examService.submitAnswer(
            examParticipantId: widget.exam.examParticipantId,
            questionId: quiz.questionId,
            answerOptionIds: [],
          );
          setState(() {
            quiz.isSaved = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[SubmitAnswer] Failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jawaban gagal disimpan. Coba lagi.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
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
              MaterialPageRoute(
                builder: (context) => QuizBlockedPage(
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
    // Show loading with green gradient (submit theme)
    showLoadingDialog(
      context,
      message: 'Mengirim jawaban...',
      gradientColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    );
    
    try {
      await _examService.finishExam(widget.exam.examParticipantId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      // Navigate to exam completion page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizEndPage(
            exam: widget.exam,
            submittedAt: DateTime.now(),
          ),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      showErrorDialog(context, 'Gagal menyelesaikan ujian. Silakan coba lagi.');
    }
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
                          onChanged: () {
                            // Auto-save essay after debounce
                            _submitAnswer();
                          },
                        ) 
                      : QuizPilganPage(
                          key: ValueKey('soal_${widget.exam.quizList[currentQuestion].questionId}_$currentQuestion'),
                          question: ques, 
                          answerList: answer,
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

