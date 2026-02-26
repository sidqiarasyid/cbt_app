import 'package:cbt_app/models/exam_result_response_model.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/history_card.dart';
import 'package:cbt_app/widgets/loading_state.dart';
import 'package:cbt_app/widgets/error_state.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Set<int> _expandedCards = {};
  late Future<ExamResultListResponse> _futureHistory;
  final ExamService _examService = ExamService();

  @override
  void initState() {
    super.initState();
    _futureHistory = _examService.getStudentExamResults();
  }

  void _refreshHistory() {
    setState(() {
      _futureHistory = _examService.getStudentExamResults();
    });
  }

  String _sanitizeError(String error) {
    final cleaned = error.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (cleaned.contains('SocketException') ||
        cleaned.contains('HttpException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExamResultListResponse>(
      future: _futureHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Memuat riwayat ujian...');
        }

        if (snapshot.hasError) {
          return ErrorState(
            error: _sanitizeError('${snapshot.error}'),
            onRetry: _refreshHistory,
          );
        }

        final historyList = snapshot.data!.results;

        return Scaffold(
          backgroundColor: ColorsApp.backgroundColor,
          body: RefreshIndicator(
            color: ColorsApp.primaryColor,
            onRefresh: () async {
              _refreshHistory();
              await _futureHistory;
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: historyList.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(historyList),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11B1E2).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Ujian',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lihat hasil ujian yang telah dikerjakan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat ujian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat ujian yang sudah dikerjakan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<ResultEntry> historyList) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final item = historyList[index];
        final isExpanded = _expandedCards.contains(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HistoryCard(
            examName: item.examParticipant.exam.examName,
            subject: item.examParticipant.exam.subject,
            gradeLevel: item.examParticipant.exam.gradeLevel,
            major: item.examParticipant.exam.major,
            status: item.examParticipant.examStatus,
            finalScore: item.finalScore,
            submitDate: item.submitDate,
            startDate: item.examParticipant.exam.startDate,
            endDate: item.examParticipant.exam.endDate,
            isExpanded: isExpanded,
            onExpandToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(index);
                } else {
                  _expandedCards.add(index);
                }
              });
            },
          ),
        );
      },
    );
  }
}

