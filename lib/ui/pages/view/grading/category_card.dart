import 'package:flutter/material.dart';
import 'package:percent_indicator/multi_segment_linear_indicator.dart';
import 'package:your_cooked/ui/commons/circular_status_indicator.dart';

import '../../../../models/grading.dart';
import '../../../../utils/score.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = getScoreColor(category.score.roundToDouble(), theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircularStatusIndicator.text(
            text: '${category.score}',
            accentColor: scoreColor,
          ),
          title: Text(
            category.category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: MultiSegmentLinearIndicator(
            segments: [
              SegmentLinearIndicator(
                percent: category.score / 10,
                color: scoreColor,
              ),
            ],
            animateFromLastPercent: true,
            animationDuration: 1000,
            animation: true,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.feedback.isNotEmpty) ...[
                    _buildFeedbackSection(
                      'Feedback',
                      category.feedback,
                      Icons.feedback,
                      theme,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (category.strengths.isNotEmpty) ...[
                    _buildListSection(
                      'Strengths',
                      category.strengths,
                      Icons.thumb_up,
                      theme.colorScheme.primary,
                      theme,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (category.weaknesses.isNotEmpty) ...[
                    _buildListSection(
                      'Areas for Improvement',
                      category.weaknesses,
                      Icons.trending_up,
                      theme.colorScheme.secondary,
                      theme,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(content, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
