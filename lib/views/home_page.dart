import 'package:cbt_app/models/ujian_response_model.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_page.dart';
import 'package:cbt_app/controllers/home_controller.dart';
import 'package:cbt_app/widgets/start_dialog.dart';
import 'package:cbt_app/widgets/home_header.dart';
import 'package:cbt_app/widgets/exam_list_section.dart';
import 'package:cbt_app/widgets/loading_state.dart';
import 'package:cbt_app/widgets/error_state.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();
  late Future<UjianResponseModel> _futureUjians;

  @override
  void initState() {
    super.initState();
    _futureUjians = _controller.getUjianList();
  }

  void _refreshUjianList() {
    setState(() {
      _futureUjians = _controller.getUjianList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UjianResponseModel>(
      future: _futureUjians,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingState();
        }

        if (snapshot.hasError) {
          return ErrorState(
            error: '${snapshot.error}',
            onRetry: _refreshUjianList,
          );
        }

        final ujianData = snapshot.data!;
        final ujianList = ujianData.ujians;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: RefreshIndicator(
            color: Color(0xFF11B1E2),
            onRefresh: () async {
              setState(() {
                _futureUjians = _controller.getUjianList();
              });
              await _futureUjians;
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ExamListSection(
                      ujianList: ujianList,
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
    PesertaUjian pesertaUjian,
    String namaUjian,
    DateTime tanggalMulai,
    int durasiMenit,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StartDialog(
          okText: "Mulai Ujian",
          subject: namaUjian,
          examDate: tanggalMulai,
          btnPressed: () =>
              _startUjianWithAPI(pesertaUjian, namaUjian, tanggalMulai),
        );
      },
    );
  }

  Future<void> _startUjianWithAPI(
    PesertaUjian pesertaUjian,
    String namaUjian,
    DateTime tanggalMulai,
  ) async {
    Navigator.pop(context); // Close dialog
    showLoadingDialog(context, message: 'Memuat soal ujian...');

    try {
      final ujianModel = await _controller.startUjian(
        pesertaUjian,
        namaUjian,
        tanggalMulai,
      );

      final blockStatus = await _controller.checkBlockStatus(
        pesertaUjian.ujian.ujianId,
      );

      if (!context.mounted) return;

      Navigator.pop(context); // Close loading

      if (blockStatus) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizBlockedPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizPage(ujian: ujianModel)),
        ).then((_) => _refreshUjianList());
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      showErrorDialog(context, e.toString());
    }
  }
}
