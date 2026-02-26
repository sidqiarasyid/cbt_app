class ExamResponseModel {
  final List<ExamParticipant> exams;

  ExamResponseModel({required this.exams});

  factory ExamResponseModel.fromJson(Map<String, dynamic> json) {
    return ExamResponseModel(
      exams: (json['exams'] as List)
          .map((item) => ExamParticipant.fromJson(item))
          .toList(),
    );
  }
}

class ExamParticipant {
  final int examParticipantId;
  final String examStatus;
  final bool isBlocked;
  final String? unlockCode;
  final DateTime? startTime;
  final DateTime? endTime;
  final ExamDetail exam;
  final ExamResult? result;

  ExamParticipant({
    required this.examParticipantId,
    required this.examStatus,
    required this.isBlocked,
    this.unlockCode,
    this.startTime,
    this.endTime,
    required this.exam,
    this.result,
  });

  factory ExamParticipant.fromJson(Map<String, dynamic> json) {
    // Backend getMyExams returns a FLAT structure (no nested 'exam' object).
    // All exam fields are at the top level alongside participant fields.
    final examData = json['exam'] as Map<String, dynamic>?;

    return ExamParticipant(
      examParticipantId: json['exam_participant_id'] as int,
      examStatus: json['exam_status'] as String,
      isBlocked: json['is_blocked'] as bool? ?? false,
      unlockCode: json['unlock_code'] as String?,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'].toString()) 
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'].toString()) 
          : null,
      exam: examData != null
          ? ExamDetail.fromJson(examData)
          : ExamDetail.fromFlat(json),
      result: json['result'] != null 
          ? ExamResult.fromJson(json['result']) 
          : null,
    );
  }
}

class ExamDetail {
  final int examId;
  final String examName;
  final String subject;
  final String gradeLevel;
  final String? major;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes;
  final bool isShuffleQuestions;

  ExamDetail({
    required this.examId,
    required this.examName,
    required this.subject,
    required this.gradeLevel,
    this.major,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.isShuffleQuestions,
  });

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    return ExamDetail(
      examId: json['exam_id'],
      examName: json['exam_name'],
      subject: json['subject'],
      gradeLevel: json['grade_level'],
      major: json['major'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      durationMinutes: json['duration_minutes'],
      isShuffleQuestions: json['is_shuffle_questions'] ?? false,
    );
  }

  /// Parse from the flat getMyExams response where exam fields are at top level.
  factory ExamDetail.fromFlat(Map<String, dynamic> json) {
    return ExamDetail(
      examId: json['exam_id'] as int,
      examName: json['exam_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      gradeLevel: json['grade_level'] as String? ?? '',
      major: json['major'] as String?,
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      isShuffleQuestions: json['is_shuffle'] as bool? ?? json['is_shuffle_questions'] as bool? ?? false,
    );
  }
}

class ExamResult {
  final double finalScore;
  final DateTime submitDate;

  ExamResult({
    required this.finalScore,
    required this.submitDate,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
      submitDate: DateTime.parse(json['submit_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
