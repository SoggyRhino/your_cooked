import 'package:cloud_firestore/cloud_firestore.dart';

class History {
  final String questionId;
  final String questionText;
  final DateTime timeStamp;

  History(
      {required this.questionId, required this.questionText, required this.timeStamp});

  factory History.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('History data cannot be null');
    }
    return History(
      questionId: data['questionId'],
      questionText: data['questionText'],
      timeStamp: data['timeStamp'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,

      'questionText': questionText,
      'timeStamp': timeStamp,
    };
  }
}
