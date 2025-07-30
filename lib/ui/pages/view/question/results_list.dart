import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/utils/date_string.dart';

import '../../../../models/answer.dart';
import '../../../../models/grading.dart';
import '../../../../services/firestore/firestore_service.dart';
import '../../../../utils/score.dart';
import '../../../commons/circular_status_indicator.dart';

class ResultsList extends StatefulWidget {
  final String userId;
  final String questionId;

  const ResultsList({
    super.key,
    required this.questionId,
    required this.userId,
  });

  @override
  State<ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<ResultsList> {
  late final Stream<List<Answer>> _answersStream;
  late final Stream<List<Grading>> _gradingsStream;

  @override
  void initState() {
    super.initState();
    _answersStream = FirestoreService().streamAnswers(
      userId: widget.userId,
      questionId: widget.questionId,
    );
    _gradingsStream = FirestoreService().streamGradings(
      userId: widget.userId,
      questionId: widget.questionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Results',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        StreamBuilder<List<Answer>>(
          stream: _answersStream,
          builder: (context, answerSnapshot) {
            if (answerSnapshot.hasError) {
              return _buildError(
                'Failed to load answers',
                answerSnapshot.error.toString(),
                theme,
              );
            }

            if (answerSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading('Loading answers...', theme);
            }

            final answers = answerSnapshot.data;

            if (answers == null || answers.isEmpty) {
              return _buildEmptyState(theme);
            }

            return StreamBuilder<List<Grading>>(
              stream: _gradingsStream,
              builder: (context, gradingSnapshot) {
                if (gradingSnapshot.hasError) {
                  return _buildError(
                    'Failed to load gradings',
                    gradingSnapshot.error.toString(),
                    theme,
                  );
                }

                final gradings = gradingSnapshot.data ?? [];

                // Sort answers by timestamp (newest first)
                final sortedAnswers = List<Answer>.from(answers)
                  ..sort((a, b) => (b.createdAt).compareTo(a.createdAt));

                return _buildResultsList(sortedAnswers, gradings, theme);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultsList(
    List<Answer> answers,
    List<Grading> gradings,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final answer in answers)
          _buildResultCard(
            answer,
            gradings.firstWhereOrNull((g) => g.answerId == answer.answerId),
            theme,
          ),
      ],
    );
  }

  Widget _buildResultCard(Answer answer, Grading? grading, ThemeData theme) {
    final isGraded = grading != null;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isGraded) {
            context.pushNamed(
              'view-grading-by-id',
              pathParameters: {'gradingId': grading.gradingId!},
            );
          } else {
            context.pushNamed(
              'view-grading-by-answer',
              pathParameters: {'answerId': answer.answerId!},
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(isGraded, grading, theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGraded ? 'Graded Submission' : 'Grade Pending',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Submitted ${createdAgo(answer.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isGraded) _buildGradeDisplay(grading, theme),
                  const SizedBox(width: 12),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (!isGraded) ...[
                const SizedBox(height: 12),
                _buildPendingActions(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    bool isGraded,
    Grading? grading,
    ThemeData theme,
  ) {
    if (isGraded && grading != null) {
      final average =
          grading.categories.fold<double>(
            0.0,
            (sum, category) => sum + category.score,
          ) /
          grading.categories.length;

      return CircularStatusIndicator.text(
        text: getScoreGrade(average.round()),
        accentColor: getScoreColor(average, theme),
      );
    } else {
      return CircularStatusIndicator.icon(icon: Icons.pending_actions);
    }
  }

  Widget _buildGradeDisplay(Grading grading, ThemeData theme) {
    final average =
        grading.categories.fold<double>(
          0.0,
          (sum, category) => sum + category.score,
        ) /
        grading.categories.length;

    return Text(
      '${average.toStringAsFixed(1)}/10',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: getScoreColor(average, theme),
      ),
    );
  }

  Widget _buildPendingActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),

        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'View to grade submission',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String title, String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No submissions yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your answers will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
