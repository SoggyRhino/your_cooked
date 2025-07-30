import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String? docId;
  final String questionText;
  final String answerText;
  final List<String> tags;
  final String visibility;
  final DateTime createdAt;
  final String userId;

  Question({
    this.docId,
    required this.questionText,
    required this.answerText,
    required this.tags,
    required this.visibility,
    required this.createdAt,
    required this.userId,
  });

  factory Question.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Firestore question data cannot be null');
    }
    return Question(
      docId: snapshot.id,
      questionText: data['questionText'],
      answerText: data['answerText'],
      tags: List<String>.from(data['tags']),
      visibility: data['visibility'],
      createdAt: data['createdAt'].toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "questionText": questionText,
      "answerText": answerText,
      "tags": tags,
      "visibility": visibility,
      "createdAt": createdAt,
      "userId": userId,
    };
  }
}
