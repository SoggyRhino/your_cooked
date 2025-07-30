// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/ui/pages/view/question/quetion_answer_card.dart';
import 'package:your_cooked/ui/pages/view/question/results_list.dart';
import 'package:your_cooked/ui/pages/view/question/tag_list.dart';

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
    update();
  }

  Future<void> update() async {
    final _ = await FirestoreService().updateHistory(
      userId,
      widget.questionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getQuestion(widget.questionId),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          String errorMessage = 'Error loading question';

          if (snapshot.hasError) {
            errorMessage = 'Error loading question ${snapshot.error}';
          } else if (snapshot.hasData) {
            final result = snapshot.data!;

            if (result.isError()) {
              errorMessage =
                  result.exceptionOrNull()?.toString() ?? 'Unknown error';
            } else {
              final question = result.getOrThrow();

              return Scaffold(
                appBar: AppBar(),
                body: Padding(
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
                        child: _buildAnswerButtons(context),
                      ),
                      //const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleError(errorMessage);
          });

          return SizedBox.shrink();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _handleError(String errorMessage) async {
    if (context.canPop()) {
      context.pop([errorMessage]);
    } else {
      context.goNamed('home');
    }
  }

  Widget _buildAnswerButtons(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.elevatedButtonTheme.style;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: _answer,
        style: style,
        child: const Text('Answer'),
      ),
    );
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
