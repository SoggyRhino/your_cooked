import 'dart:async';

import 'package:flutter/material.dart';
import 'package:your_cooked/services/firestore/firestore_service.dart';
import 'package:your_cooked/ui/pages/home/question_card.dart';

import '../../../models/history.dart';
import '../../../models/question.dart';

//todo fix stream
class QuestionCarousel extends StatelessWidget {
  final String label;
  final Stream<List<Question>> stream;

  const QuestionCarousel({
    super.key,
    required this.label,
    required this.stream,
  });

  factory QuestionCarousel.fromHistory({
    required String label,
    required Stream<List<History>> historyStream,
  }) {
    final transformer =
        StreamTransformer<List<History>, List<Question>>.fromHandlers(
          handleData: (historyList, sink) async {
            final questionFutures = historyList
                .map((history) => history.id)
                .toSet()
                .map((id) => FirestoreService().getQuestion(id));

            final questions = await Future.wait(questionFutures);

            sink.add(
              questions
                  .where((result) => result.isSuccess())
                  .map((result) => result.getOrThrow())
                  .toList(),
            );
          },
        );

    final stream = historyStream.transform(transformer);
    return QuestionCarousel(label: label, stream: stream);
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

            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ), // Slightly larger and bolder
            ),
          ),
          const SizedBox(height: 12.0),
          StreamBuilder<List<Question>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Centered loader
              } else if (snapshot.hasError) {
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
                        child: QuestionCard(question: snapshot.data![index]),
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
