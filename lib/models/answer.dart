import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

class Answer {
  final String? answerId;
  final String userId;
  final String questionId;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  Answer({
    required this.userId,
    required this.questionId,
    required this.messages,
    required this.createdAt,
    this.answerId,
  });

  factory Answer.fromHistory(
    String userId,
    String questionId,
    Iterable<Content> history,
  ) {
    return Answer(
      userId: userId,
      questionId: questionId,
      messages: history.map(ChatMessage.fromContent).toList(),
      createdAt: DateTime.now(),
    );
  }

  factory Answer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Firestore Answer data cannot be null');
    }

    final messageData = (data['messages'] as List<dynamic>)
        .map((item) => ChatMessage.fromFirestore(item))
        .toList();

    return Answer(
      answerId: snapshot.id,
      userId: data['userId'],
      questionId: data['questionId'],
      messages: messageData,
      createdAt: data['createdAt'].toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "userId": userId,
      "questionId": questionId,
      "messages": messages.map((message) => message.toFirestore()).toList(),
      "createdAt": createdAt,
    };
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.fromContent(Content content) {
    return ChatMessage(
      role: content.role ?? '',
      content: _extractContent(content),
    );
  }

  factory ChatMessage.fromFirestore(dynamic data) {
    final map = data as Map<String, dynamic>;
    return ChatMessage(role: map['role'], content: map['content']);
  }

  Map<String, dynamic> toFirestore() {
    return {"role": role, "content": content};
  }

  //todo update to support uploading attachments
  static String _extractContent(Content content) {
    StringBuffer buffer = StringBuffer();

    for (final part in content.parts) {
      switch (part) {
        case TextPart textPart:
          buffer.write(textPart.text);
          break;
        default:
          print('Unsupported Part Type $part');
          break;
      }
    }
    return buffer.toString();
  }

  Map<String, String> toJson() {
    return {'role': role, 'content': content};
  }
}
