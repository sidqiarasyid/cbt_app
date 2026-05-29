import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/exam_model.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/services/exam_service.dart';
import 'package:cbt_app/services/offline_exam_storage.dart';
import 'package:cbt_app/services/offline_sync_service.dart';

/// State container for a single active exam session.
///
/// Owns the countdown timer, anti-cheat lifecycle reaction, answer submission
/// (online + offline fallback), and finish flow. UI widgets read/listen to
/// this; lifecycle events are forwarded in by an `AntiCheatObserver` widget.
class ExamSessionProvider extends ChangeNotifier {
  ExamSessionProvider({
    ExamService? examService,
    OfflineSyncService? syncService,
  })  : _examService = examService ?? ExamService(),
        _syncService = syncService ?? OfflineSyncService();

  final ExamService _examService;
  final OfflineSyncService _syncService;

  ExamModel? _exam;
  ExamModel get exam => _exam!;
  bool get hasExam => _exam != null;

  int _currentQuestion = 0;
  int get currentQuestion => _currentQuestion;

  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;

  int _initialDurationSeconds = 0;
  int get initialDurationSeconds => _initialDurationSeconds;

  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  /// Set when timer hits zero AND auto-finish failed; UI shows recovery dialog.
  bool _autoFinishFailed = false;
  bool get autoFinishFailed => _autoFinishFailed;

  /// Set when finish succeeded; UI navigates to QuizEndPage.
  bool _finishedSuccessfully = false;
  bool get finishedSuccessfully => _finishedSuccessfully;

  /// Set when block is triggered; UI navigates to QuizBlockedPage.
  String? _pendingBlockViolationType;
  String? get pendingBlockViolationType => _pendingBlockViolationType;

  Timer? _countdownTimer;
  Timer? _inactiveTimer;
  Timer? _connectivityTimer;

  void start(ExamModel exam) {
    _exam = exam;
    _initializeTimer();
    _startConnectivityCheck();
  }

  // ───── Timer ──────────────────────────────────────────────────────────────

