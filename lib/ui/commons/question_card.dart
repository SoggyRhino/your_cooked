import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionCard extends StatelessWidget {
  final String questionId;
  final String questionText;
  final bool row;

  const QuestionCard({
    super.key,
    required this.questionId,
    required this.questionText,
    this.row = false,
  });

  factory QuestionCard.row({
    required String questionId,
    required String questionText,
  }) =>
      QuestionCard(
        questionId: questionId,
        questionText: questionText,
        row: true,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _viewQuestion(context),
      child: row ? _buildRow(context) : _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.topLeft,
        child: Text(
          questionText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 3, // Limit text to a few lines
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
        onTap: () => _viewQuestion(context),
        title: Text(
          questionText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        tileColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(125),
          ),
        )

    );
  }

  Future<void> _viewQuestion(BuildContext context) async {
    final result = await context.pushNamed(
      'view-question',
      pathParameters: {'questionId': questionId},
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
