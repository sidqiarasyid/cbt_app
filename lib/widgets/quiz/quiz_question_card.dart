import 'package:flutter/material.dart';
import 'package:cbt_app/models/quiz_model.dart';
import 'package:cbt_app/views/quiz_essay_page.dart';
import 'package:cbt_app/views/quiz_multiple_choice_page.dart';

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.quiz,
    required this.currentQuestion,
    required this.essayController,
    required this.onEssayChanged,
    required this.onAnswerSelected,
  });

  final QuizModel quiz;
  final int currentQuestion;
  final TextEditingController essayController;
  final VoidCallback onEssayChanged;
  final void Function(int? selectedIndex, {List<int>? selectedIndices})
      onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    final typeMeta = _typeMeta(quiz.quizType);
    final question = quiz.question;
    final options =
        quiz.answerOptions?.map((option) => option.optionText).toList() ??
            const <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeMeta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeMeta.icon, size: 12, color: typeMeta.color),
                    const SizedBox(width: 5),
                    Text(
                      typeMeta.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeMeta.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (quiz.hasAnswer)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF22C55E)),
                      const SizedBox(width: 4),
                      Text(
                        quiz.isSaved ? 'Tersimpan' : 'Menyimpan…',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          quiz.quizType == 'ESSAY'
              ? QuizEssayPage(
                  key: ValueKey('essay_${quiz.questionId}_$currentQuestion'),
                  question: question,
                  controller: essayController,
                  questionImage: quiz.image,
                  onChanged: onEssayChanged,
                )
              : QuizPilganPage(
                  key: ValueKey('soal_${quiz.questionId}_$currentQuestion'),
                  question: question,
                  answerList: options,
                  questionImage: quiz.image,
                  initialSelectedIndex: quiz.selectedAnswerIndex,
                  initialSelectedIndices: quiz.selectedAnswerIndices,
                  isMultipleChoice: quiz.quizType == 'MULTIPLE_CHOICE',
                  onAnswerSelected: (selectedIndex, {selectedIndices}) {
                    onAnswerSelected(selectedIndex,
                        selectedIndices: selectedIndices);
                  },
                ),
        ],
      ),
    );
  }

  _QuestionTypeMeta _typeMeta(String type) {
    switch (type) {
      case 'ESSAY':
        return const _QuestionTypeMeta(
          label: 'Esai',
          icon: Icons.edit_note_rounded,
          color: Color(0xFFA855F7),
        );
      case 'MULTIPLE_CHOICE':
        return const _QuestionTypeMeta(
          label: 'Pilihan Ganda Kompleks',
          icon: Icons.checklist_rounded,
          color: Color(0xFF0EA5E9),
        );
      case 'SINGLE_CHOICE':
      default:
        return const _QuestionTypeMeta(
          label: 'Pilihan Ganda',
          icon: Icons.radio_button_checked_rounded,
          color: Color(0xFF11B1E2),
        );
    }
  }
}

class _QuestionTypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _QuestionTypeMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}
