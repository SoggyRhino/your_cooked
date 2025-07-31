import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String userName;
  final DateTime joined;

  User({
    required this.userId,
    required this.userName,
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
      userId: snapshot.id,
      userName: data['userName'],
      joined: data['joined'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'joined': joined,
    };
  }
}