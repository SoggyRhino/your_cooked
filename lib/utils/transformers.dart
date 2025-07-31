import 'dart:async';

import '../models/history.dart';
import '../models/question.dart';
import '../models/question_preview.dart';

final questionsToPreviewTransformer =
    StreamTransformer<List<Question>, List<QuestionPreview>>.fromHandlers(
      handleData: (questionList, sink) =>
          sink.add(questionList.map(QuestionPreview.fromQuestion).toList()),
    );

final historyToPreviewTransformer =
    StreamTransformer<List<History>, List<QuestionPreview>>.fromHandlers(
      handleData: (historyList, sink) =>
          sink.add(historyList.map(QuestionPreview.fromHistory).toList()),
    );
