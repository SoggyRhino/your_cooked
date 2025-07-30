import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import 'chat_interview.dart';

class ChatMessage extends StatefulWidget {
  final String role;
  final Stream<GenerateContentResponse>? response;
  final String? message;
  final FunctionCallHandler? onFunction;

  /// Constructor for a static message
  const ChatMessage.fromMessage({
    super.key,
    required this.role,
    required this.message,
    this.onFunction,
  }) : response = null;

  /// Constructor for a streaming response
  const ChatMessage.fromResponse({
    super.key,
    required this.role,
    required this.response,
    required this.onFunction,
  }) : message = null;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  final _buffer = StringBuffer();
  StreamSubscription<GenerateContentResponse>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.response != null) {
      _subscription = widget.response!.listen(_handleResponse);
    }
  }

  void _handleResponse(GenerateContentResponse response) {
    for (final candidate in response.candidates) {
      final content = candidate.content;

      if (content.parts.isNotEmpty) {
        for (final part in content.parts) {
          // Check if this part is a function call
          if (part is FunctionCall) {
            if (widget.onFunction != null) {
              final name = part.name;
              final args = part.args;

              widget.onFunction!(name, args);
            }
          } else if (part is TextPart) {
            setState(() {
              _buffer.write(response.text ?? '');
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message ?? _buffer.toString();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: widget.role == 'user'
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.role == 'user' ? 'You:' : 'AI:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text.isEmpty ? '...' : text,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