  void _initializeTimer() {
    final int? remainingSec = _exam!.remainingSeconds;
    final DateTime? endTime = _exam!.endDate;

    Duration remaining;
    if (remainingSec != null && remainingSec > 0) {
      remaining = Duration(seconds: remainingSec);
    } else if (endTime != null) {
      remaining = endTime.difference(DateTime.now());
    } else {
      remaining = const Duration(minutes: 60);
    }

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      _remaining = Duration.zero;
      _initialDurationSeconds = 0;
      notifyListeners();
      triggerAutoFinish();
    } else {
      _remaining = remaining;
      _initialDurationSeconds = remaining.inSeconds;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        triggerAutoFinish();
        return;
      }
      _remaining = _remaining - const Duration(seconds: 1);
      notifyListeners();
    });
  }

  String formatRemaining() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = _remaining.inHours;
    final minutes = twoDigits(_remaining.inMinutes.remainder(60));
    final seconds = twoDigits(_remaining.inSeconds.remainder(60));
    if (hours > 0) return '${twoDigits(hours)}:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  double get timerProgress {
    if (_initialDurationSeconds == 0) return 0;
    return (_remaining.inSeconds / _initialDurationSeconds).clamp(0.0, 1.0);
  }

  // ───── Connectivity ───────────────────────────────────────────────────────

  void _startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final wasOffline = _isOffline;
      bool online;
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      } catch (_) {
        online = false;
      }
      if (online == !_isOffline) return;
      _isOffline = !online;
      notifyListeners();
      if (wasOffline && online) {
        unawaited(_syncService.syncAnswersForExam(_exam!.examParticipantId));
      }
    });
  }

  // ───── Anti-cheat (called by AntiCheatObserver) ───────────────────────────

  /// Called when the app is backgrounded. Blocks immediately.
  void onAppBackgrounded() {
    if (_isBlocked) {
      _pendingBlockViolationType ??= 'APP_BACKGROUNDED_AGAIN';
      notifyListeners();
      return;
    }
    _inactiveTimer?.cancel();
    blockExam('APP_BACKGROUNDED');
  }

  /// Called when overlay/inactive state detected. Debounces 300ms to filter
  /// transient transitions; normal background goes inactive→paused fast.
  void onAppInactive() {
    if (_isBlocked) return;
    _inactiveTimer?.cancel();
    _inactiveTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isBlocked) blockExam('OVERLAY_DETECTED');
    });
  }

  void onAppResumed() {
    _inactiveTimer?.cancel();
    if (_isBlocked) {
      _pendingBlockViolationType ??= 'APP_BACKGROUNDED';
      notifyListeners();
    }
  }

  Future<void> blockExam(String violationType) async {
    if (_isBlocked) return;
    _isBlocked = true;
    _countdownTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blockKey ${_exam!.examId}', true);

    unawaited(_examService.reportViolation(
      examParticipantId: _exam!.examParticipantId,
      violationType: violationType,
    ));

    _pendingBlockViolationType = violationType;
    notifyListeners();
  }

  void consumeBlockNavigation() {
    _pendingBlockViolationType = null;
  }

  // ───── Answer flow ────────────────────────────────────────────────────────

  void selectAnswer(int? selectedIndex, {List<int>? selectedIndices}) {
    final qList = _exam!.quizList;
    if (qList.isEmpty || _currentQuestion < 0 || _currentQuestion >= qList.length) {
      return;
    }
    final quiz = qList[_currentQuestion];
    if (quiz.quizType == 'SINGLE_CHOICE') {
      quiz.selectedAnswerIndex = selectedIndex;
    } else if (quiz.quizType == 'MULTIPLE_CHOICE') {
      quiz.selectedAnswerIndices = selectedIndices;
    }
    notifyListeners();
    unawaited(submitCurrentAnswer());
  }

  Future<void> submitCurrentAnswer() async {
    final qList = _exam!.quizList;
    if (qList.isEmpty || _currentQuestion < 0 || _currentQuestion >= qList.length) {
      return;
    }
    final quiz = qList[_currentQuestion];
    try {
      if (quiz.quizType == 'ESSAY') {
        await _submitEssay(quiz);
      } else if (quiz.quizType == 'SINGLE_CHOICE') {
        await _submitSingleChoice(quiz);
      } else if (quiz.quizType == 'MULTIPLE_CHOICE') {
        await _submitMultipleChoice(quiz);
      }
      await OfflineExamStorage.cacheExamData(_exam!);
    } catch (e) {
      debugPrint('[ExamSession] submit failed: $e');
    }
  }

  Future<void> _submitEssay(QuizModel quiz) async {
    final text = (quiz.answerEssay?.trim().isEmpty ?? true) ? null : quiz.answerEssay?.trim();
    await OfflineExamStorage.savePendingAnswer(
      examParticipantId: _exam!.examParticipantId,
      questionId: quiz.questionId,
      answerText: text,
      quizType: quiz.quizType,
    );
    quiz.isSaved = text != null;
    notifyListeners();
    try {
      await _examService.submitAnswer(
        examParticipantId: _exam!.examParticipantId,
        questionId: quiz.questionId,
        answerText: text,
      );
      await OfflineExamStorage.removePendingAnswer(
        _exam!.examParticipantId,
        quiz.questionId,
      );
      _setOnlineIfWasOffline();
    } catch (e) {
      _handleSubmitError(e);
    }
  }

  Future<void> _submitSingleChoice(QuizModel quiz) async {
    int? optionId;
    if (quiz.selectedAnswerIndex != null && quiz.answerOptions != null) {
      optionId = quiz.answerOptions![quiz.selectedAnswerIndex!].optionId;
    }
    await OfflineExamStorage.savePendingAnswer(
      examParticipantId: _exam!.examParticipantId,
      questionId: quiz.questionId,
      answerOptionId: optionId,
      quizType: quiz.quizType,
    );
    quiz.isSaved = optionId != null;
    notifyListeners();
    try {
      await _examService.submitAnswer(
        examParticipantId: _exam!.examParticipantId,
        questionId: quiz.questionId,
        answerOptionId: optionId,
      );
      await OfflineExamStorage.removePendingAnswer(
        _exam!.examParticipantId,
        quiz.questionId,
      );
      _setOnlineIfWasOffline();
    } catch (e) {
      _handleSubmitError(e);
    }
  }

  Future<void> _submitMultipleChoice(QuizModel quiz) async {
    List<int>? optionIds;
    if (quiz.selectedAnswerIndices != null &&
        quiz.selectedAnswerIndices!.isNotEmpty &&
        quiz.answerOptions != null) {
      optionIds = quiz.selectedAnswerIndices!
          .map((i) => quiz.answerOptions![i].optionId)
          .toList();
    }
    await OfflineExamStorage.savePendingAnswer(
      examParticipantId: _exam!.examParticipantId,
      questionId: quiz.questionId,
      answerOptionIds: optionIds ?? const [],
      quizType: quiz.quizType,
    );
    quiz.isSaved = optionIds != null && optionIds.isNotEmpty;
    notifyListeners();
    try {
      await _examService.submitAnswer(
        examParticipantId: _exam!.examParticipantId,
        questionId: quiz.questionId,
        answerOptionIds: optionIds ?? const [],
      );
      await OfflineExamStorage.removePendingAnswer(
        _exam!.examParticipantId,
        quiz.questionId,
      );
      _setOnlineIfWasOffline();
    } catch (e) {
      _handleSubmitError(e);
    }
  }

  void _setOnlineIfWasOffline() {
    if (_isOffline) {
      _isOffline = false;
      notifyListeners();
    }
  }

  /// True when the failure was network-related (caller may flash an offline snackbar).
  bool _handleSubmitError(dynamic e) {
    final s = e.toString();
    final isNetwork = e is SocketException ||
        s.contains('Tidak dapat terhubung') ||
        s.contains('timeout') ||
        s.contains('SocketException');
    if (isNetwork && !_isOffline) {
      _isOffline = true;
      notifyListeners();
      return true;
    }
    if (!isNetwork) debugPrint('[ExamSession] non-network submit error: $e');
    return isNetwork;
  }

  // ───── Navigation ─────────────────────────────────────────────────────────

  void goToQuestion(int index) {
    final qList = _exam!.quizList;
    if (qList.isEmpty || index < 0 || index >= qList.length) return;
    _currentQuestion = index;
    notifyListeners();
  }

  void nextQuestion() {
    final qList = _exam!.quizList;
    if (qList[_currentQuestion].quizType == 'ESSAY') {
      unawaited(submitCurrentAnswer());
    }
    qList[_currentQuestion].isFinished = true;
    if (_currentQuestion + 1 < qList.length) {
      _currentQuestion++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestion <= 0) return;
    final qList = _exam!.quizList;
    if (qList[_currentQuestion].quizType == 'ESSAY') {
      unawaited(submitCurrentAnswer());
    }
    _currentQuestion--;
    notifyListeners();
  }

  // ───── Finish ─────────────────────────────────────────────────────────────

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Finish quiz. Returns:
  /// - `FinishResult.success` — finished, navigate to QuizEndPage.
  /// - `FinishResult.noInternet` — caller should show "no internet" dialog.
  /// - `FinishResult.networkError` — connection lost mid-finish.
  /// - `FinishResult.otherError(message)` — anything else.
  Future<FinishResult> finishQuiz() async {
    if (!await hasInternet()) return const FinishResult.noInternet();
    try {
      await _syncService.syncAnswersForExam(_exam!.examParticipantId);
      await _examService.finishExam(_exam!.examParticipantId);
      await OfflineExamStorage.clearPendingAnswers(_exam!.examParticipantId);
      await OfflineExamStorage.removePendingFinish(_exam!.examParticipantId);
      await OfflineExamStorage.clearCachedExamData(_exam!.examId);
      await OfflineExamStorage.removeDownloadedMark(_exam!.examId);
      _finishedSuccessfully = true;
      notifyListeners();
      return const FinishResult.success();
    } catch (e) {
      final s = e.toString();
      final isNetwork = e is SocketException ||
          s.contains('Tidak dapat terhubung') ||
          s.contains('timeout') ||
          s.contains('SocketException');
      if (isNetwork) return const FinishResult.networkError();
      return FinishResult.otherError(_sanitize(s));
    }
  }

  String _sanitize(String error) {
    final cleaned = error.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (cleaned.contains('SocketException') || cleaned.contains('HttpException')) {
      return 'Tidak dapat terhubung ke server.';
    }
    return cleaned;
  }

  /// Triggered by timer expiry. Manages its own retry loop; UI just reads
  /// [autoFinishFailed] to know whether to show the "no internet" recovery
  /// dialog. Resets the flag if user retries successfully.
  Future<void> triggerAutoFinish({int retryCount = 0}) async {
    const maxRetries = 5;

    if (!await hasInternet()) {
      if (retryCount < maxRetries) {
        await Future<void>.delayed(Duration(seconds: 3 * (retryCount + 1)));
        return triggerAutoFinish(retryCount: retryCount + 1);
      }
      _autoFinishFailed = true;
      notifyListeners();
      return;
    }

    try {
      await _syncService.syncAnswersForExam(_exam!.examParticipantId);
      await _examService.finishExam(_exam!.examParticipantId);
      await OfflineExamStorage.clearPendingAnswers(_exam!.examParticipantId);
      await OfflineExamStorage.removePendingFinish(_exam!.examParticipantId);
      await OfflineExamStorage.clearCachedExamData(_exam!.examId);
      await OfflineExamStorage.removeDownloadedMark(_exam!.examId);
      _autoFinishFailed = false;
      _finishedSuccessfully = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AutoFinish] failed (attempt ${retryCount + 1}): $e');
      if (retryCount < maxRetries) {
        await Future<void>.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return triggerAutoFinish(retryCount: retryCount + 1);
      }
      _autoFinishFailed = true;
      notifyListeners();
    }
  }

  /// Triggered by user exiting an unfinished quiz (the "exit anyway" path).
  /// Persists block, reports violation, returns the violation type that the
  /// UI should redirect to QuizBlockedPage with.
  Future<String> markExitedAndBlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blockKey ${_exam!.examId}', true);
    unawaited(_examService.reportViolation(
      examParticipantId: _exam!.examParticipantId,
      violationType: 'EXAM_EXITED',
    ));
    return 'EXAM_EXITED';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _inactiveTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }
}

class FinishResult {
  final FinishResultKind kind;
  final String? message;
  const FinishResult._(this.kind, [this.message]);
  const FinishResult.success() : this._(FinishResultKind.success);
  const FinishResult.noInternet() : this._(FinishResultKind.noInternet);
  const FinishResult.networkError() : this._(FinishResultKind.networkError);
  const FinishResult.otherError(String msg) : this._(FinishResultKind.otherError, msg);
}

enum FinishResultKind { success, noInternet, networkError, otherError }
