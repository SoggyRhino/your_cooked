import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? docId;
  final String userId;
  final String userName;
  final List<String> questions;
  final DateTime joined;

  User({
    this.docId,
    required this.userId,
    required this.userName,
    required this.questions,
    required this.joined,
  });

  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Firestore question data cannot be null');
    }
    return User(
      docId: snapshot.id,
      userId: data['userId'],
      userName: data['userName'],
      questions: List<String>.from(data['questions']),
      joined: data['joined'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'questions': questions,
      'joined': joined,
    };
  }
}
