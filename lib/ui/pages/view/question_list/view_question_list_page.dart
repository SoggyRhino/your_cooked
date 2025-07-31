import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:your_cooked/models/question_preview.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/services/firestore/firestore_service.dart';

import '../../../../utils/transformers.dart';
import '../../../commons/question_card.dart';

//todo add pagination
class ViewQuestionListPage extends StatefulWidget {
  final String title;
  final String name;
  final Stream<List<QuestionPreview>> Function(String userId) getStream;

  const ViewQuestionListPage({
    super.key,
    required this.getStream,
    required this.title,
    required this.name,
  });

  factory ViewQuestionListPage.questions() {
    return ViewQuestionListPage(
      title: 'My Questions',
      name: 'questions',
      getStream: (userId) => FirestoreService()
          .getQuestionsStream(userId: userId)
          .transform(questionsToPreviewTransformer),
    );
  }

  factory ViewQuestionListPage.history() {
    return ViewQuestionListPage(
      title: 'History',
      name: 'history',
      getStream: (userId) => FirestoreService()
          .streamHistory(userId: userId)
          .transform(historyToPreviewTransformer),
    );
  }

  @override
  State<ViewQuestionListPage> createState() => _ViewQuestionListPageState();
}

class _ViewQuestionListPageState extends State<ViewQuestionListPage> {
  late final String _userId;
  late Stream<List<QuestionPreview>> _stream;
  String _query = '';
  bool _isRowView = false;

  @override
  void initState() {
    _userId = AuthenticationService().currentUser!.uid;
    _stream = widget.getStream(_userId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 8.0),
                Expanded(
                  child: SearchBar(
                    hintText: 'Search ${widget.name.capitalize}',
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isRowView = !_isRowView;
                    });
                  },
                  icon: Icon(_isRowView ? Icons.list : Icons.grid_view),
                ),
                const SizedBox(width: 8.0),
              ],
            ),
          ),
          StreamBuilder<List<QuestionPreview>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _stream = widget.getStream(_userId);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final subset = snapshot.data!
                  .where(
                    (question) => question.questionText.toLowerCase().contains(
                      _query.toLowerCase(),
                    ),
                  )
                  .toList();

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _isRowView
                    ? _buildGridView(subset)
                    : _buildListView(subset),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<QuestionPreview> subset) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      children: subset.map((preview) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: QuestionCard(
            questionId: preview.questionId,
            questionText: preview.questionText,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListView(List<QuestionPreview> subset) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: subset.length,
      itemBuilder: (context, index) {
        final preview = subset[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: QuestionCard(
            questionId: preview.questionId,
            questionText: preview.questionText,
            row: true,
          ),
        );
      },
    );
  }
}
