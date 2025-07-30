import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:result_dart/result_dart.dart';
import 'package:your_cooked/services/ai/functions.dart';
import 'package:your_cooked/services/ai/instructions.dart';

import '../../models/answer.dart';
import '../../models/grading.dart';
import '../../models/question.dart';

class AiService {
  AiService._();

  static final AiService _instance = AiService._();

  factory AiService() {
    return _instance;
  }

  final _vertexAI = FirebaseAI.vertexAI(auth: FirebaseAuth.instance);

  GenerativeModel getInterviewModel() {
    return _vertexAI.generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(interviewInstrucitons),
      tools: [
        Tool.functionDeclarations([endInterviewFunction]),
      ],
    );
  }

  Content createInterviewPrompt(Question question) {
    return Content('user', [
      TextPart(
        'Please start the interview. Ask me this question: "${question.questionText}"',
      ),
    ]);
  }

  GenerativeModel getResultModel() {
    return _vertexAI.generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(resultInstructions),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(items: Category.schema),
      ),
    );
  }

  Content createResultPrompt(Answer answer) {
    return Content('user', [TextPart(answer.messages.toJson().toString())]);
  }

  Future<Result<List<Category>>> generateGradingCategories(
    Answer answer,
  ) async {
    try {
      final model = getResultModel();
      final prompt = createResultPrompt(answer);
      final response = await model.generateContent([prompt]);

      final List<dynamic> decodedList = jsonDecode(response.text ?? '[]');

      final categories = decodedList
          .map((element) => Category.fromJson(element as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      return Failure(Exception('Failed to generate grading: ${e.toString()}'));
    }
  }
}

extension on List<ChatMessage> {
  Uint8List toJson() {
    final list = map((e) => e.toJson()).toList();
    return Uint8List.fromList(json.encode(list).codeUnits);
  }
}
