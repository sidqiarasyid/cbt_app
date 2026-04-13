import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_page.dart';
import 'package:cbt_app/controllers/exam_controller.dart';
import 'package:cbt_app/widgets/start_dialog.dart';
import 'package:cbt_app/widgets/home_header.dart';
import 'package:cbt_app/widgets/exam_list_section.dart';
import 'package:cbt_app/widgets/loading_state.dart';
import 'package:cbt_app/widgets/error_state.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/page_transitions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UjianController _controller = UjianController();
  late Future<ExamResponseModel> _futureExams;

  @override
  void initState() {
    super.initState();
    _futureExams = _controller.getExamList();
  }

  void _refreshUjianList() {
    setState(() {
      _futureExams = _controller.getExamList();
    });
  }

  String _sanitizeError(String error) {
    // Strip "Exception: " prefix and hide technical details
    final cleaned = error.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (cleaned.contains('SocketException') || cleaned.contains('HttpException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExamResponseModel>(
      future: _futureExams,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingState();
        }

        if (snapshot.hasError) {
          return ErrorState(
            error: _sanitizeError('${snapshot.error}'),
            onRetry: _refreshUjianList,
          );
        }

        final examData = snapshot.data!;
        final examList = examData.exams;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: RefreshIndicator(
            color: Color(0xFF11B1E2),
            onRefresh: () async {
              setState(() {
                _futureExams = _controller.getExamList();
              });
              await _futureExams;
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ExamListSection(
                      examList: examList,
                      formatDate: DateFormatter.formatDateFromString,
                      onStartExam: _handleStartExam,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleStartExam(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
    int durationMinutes,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StartDialog(
          okText: "Mulai Ujian",
          subject: examName,
          examDate: startDate,
          btnPressed: () =>
              _startUjianWithAPI(examParticipant, examName, startDate),
        );
      },
    );
  }

  Future<void> _startUjianWithAPI(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
  ) async {
    Navigator.pop(context); // Close dialog
    showLoadingDialog(context, message: 'Memuat soal ujian...');

    try {
      final examModel = await _controller.startExam(
        examParticipant,
        examName,
        startDate,
      );

      final blockStatus = await _controller.checkBlockStatus(
        examParticipant.exam.examId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading

      // Check both local block (SharedPreferences) and server block
      if (blockStatus || examParticipant.isBlocked) {
        // Sync local block status if server says blocked
        if (examParticipant.isBlocked && !blockStatus) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("blockKey ${examParticipant.exam.examId}", true);
        }
        if (!mounted) return;
        Navigator.push(
          context,
          fadeSlideRoute(QuizBlockedPage(examName: examName)),
        );
      } else {
        Navigator.push(
          context,
          fadeSlideRoute(QuizPage(exam: examModel)),
        ).then((_) => _refreshUjianList());
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      showErrorDialog(context, e.toString());
    }
  }
}
