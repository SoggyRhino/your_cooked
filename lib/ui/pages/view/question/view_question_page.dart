// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:your_cooked/ui/pages/view/question/quetion_answer_card.dart';
import 'package:your_cooked/ui/pages/view/question/results_list.dart';
import 'package:your_cooked/ui/pages/view/question/tag_list.dart';

import '../../../../models/question.dart';
import '../../../../services/auth/auth_service.dart';
import '../../../../services/firestore/firestore_service.dart';

class ViewQuestionPage extends StatefulWidget {
  final String questionId;

  const ViewQuestionPage({super.key, required this.questionId});

  @override
  State<ViewQuestionPage> createState() => _ViewQuestionPageState();
}

class _ViewQuestionPageState extends State<ViewQuestionPage> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = AuthenticationService().currentUser!.uid;
  }

  Future<void> updateHistory(Question question) async {
    final _ = await FirestoreService().updateHistory(
      userId,
      question.docId!,
      question.questionText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getQuestion(widget.questionId),

      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data!;

          if (result.isError()) {
            return _handleError(
              result.exceptionOrNull()?.toString() ?? 'Unknown error',
            );
          } else {
            final question = result.getOrThrow();
            updateHistory(question);
            return _build(question, false);
          }
        } else if (snapshot.hasError) {
          return _handleError(snapshot.error?.toString() ?? 'Unknown error');
        }

        final question = Question(
          docId: "docId",
          questionText: "questionText",
          answerText: "answerText",
          tags: ["tags"],
          visibility: "visibility",
          createdAt: DateTime.now(),
          userId: "userId",
        );

        return _build(question, true);
      },
    );
  }

  Widget _build(Question question, bool isLoading) {
    return Scaffold(
      appBar: AppBar(),
      body: Skeletonizer(
        enabled: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              ListView(
                children: [
                  QuestionAnswerCard(
                    questionText: question.questionText,
                    answerText: question.answerText,
                  ),
                  const SizedBox(height: 24),
                  if (question.tags.isNotEmpty) ...[
                    TagList(tags: question.tags),
                    const SizedBox(height: 24),
                  ],
                  ResultsList(
                    userId: userId,
                    questionId: question.docId!,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              Positioned(
                bottom: 8,
                left: 16,
                right: 16,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _answer,
                    style: Theme
                        .of(context)
                        .elevatedButtonTheme
                        .style,
                    child: const Text('Answer'),
                  ),
                ),
              ),
              //const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handleError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.canPop()) {
        context.pop([errorMessage]);
      } else {
        context.goNamed('home');
      }
    });
    return const SizedBox.shrink();
  }

  Future<void> _answer() async {
    final result = await context.pushNamed(
      'answer',
      pathParameters: {'questionId': widget.questionId},
    );

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
