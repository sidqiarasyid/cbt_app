class ExamResultListResponse {
  final List<ResultEntry> results;

  ExamResultListResponse({required this.results});

  factory ExamResultListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List? ?? [])
        .map((e) => ResultEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return ExamResultListResponse(results: list);
  }
}

class ResultEntry {
  final int? examResultId;
  final int examParticipantId;
  final double? finalScore;
  final DateTime submitDate;
  final ExamParticipantResult examParticipant;

  ResultEntry({
    this.examResultId,
    required this.examParticipantId,
    this.finalScore,
    required this.submitDate,
    required this.examParticipant,
  });

  /// Whether this exam was never attempted by the student
  bool get isNotAttempted =>
      examParticipant.examStatus == 'NOT_ATTEMPTED';

  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      examResultId: json['exam_result_id'] as int?,
      examParticipantId: json['exam_participant_id'] as int? ?? 0,
      finalScore: (json['final_score'] as num?)?.toDouble(),
      submitDate: json['submit_date'] != null
          ? DateTime.parse(json['submit_date'] as String)
          : DateTime.now(),
      examParticipant: ExamParticipantResult.fromJson(
        (json['exam_participant'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class ExamParticipantResult {
  final int examParticipantId;
  final int studentId;
  final int examId;
  final String examStatus;
  final ExamShort exam;

  ExamParticipantResult({
    required this.examParticipantId,
    required this.studentId,
    required this.examId,
    required this.examStatus,
    required this.exam,
  });

  factory ExamParticipantResult.fromJson(Map<String, dynamic> json) {
    return ExamParticipantResult(
      examParticipantId: json['exam_participant_id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      examId: json['exam_id'] as int? ?? 0,
      examStatus: json['exam_status'] as String? ?? '',
      exam: ExamShort.fromJson(
        (json['exam'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class ExamShort {
  final int examId;
  final String examName;
  final String subject;
  final String gradeLevel;
  final String major;
  final DateTime startDate;
  final DateTime endDate;

  ExamShort({
    required this.examId,
    required this.examName,
    required this.subject,
    required this.gradeLevel,
    required this.major,
    required this.startDate,
    required this.endDate,
  });

  factory ExamShort.fromJson(Map<String, dynamic> json) {
    return ExamShort(
      examId: json['exam_id'] as int? ?? 0,
      examName: json['exam_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      gradeLevel: json['grade_level'] as String? ?? '',
      major: json['major'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : DateTime.now(),
    );
  }
}
