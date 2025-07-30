import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

class Grading {
  final String? gradingId;
  final String userId;
  final String answerId;
  final String questionId;
  final List<Category> categories;
  final DateTime createdAt;

  Grading({
    this.gradingId,
    required this.userId,
    required this.answerId,
    required this.questionId,
    required this.categories,
    required this.createdAt,
  });

  factory Grading.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    if (data == null) {
      throw Exception('Firestore Result data cannot be null');
    }
    final categories = (data['categories'] as List<dynamic>)
        .map((item) => Category.fromFirestore(item))
        .toList();

    return Grading(
      gradingId: snapshot.id,
      userId: data['userId'],
      answerId: data['answerId'],
      questionId: data['questionId'],
      categories: categories,
      createdAt: data['createdAt'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'answerId': answerId,
      'questionId': questionId,
      'categories': categories
          .map((category) => category.toFirestore())
          .toList(),
      'createdAt': createdAt,
    };
  }

  double get averageScore {
    double average = 0;
    for (final category in categories) {
      average += category.score;
    }
    return average / categories.length;
  }
}

class Category {
  final String category;
  final String feedback;
  final List<String> strengths;
  final List<String> weaknesses;
  final int score;

  Category({
    required this.category,
    required this.feedback,
    required this.strengths,
    required this.weaknesses,
    required this.score,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      category: json['category'],
      feedback: json['feedback'],
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
      score: json['score'],
    );
  }

  factory Category.fromFirestore(dynamic data) {
    final map = data as Map<String, dynamic>;
    return Category(
      category: map['category'],
      feedback: map['feedback'],
      strengths: List<String>.from(map['strengths']),
      weaknesses: List<String>.from(map['weaknesses']),
      score: map['score'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'feedback': feedback,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'score': score,
    };
  }

  static Schema get schema => Schema.object(
    properties: {
      'category': Schema.string(),
      'score': Schema.integer(),
      'strengths': Schema.array(items: Schema.string()),
      'weaknesses': Schema.array(items: Schema.string()),
      'feedback': Schema.string(),
    },
  );
}
