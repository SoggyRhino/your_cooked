import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter/material.dart';
import 'package:your_cooked/ui/commons/question_card.dart';

import '../../../models/question.dart';
import '../../../services/search_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _searchTextController = TextEditingController();
  final _searcher = SearchService.questionsSearcher;

  Stream<List<Hit>> get _searchHits =>
      _searcher.responses.map((response) => response.hits);

  bool _isRowView = false;

  @override
  void initState() {
    super.initState();
    _searchTextController.addListener(
      () => _searcher.applyState(
        (state) => state.copyWith(query: _searchTextController.text, page: 0),
      ),
    );
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Questions')),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 8.0),

                    Expanded(
                      child: SearchBar(
                        controller: _searchTextController,
                        leading: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(Icons.search),
                        ),
                        hintText: 'Search',
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
            ),
            Expanded(
              child: StreamBuilder<List<Hit>>(
                stream: _searchHits,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final questions = snapshot.data!
                      .map((hit) => Question.fromHit(hit))
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isRowView
                        ? _buildGridView(questions)
                        : _buildListView(questions),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildGridView(List<Question> subset) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    children: subset.map((question) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: QuestionCard(
          questionId: question.docId!,
          questionText: question.questionText,
        ),
      );
    }).toList(),
  );
}

Widget _buildListView(List<Question> subset) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: subset.length,
    itemBuilder: (context, index) {
      final question = subset[index];
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: QuestionCard.row(
          questionId: question.docId!,
          questionText: question.questionText,
        ),
      );
    },
  );
}
