import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/ui/commons/question_card.dart';
import 'package:your_cooked/utils/transformers.dart';

import '../../../models/history.dart';
import '../../../models/question.dart';
import '../../../models/question_preview.dart';

//todo fix stream
class QuestionCarousel extends StatelessWidget {
  final String label;
  final Stream<List<QuestionPreview>> stream;
  final String viewMoreLink;

  const QuestionCarousel({
    super.key,
    required this.label,
    required this.stream,
    required this.viewMoreLink,
  });

  factory QuestionCarousel.fromHistory({
    required String label,
    required Stream<List<History>> historyStream,
  }) {
    return QuestionCarousel(
      label: label,
      stream: historyStream.transform(historyToPreviewTransformer),
      viewMoreLink: 'view-history',
    );
  }

  factory QuestionCarousel.fromQuestions({
    required String label,
    required Stream<List<Question>> questionsStream,
  }) {
    return QuestionCarousel(
      label: label,
      stream: questionsStream.transform(questionsToPreviewTransformer),
      viewMoreLink: 'view-my-questions',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),

            child: Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ), // Slightly larger and bolder
                ),
                Expanded(child: Container()),
                TextButton(
                  onPressed: () {
                    context.pushNamed(viewMoreLink);
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          StreamBuilder<List<QuestionPreview>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Centered loader
              } else if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                );
              } else if (snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Nothing here :(',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              } else {
                return SizedBox(
                  height: 120, // Slightly reduced height, adjust as needed
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 16.0 : 8.0,
                          right: 8.0,
                        ),
                        // Consistent spacing
                        child: QuestionCard(
                          questionId: snapshot.data![index].questionId,
                          questionText: snapshot.data![index].questionText,
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
