import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _viewQuestion(context),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(125),
          ),
        ),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Container(
          height: 180,
          width: 180,
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.topLeft,
          child: Text(
            question.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 3, // Limit text to a few lines
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Future<void> _viewQuestion(BuildContext context) async {
    final result = await context.pushNamed(
      'view-question',
      pathParameters: {'questionId': ?question.docId},
    );

    if (!context.mounted) return;

    if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('$result'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    }
  }
}
