import 'dart:async';
import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/pages/quiz_blocked_page.dart';
import 'package:cbt_app/pages/quiz_essay_page.dart';
import 'package:cbt_app/pages/quiz_picker.dart';
import 'package:cbt_app/pages/quiz_pilgan_page.dart';
import 'package:cbt_app/services/UjianService.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/EndQuizDialog.dart';
import 'package:cbt_app/widgets/FinishQuizDialog.dart';
import 'package:cbt_app/widgets/UnansweredWarningDialog.dart';
import 'package:cbt_app/widgets/UnansweredFinishWarningDialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class QuizPage extends StatefulWidget {
  final UjianModel ujian;
  const QuizPage({super.key, required this.ujian});

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
  final UjianService _ujianService = UjianService();
  DateTime? exitTime;
  Duration? exitDuration;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Debug check
    if (widget.ujian.quizList.isEmpty) {
      print('❌ ERROR: quizList is empty!');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada soal tersedia untuk ujian ini'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }
    
    print('✅ QuizList loaded: ${widget.ujian.quizList.length} soal');
    loadCurrentQuestion();
    _initializeTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)  { 
    if(state == AppLifecycleState.paused || state == AppLifecycleState.inactive){
      exitTime = DateTime.now();
    } else if(state == AppLifecycleState.resumed){
      if(exitTime != null){
        exitDuration = DateTime.now().difference(exitTime!);
        if(exitDuration!.inSeconds > 10){
          //hit block API
          if(mounted){
            print("DEBUG: Duration > 5s. Attempting navigation...");
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => QuizBlockedPage(),), (route)=> false);
          }
        }
        exitTime = null;
      }
    }
  }

  void _initializeTimer() {
    // Gunakan tanggalSelesai dari server jika tersedia
    DateTime? endTime;
    
    if (widget.ujian.tanggalSelesai != null) {
      // Gunakan waktu selesai ujian dari server (lebih akurat)
      endTime = widget.ujian.tanggalSelesai;
    } else if (widget.ujian.waktuMulai != null && widget.ujian.durasiMenit > 0) {
      // Fallback: kalkulasi dari waktu mulai + durasi
      endTime = widget.ujian.waktuMulai!.add(Duration(minutes: widget.ujian.durasiMenit));
    }
    
    if (endTime != null) {
      final Duration remaining = endTime.difference(DateTime.now());
      
      if (remaining.isNegative) {
        _remainingTime = Duration.zero;
        _autoFinishUjian();
      } else {
        _remainingTime = remaining;
        _startCountdown();
      }
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

  void _autoFinishUjian() async {
    try {
      await _ujianService.finishUjian(widget.ujian.pesertaUjianId);
      if (!mounted) return;
      
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Waktu ujian habis. Ujian telah selesai.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('Error auto finish ujian: $e');
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    essayController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void loadCurrentQuestion() {
    final qList = widget.ujian.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      print('❌ Invalid currentQuestion index: $currentQuestion, list length: ${qList.length}');
      return;
    }
    
    ques = qList[currentQuestion].question;
    
    if (qList[currentQuestion].quizType == "ESSAY") {
      essayController.text = qList[currentQuestion].answerEssay ?? '';
    } else {
      // Convert opsiJawaban to String list for QuizPilganPage
      answer = qList[currentQuestion].opsiJawaban?.map((opsi) => opsi.teksOpsi).toList() ?? [];
    }
  }

  Future<void> _submitAnswer() async {
    final qList = widget.ujian.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      print('❌ Cannot submit: Invalid question index');
      return;
    }
    
    final quiz = qList[currentQuestion];
    
    try {
      if (quiz.quizType == "ESSAY") {
        // Essay answer - submit even if empty to allow deletion
        await _ujianService.submitJawaban(
          pesertaUjianId: widget.ujian.pesertaUjianId,
          soalId: quiz.soalId,
          teksJawaban: essayController.text.trim().isEmpty ? null : essayController.text.trim(),
        );
        setState(() {
          quiz.answerEssay = essayController.text.trim().isEmpty ? null : essayController.text.trim();
          quiz.isSaved = essayController.text.trim().isNotEmpty;
        });
        if (essayController.text.trim().isEmpty) {
          print('🗑️ Essay answer deleted for soal ${quiz.soalId}');
        } else {
          print('✅ Essay answer submitted for soal ${quiz.soalId}');
        }
      } else if (quiz.quizType == "PILIHAN_GANDA_SINGLE") {
        if (quiz.selectedAnswerIndex != null && quiz.opsiJawaban != null) {
          // Submit selected answer
          final opsiId = quiz.opsiJawaban![quiz.selectedAnswerIndex!].opsiId;
          await _ujianService.submitJawaban(
            pesertaUjianId: widget.ujian.pesertaUjianId,
            soalId: quiz.soalId,
            opsiJawabanId: opsiId,
          );
          setState(() {
            quiz.isSaved = true;
          });
          print('✅ Single choice answer submitted: opsi $opsiId');
        } else {
          // No selection - delete existing answer
          await _ujianService.submitJawaban(
            pesertaUjianId: widget.ujian.pesertaUjianId,
            soalId: quiz.soalId,
            opsiJawabanId: null,
          );
          setState(() {
            quiz.isSaved = false;
          });
          print('🗑️ Single choice answer deleted for soal ${quiz.soalId}');
        }
      } else if (quiz.quizType == "PILIHAN_GANDA_MULTIPLE") {
        if (quiz.selectedAnswerIndices != null && 
            quiz.selectedAnswerIndices!.isNotEmpty && 
            quiz.opsiJawaban != null) {
          // Submit selected answers
          final opsiIds = quiz.selectedAnswerIndices!
              .map((index) => quiz.opsiJawaban![index].opsiId)
              .toList();
          await _ujianService.submitJawaban(
            pesertaUjianId: widget.ujian.pesertaUjianId,
            soalId: quiz.soalId,
            opsiJawabanIds: opsiIds,
          );
          setState(() {
            quiz.isSaved = true;
          });
          print('✅ Multiple choice answer submitted: $opsiIds');
        } else {
          // No selection - delete existing answer
          await _ujianService.submitJawaban(
            pesertaUjianId: widget.ujian.pesertaUjianId,
            soalId: quiz.soalId,
            opsiJawabanIds: [],
          );
          setState(() {
            quiz.isSaved = false;
          });
          print('🗑️ Multiple choice answer deleted for soal ${quiz.soalId}');
        }
      }
    } catch (e) {
      print('❌ Error submitting answer: $e');
      // Don't show error to user, just log it
    }
  }

  void _onAnswerSelected(int? selectedIndex, {List<int>? selectedIndices}) {
    final qList = widget.ujian.quizList;
    
    // Validasi index
    if (qList.isEmpty || currentQuestion < 0 || currentQuestion >= qList.length) {
      print('❌ Cannot select answer: Invalid question index');
      return;
    }
    
    final quiz = qList[currentQuestion];
    
    print('🎯 _onAnswerSelected called:');
    print('   Soal ID: ${quiz.soalId}');
    print('   Type: ${quiz.quizType}');
    print('   Selected Index: $selectedIndex');
    print('   Selected Indices: $selectedIndices');
    
    setState(() {
      if (quiz.quizType == "PILIHAN_GANDA_SINGLE") {
        // Update even if null (for unselect)
        final oldValue = quiz.selectedAnswerIndex;
        quiz.selectedAnswerIndex = selectedIndex;
        print('   📝 Updated single choice: $oldValue → $selectedIndex');
      } else if (quiz.quizType == "PILIHAN_GANDA_MULTIPLE") {
        // Update even if null or empty (for unselect)
        final oldValue = quiz.selectedAnswerIndices;
        quiz.selectedAnswerIndices = selectedIndices;
        print('   📝 Updated multiple choice: $oldValue → $selectedIndices');
      }
    });
    
    // Auto-save after selection (including unselect)
    _submitAnswer();
  }

  void nextQuestion() {
    List<QuizModel> qList = widget.ujian.quizList;
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
      currentQuestion--;
      setState(() {
        loadCurrentQuestion();
      });
    }
  }

  void _showExitConfirmation() {
    List<QuizModel> qList = widget.ujian.quizList;
    int answeredCount = qList.where((q) => q.hasAnswer).length;
    int totalCount = qList.length;
    int unansweredCount = totalCount - answeredCount;
    
    if (unansweredCount == 0) {
      // All answered - show different message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsApp.secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 50, color: Colors.blue),
                  SizedBox(height: 10),
                  Text(
                    "Keluar Ujian?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Semua soal telah dijawab.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Apakah anda ingin:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Finish Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _showFinishConfirmation();
                      },
                      child: Text(
                        "Selesaikan Ujian",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Exit without finish button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close first dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => EndQuizDialog(
                            onYesPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Exit quiz
                            },
                            onNoPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      child: Text(
                        "Keluar Tanpa Menyelesaikan",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Batal",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnansweredWarningDialog(
          unansweredCount: unansweredCount,
          onContinue: () async{
            String blockKey = "blockKey ${widget.ujian.ujianId.toString()}";
            SharedPreferences myPref = await SharedPreferences.getInstance();
            myPref.setBool(blockKey, true);
            Navigator.pop(context); 
            Navigator.pop(context);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _showFinishConfirmation() {
    List<QuizModel> qList = widget.ujian.quizList;
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
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      final result = await _ujianService.finishUjian(widget.ujian.pesertaUjianId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Exit quiz page
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ujian berhasil diselesaikan!'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('✅ Ujian finished with result: $result');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Gagal menyelesaikan ujian: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> navigatePicker(
    BuildContext context,
    List<QuizModel> qList,
    int curItem,
  ) async {
    int? res;
    res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPicker(
          quizList: qList, 
          currItem: curItem,
          ujian: widget.ujian,
          onFinishQuiz: () async {
            // Close picker
            Navigator.pop(context);
            // Finish quiz
            await _finishQuiz();
          },
          onExitQuiz: () {
            // Close picker
            Navigator.pop(context);
            // Exit quiz page without finishing
            Navigator.pop(context);
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
    if (widget.ujian.quizList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('Tidak ada soal tersedia'),
        ),
      );
    }
    
    // Ensure currentQuestion is valid
    if (currentQuestion >= widget.ujian.quizList.length) {
      currentQuestion = widget.ujian.quizList.length - 1;
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
                        "Soal ${currentQuestion + 1}",
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
                        width: 80,
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
                            widget.ujian.quizList,
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
                    widget.ujian.quizList[currentQuestion].quizType == "ESSAY" 
                      ? QuizEssayPage(
                          question: ques, 
                          controller: essayController,
                          onChanged: () {
                            // Auto-save essay after debounce
                            _submitAnswer();
                          },
                        ) 
                      : QuizPilganPage(
                          key: ValueKey('soal_${widget.ujian.quizList[currentQuestion].soalId}_$currentQuestion'),
                          question: ques, 
                          answerList: answer,
                          initialSelectedIndex: widget.ujian.quizList[currentQuestion].selectedAnswerIndex,
                          initialSelectedIndices: widget.ujian.quizList[currentQuestion].selectedAnswerIndices,
                          isMultipleChoice: widget.ujian.quizList[currentQuestion].quizType == "PILIHAN_GANDA_MULTIPLE",
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
                                  backgroundColor: currentQuestion + 1 >= widget.ujian.quizList.length 
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
                                        currentQuestion + 1 >= widget.ujian.quizList.length 
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
                                      currentQuestion + 1 >= widget.ujian.quizList.length 
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

