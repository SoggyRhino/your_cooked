import 'dart:math';

import 'package:flutter/material.dart';

class QuestionAnswerCard extends StatefulWidget {
  final String questionText;
  final String answerText;

  const QuestionAnswerCard({
    super.key,
    required this.questionText,
    required this.answerText,
  });

  @override
  State<StatefulWidget> createState() => _QuestionAnswerCardState();
}

class _QuestionAnswerCardState extends State<QuestionAnswerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFrontVisible = true;
  Widget? _frontFace;
  Widget? _backFace;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isAnimating) return;

    setState(() {
      _isFrontVisible = !_isFrontVisible;
    });

    if (_isFrontVisible) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    _frontFace ??= _buildFace(
      isQuestion: true,
      title: 'Question',
      content: widget.questionText,
      buttonText: 'Show Answer',
    );
    _backFace ??= _buildFace(
      isQuestion: false,
      title: 'Answer',
      content: widget.answerText,
      buttonText: 'Show Question',
    );

    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * -pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          // Determine which face to show
          final showingFront = _controller.value < 0.5;
          final currentFace = showingFront
              ? _frontFace
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _backFace,
                );

          return AnimatedSize(
            duration: Duration(
              milliseconds:
                  (_controller.duration?.inMilliseconds ?? 600) ~/
                  2, // Half the flip duration
            ),
            curve: Curves.easeInOut,
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: currentFace,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFace({
    required bool isQuestion,
    required String title,
    required String content,
    required String buttonText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final iconColor = isQuestion ? colorScheme.primary : colorScheme.secondary;

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 200),
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  content,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
                // Footer Action
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonText,
                  style: textTheme.labelLarge?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.sync_alt, color: iconColor, size: 18),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
