import 'package:your_cooked/models/question.dart';

import 'history.dart';

class QuestionPreview {
  final String questionId;
  final String questionText;

  QuestionPreview({required this.questionId, required this.questionText});

  factory QuestionPreview.fromQuestion(Question question) {
    return QuestionPreview(
      questionId: question.docId!,
      questionText: question.questionText,
    );
  }

  factory QuestionPreview.fromHistory(History history) {
    return QuestionPreview(
      questionId: history.questionId,
      questionText: history.questionText,
    );
  }

  factory QuestionPreview.fromFirestore(dynamic data) {
    final map = data as Map<String, dynamic>;
    return QuestionPreview(
      questionId: map['questionId'],
      questionText: map['questionText'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'questionId': questionId, 'questionText': questionText};
  }
}
