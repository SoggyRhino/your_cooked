import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:your_cooked/ui/pages/view/grading/category_card.dart';

import '../../../../models/grading.dart';
import '../../../../services/ai/ai_service.dart';
import '../../../../services/firestore/firestore_service.dart';
import '../../../../utils/score.dart';

class ViewGradingPage extends StatefulWidget {
  final String? answerId;
  final String? gradingId;

  const ViewGradingPage({super.key, required this.gradingId}) : answerId = null;

  const ViewGradingPage.fromAnswer({super.key, required this.answerId})
    : gradingId = null;

  @override
  State<ViewGradingPage> createState() => _ViewGradingPageState();
}

class _ViewGradingPageState extends State<ViewGradingPage> {
  String _loadingMessage = 'Loading grading...';
  String? _answerId;
  String? _gradingId;

  late Future<Grading> _gradingFuture;

  @override
  void initState() {
    super.initState();
    _answerId = widget.answerId;
    _gradingId = widget.gradingId;
    _gradingFuture = _fetchGrading();
  }

  @override
  void dispose() {
    _gradingFuture.ignore();
    super.dispose();
  }

  //todo make result
  Future<Grading> _fetchGrading() async {
    if (_gradingId != null) {
      setState(() {
        _loadingMessage = 'Loading grading details...';
      });

      final gradingResult = await FirestoreService().getGrading(_gradingId!);
      return gradingResult.getOrThrow();
    } else {
      setState(() {
        _loadingMessage = 'Fetching answer details...';
      });

      //load answer
      final answerResult = await FirestoreService().getAnswer(_answerId!);
      if (answerResult.isError()) {
        throw Exception(
          'Failed to fetch answer: ${answerResult.exceptionOrNull()}',
        );
      }

      setState(() {
        _loadingMessage = 'Creating grading assessment...';
      });
      final answer = answerResult.getOrThrow();

      final categoriesResult = await AiService().generateGradingCategories(
        answer,
      );
      if (categoriesResult.isError()) {
        throw Exception(
          'Failed to create grading: ${categoriesResult.exceptionOrNull()}',
        );
      }

      setState(() {
        _loadingMessage = 'Finalizing grading results...';
      });

      final categories = categoriesResult.getOrThrow();
      final gradingResult = await FirestoreService().createGrading(
        answer: answer,
        categories: categories,
      );
      if (gradingResult.isError()) {
        throw Exception(
          'Failed to create grading: ${gradingResult.exceptionOrNull()}',
        );
      }

      final gradingId = gradingResult.getOrThrow();
      final fetchedGradingResult = await FirestoreService().getGrading(
        gradingId,
      );
      if (fetchedGradingResult.isError()) {
        throw Exception(
          'Failed to fetch grading results: ${fetchedGradingResult.exceptionOrNull()}',
        );
      }

      setState(() {
        _gradingId = gradingId;
      });

      return fetchedGradingResult.getOrThrow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: FutureBuilder<Grading>(
        future: _gradingFuture,
        builder: (BuildContext context, AsyncSnapshot<Grading> snapshot) {
          if (snapshot.hasData) {
            return _buildGradingContent(snapshot.data!, theme);
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString(), theme);
          } else {
            return _buildLoading(theme);
          }
        },
      ),
    );
  }

  Widget _buildGradingContent(Grading grading, ThemeData theme) {
    double average = 0;
    for (var category in grading.categories) {
      average += category.score;
    }
    average /= grading.categories.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildOverallScoreCard(average, grading.categories, theme),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Detailed Feedback',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: CategoryCard(category: grading.categories[index]),
            ),
            childCount: grading.categories.length,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScoreCard(
    double average,
    List<Category> categories,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                percent: average / 10,
                animation: true,
                animationDuration: 1000,
                circularStrokeCap: CircularStrokeCap.round,
                animateFromLastPercent: true,
                curve: Curves.easeOutCubic,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                progressColor: getScoreColor(average, theme),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getScoreGrade(average.clamp(0, 10).round()),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: getScoreColor(average, theme),
                      ),
                    ),
                    Text(
                      '${average.toStringAsFixed(1)}/10',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('View Your Answer'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Re-Grade'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
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
            _loadingMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _gradingFuture = _fetchGrading();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
