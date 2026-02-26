// Model for response from API /students/exams/start
class StartExamResponseModel {
  final ExamParticipantInfo examParticipant;
  final List<ExamQuestion> questionList;
  final int totalQuestions;
  final int remainingSeconds;

  StartExamResponseModel({
    required this.examParticipant,
    required this.questionList,
    required this.totalQuestions,
    this.remainingSeconds = 0,
  });

  factory StartExamResponseModel.fromJson(Map<String, dynamic> json) {
    // Backend returns a FLAT response:
    // { exam_participant_id, exam: {...}, remaining_seconds, total_questions, questions: [...], existing_answers: [...] }
    final examData = json['exam'] as Map<String, dynamic>? ?? {};

    // Build existing answers lookup by question_id
    final Map<int, Map<String, dynamic>> existingAnswersMap = {};
    if (json['existing_answers'] != null) {
      for (var answer in json['existing_answers'] as List) {
        final a = answer as Map<String, dynamic>;
        existingAnswersMap[a['question_id'] as int] = a;
      }
    }

    // Parse questions, injecting existing answers as 'my_answer'
    final List<ExamQuestion> questionList = [];
    if (json['questions'] != null) {
      for (var item in json['questions'] as List) {
        final q = Map<String, dynamic>.from(item as Map);
        final questionData = q['question'] as Map<String, dynamic>?;
        final questionId = questionData?['question_id'] as int?;

        if (questionId != null && existingAnswersMap.containsKey(questionId)) {
          q['my_answer'] = _convertExistingAnswer(existingAnswersMap[questionId]!);
        }

        questionList.add(ExamQuestion.fromJson(q));
      }
    }

    return StartExamResponseModel(
      examParticipant: ExamParticipantInfo(
        examParticipantId: json['exam_participant_id'] as int? ?? 0,
        examStatus: 'IN_PROGRESS',
        startTime: null,
        durationMinutes: examData['duration_minutes'] as int? ?? 0,
      ),
      questionList: questionList,
      totalQuestions: json['total_questions'] as int? ?? questionList.length,
      remainingSeconds: json['remaining_seconds'] as int? ?? 0,
    );
  }

  /// Convert backend existing_answer format (mc_option_ids as comma string)
  /// to the MyAnswer-compatible format.
  static Map<String, dynamic> _convertExistingAnswer(Map<String, dynamic> answer) {
    final mcOptionIdsStr = answer['mc_option_ids'] as String?;
    int? answerOptionId;
    List<int>? answerOptionIds;

    if (mcOptionIdsStr != null && mcOptionIdsStr.isNotEmpty) {
      final ids = mcOptionIdsStr
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      if (ids.isNotEmpty) {
        answerOptionId = ids.first;
        answerOptionIds = ids;
      }
    }

    return {
      'answer_id': 0,
      'answer_option_id': answerOptionId,
      'answer_option_ids': answerOptionIds,
      'answer_text': answer['essay_answer_text'],
    };
  }
}

class ExamParticipantInfo {
  final int examParticipantId;
  final String examStatus;
  final DateTime? startTime;
  final int durationMinutes;

  ExamParticipantInfo({
    required this.examParticipantId,
    required this.examStatus,
    this.startTime,
    required this.durationMinutes,
  });

  factory ExamParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ExamParticipantInfo(
      examParticipantId: json['exam_participant_id'] as int? ?? 0,
      examStatus: json['exam_status'] as String? ?? '',
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }
}

class ExamQuestion {
  final int examQuestionId;
  final int sequence;
  final int scoreWeight;
  final Question question;
  final MyAnswer? myAnswer;

  ExamQuestion({
    required this.examQuestionId,
    required this.sequence,
    required this.scoreWeight,
    required this.question,
    this.myAnswer,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      examQuestionId: json['exam_question_id'] as int? ?? 0,
      sequence: json['sequence'] as int? ?? 0,
      scoreWeight: json['score_weight'] as int? ?? 0,
      question: Question.fromJson((json['question'] as Map<String, dynamic>?) ?? {}),
      myAnswer: json['my_answer'] != null
          ? MyAnswer.fromJson(json['my_answer'])
          : null,
    );
  }
}

class Question {
  final int questionId;
  final String questionType; // SINGLE_CHOICE, MULTIPLE_CHOICE, ESSAY
  final String questionText;
  final String? questionImage;
  final List<AnswerOption> answerOptions;

  Question({
    required this.questionId,
    required this.questionType,
    required this.questionText,
    this.questionImage,
    required this.answerOptions,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id'] as int? ?? 0,
      questionType: json['question_type'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionImage: json['question_image'],
      answerOptions: json['answer_options'] != null
          ? (json['answer_options'] as List)
              .map((item) => AnswerOption.fromJson(item))
              .toList()
          : [],
    );
  }
}

class AnswerOption {
  final int optionId;
  final String label;
  final String optionText;

  AnswerOption({
    required this.optionId,
    required this.label,
    required this.optionText,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      optionId: json['option_id'],
      label: json['option_label'] ?? json['label'] ?? '',
      optionText: json['option_text'] ?? '',
    );
  }
}

class MyAnswer {
  final int answerId;
  final int? answerOptionId;
  final List<int>? answerOptionIds; // for MULTIPLE_CHOICE
  final String? answerText;

  MyAnswer({
    required this.answerId,
    this.answerOptionId,
    this.answerOptionIds,
    this.answerText,
  });

  factory MyAnswer.fromJson(Map<String, dynamic> json) {
    return MyAnswer(
      answerId: json['answer_id'] as int? ?? 0,
      answerOptionId: json['answer_option_id'],
      answerOptionIds: json['answer_option_ids'] != null
          ? List<int>.from(json['answer_option_ids'])
          : null,
      answerText: json['answer_text'],
    );
  }
}
