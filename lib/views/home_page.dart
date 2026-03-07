import 'dart:io';
import 'package:cbt_app/models/exam_response_model.dart';
import 'package:cbt_app/views/quiz_blocked_page.dart';
import 'package:cbt_app/views/quiz_page.dart';
import 'package:cbt_app/controllers/exam_controller.dart';
import 'package:cbt_app/services/offline_exam_storage.dart';
import 'package:cbt_app/services/offline_sync_service.dart';
import 'package:cbt_app/widgets/start_dialog.dart';
import 'package:cbt_app/widgets/home_header.dart';
import 'package:cbt_app/widgets/exam_list_section.dart';
import 'package:cbt_app/widgets/loading_state.dart';
import 'package:cbt_app/widgets/error_state.dart';
import 'package:cbt_app/widgets/dialogs/loading_dialog.dart';
import 'package:cbt_app/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UjianController _controller = UjianController();
  final OfflineSyncService _syncService = OfflineSyncService();
  late Future<ExamResponseModel> _futureExams;
  bool _hasPendingSync = false;
  Set<int> _downloadedExamIds = {};
  Set<int> _downloadingExamIds = {};

  @override
  void initState() {
    super.initState();
    _futureExams = _controller.getExamList();
    _checkAndSyncOfflineData();
    _loadDownloadedExamIds();
  }

  /// Memuat daftar ID ujian yang sudah diunduh dari storage
  Future<void> _loadDownloadedExamIds() async {
    final ids = await OfflineExamStorage.getDownloadedExamIds();
    if (mounted) {
      setState(() => _downloadedExamIds = ids);
    }
  }

  /// Cek dan sinkronkan data offline saat halaman pertama kali dibuka
  Future<void> _checkAndSyncOfflineData() async {
    final hasPending = await _controller.hasPendingOfflineData();
    if (mounted) {
      setState(() => _hasPendingSync = hasPending);
    }
    
    if (hasPending) {
      final result = await _syncService.syncAllPending();
      if (mounted) {
        setState(() => _hasPendingSync = false);
        if (result.syncedAnswers > 0 || result.syncedFinish > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green[700],
              duration: Duration(seconds: 4),
            ),
          );
          _refreshUjianList();
        }
      }
    }
  }

  void _refreshUjianList() {
    setState(() {
      _futureExams = _controller.getExamList();
    });
    _loadDownloadedExamIds();
  }

  String _sanitizeError(String error) {
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
              await _loadDownloadedExamIds();
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(),
                  // Pending sync banner
                  if (_hasPendingSync)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange[700],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mensinkronkan data offline...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ExamListSection(
                      examList: examList,
                      formatDate: DateFormatter.formatDateFromString,
                      onStartExam: _handleStartExam,
                      onDownloadExam: _handleDownloadExam,
                      downloadedExamIds: _downloadedExamIds,
                      downloadingExamIds: _downloadingExamIds,
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

  // ==================== DOWNLOAD EXAM ====================

  void _handleDownloadExam(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
    int durationMinutes,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.download_rounded, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Expanded(child: Text('Unduh Ujian', style: TextStyle(fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                examName,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Timer ujian akan mulai berjalan setelah diunduh. Pastikan Anda siap mengerjakan.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _downloadExamWithAPI(examParticipant, examName, startDate);
              },
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text('Unduh Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadExamWithAPI(
    ExamParticipant examParticipant,
    String examName,
    DateTime startDate,
  ) async {
    final examId = examParticipant.exam.examId;

    // Set downloading state
    setState(() {
      _downloadingExamIds = {..._downloadingExamIds, examId};
    });

    try {
      await _controller.downloadExam(examParticipant, examName, startDate);

      if (!mounted) return;

      // Update state
      setState(() {
        _downloadingExamIds = {..._downloadingExamIds}..remove(examId);
        _downloadedExamIds = {..._downloadedExamIds, examId};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Ujian "$examName" berhasil diunduh! Siap dikerjakan offline.')),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _downloadingExamIds = {..._downloadingExamIds}..remove(examId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Gagal mengunduh: ${_sanitizeError(e.toString())}')),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // ==================== START EXAM ====================

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

    final examId = examParticipant.exam.examId;

    try {
      // Check block status first (works offline via SharedPreferences)
      final blockStatus = await _controller.checkBlockStatus(examId);

      if (blockStatus || examParticipant.isBlocked) {
        if (examParticipant.isBlocked && !blockStatus) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("blockKey $examId", true);
        }
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizBlockedPage(examName: examName),
          ),
        );
        return;
      }

      // Try to load from cache first (supports offline start)
      final isDownloaded = await OfflineExamStorage.isExamDownloaded(examId);

      if (isDownloaded) {
        // Load from cache — works offline
        final cachedExam = await _controller.startExamFromCache(examId);
        if (cachedExam != null) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizPage(exam: cachedExam)),
          ).then((_) => _refreshUjianList());
          return;
        }
      }

      // Not downloaded or cache missing — call API
      final examModel = await _controller.startExam(
        examParticipant,
        examName,
        startDate,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizPage(exam: examModel)),
      ).then((_) => _refreshUjianList());
    } on SocketException {
      // Offline and not downloaded — show error
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showOfflineError(examName);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Check if it's a network error — try cache fallback
      if (e.toString().contains('Tidak dapat terhubung') ||
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        final cachedExam = await _controller.startExamFromCache(examId);
        if (cachedExam != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizPage(exam: cachedExam)),
          ).then((_) => _refreshUjianList());
          return;
        }
        _showOfflineError(examName);
      } else {
        showErrorDialog(context, _sanitizeError(e.toString()));
      }
    }
  }

  void _showOfflineError(String examName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tidak ada koneksi. Unduh ujian "$examName" terlebih dahulu saat online.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 4),
      ),
    );
  }
}
