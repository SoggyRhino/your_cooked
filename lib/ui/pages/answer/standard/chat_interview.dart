import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/models/question.dart';

import '../../../../services/ai/ai_service.dart';
import '../../../../services/firestore/firestore_service.dart';
import 'chat_message.dart';

typedef FunctionCallHandler =
    void Function(String name, Map<String, dynamic> args);

class ChatInterview extends StatefulWidget {
  final String userId;
  final Question question;

  const ChatInterview({
    super.key,
    required this.question,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _ChatInterviewState();
}

class _ChatInterviewState extends State<ChatInterview> {
  late final GenerativeModel model;
  late final ChatSession session;
  late List<Widget> _messages;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _interviewActive = true;
  String? _answerId;

  @override
  void initState() {
    super.initState();
    model = AiService().getInterviewModel();
    session = model.startChat();
    _messages = [];
    _sendMessage(
      'Please start the interview. Ask me this question: "${widget.question.questionText}"',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(String message) {
    final stream = session.sendMessageStream(
      Content('user', [TextPart(message)]),
    );

    setState(() {
      _messages.add(ChatMessage.fromMessage(role: 'user', message: message));
      _messages.add(
        ChatMessage.fromResponse(
          role: 'model',
          response: stream,
          onFunction: _handleFunctionCall,
        ),
      );
    });

    // Auto-scroll to bottom when new message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFunctionCall(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (name == 'end_interview') {
      _submitAnswer();
    }
  }

  Future<void> _submitAnswer() async {
    final result = await FirestoreService().addAnswer(
      userId: widget.userId,
      questionId: widget.question.docId,
      history: session.history,
    );

    if (result.isSuccess()) {
      final answerId = result.getOrThrow();

      setState(() {
        _answerId = answerId;
      });
    } else {
      if (context.mounted) {
        final error = result.exceptionOrNull();
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }

    //todo end chat session ?
    setState(() {
      _interviewActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages
        .getRange(
          _messages.isNotEmpty ? 1 : 0,
          _interviewActive ? _messages.length : _messages.length - 1,
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (BuildContext context, int index) => messages[index],
          ),
        ),
        _interviewActive ? _buildTextInput() : _buildEndInterview(),
      ],
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                autocorrect: true,
                autofocus: true,
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _sendMessage(value.trim());
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                final value = _textController.text.trim();
                if (value.isNotEmpty) {
                  _sendMessage(value);
                  _textController.clear();
                }
              },
              icon: Icon(
                Icons.send_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndInterview() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 32,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Interview Completed!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Great job! Your responses have been recorded.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_answerId != null) {
                    context.pushReplacementNamed(
                      'view-grading-by-answer',
                      pathParameters: {'answerId': _answerId!},
                    );
                  } else {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Internal Error Occurred'),
                            ],
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    _submitAnswer();
                  }
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View Results'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
