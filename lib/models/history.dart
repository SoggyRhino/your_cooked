import 'package:cloud_firestore/cloud_firestore.dart';

class History {
  final String id;
  final DateTime timeStamp;

  History({required this.id, required this.timeStamp});

  factory History.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('History data cannot be null');
    }
    return History(
      id: data['questionId'],
      timeStamp: data['timeStamp'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'questionId': id, 'timeStamp': timeStamp};
  }
}
