import 'dart:async';

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
  final Map<String, dynamic> results = {};
  late final StreamSubscription _answersSubscription;
  late final StreamSubscription _gradingsSubscription;

  @override
  void initState() {
    super.initState();
    _answersSubscription = FirestoreService()
        .streamAnswers(userId: widget.userId, questionId: widget.questionId)
        .listen((answers) {
          setState(() {
            for (final answer in answers) {
              results[answer.answerId!] = answer;
            }
          });
        });
    _gradingsSubscription = FirestoreService()
        .streamGradings(userId: widget.userId, questionId: widget.questionId)
        .listen((gradings) {
          setState(() {
            for (final grading in gradings) {
              if (!results.containsKey(grading.answerId)) {
                results[grading.answerId] = grading;
              }
            }
          });
        });
  }

  @override
  void dispose() {
    _answersSubscription.cancel();
    _gradingsSubscription.cancel();
    super.dispose();
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
        ...results.values
            .sorted((a, b) => b.createdAt.compareTo(a.createdAt))
            .map(
              (result) => _buildResultCard(
                (result is Answer ? result : null),
                (result is Grading ? result : null),
              ),
            ),
      ],
    );
  }

  Widget _buildResultCard(Answer? answer, Grading? grading) {
    final isGraded = grading != null;
    final theme = Theme.of(context);

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
              pathParameters: {'answerId': answer!.answerId!},
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
                          'Submitted ${createdAgo(isGraded ? grading.createdAt : answer!.createdAt)}',
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
}
