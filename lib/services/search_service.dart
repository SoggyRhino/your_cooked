import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';

class SearchService {
  static HitsSearcher get questionsSearcher => HitsSearcher(
    applicationID: '11PSW57A75',
    apiKey: '4d5e9fcea16edfb37f5dfeca77dfe294',
    indexName: 'questions',
  );
}
