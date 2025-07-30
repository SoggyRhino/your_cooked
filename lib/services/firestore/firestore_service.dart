import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:result_dart/result_dart.dart';
import 'package:your_cooked/models/user.dart';
import 'package:your_cooked/services/firestore/firestore_errors.dart';

import '../../models/answer.dart';
import '../../models/grading.dart';
import '../../models/history.dart';
import '../../models/question.dart';
import 'firestore_collections.dart';

//todo add crashlytics
class FirestoreService {
  static const Duration _fireStoreTimeout = Duration(seconds: 30);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Question> _questionsReference;
  late final CollectionReference<User> _userReference;
  late final CollectionReference<Answer> _answerReference;
  late final CollectionReference<Grading> _gradingReference;

  static final FirestoreService _instance = FirestoreService._();

  factory FirestoreService() => _instance;

  FirestoreService._() {
    _questionsReference = _firestore
        .collection(FirestoreCollections.questions)
        .withConverter<Question>(
          fromFirestore: (snapshot, options) =>
              Question.fromFirestore(snapshot, options),
          toFirestore: (question, _) => question.toFirestore(),
        );

    _userReference = _firestore
        .collection(FirestoreCollections.users)
        .withConverter<User>(
          fromFirestore: (snapshot, options) =>
              User.fromFirestore(snapshot, options),
          toFirestore: (user, _) => user.toFirestore(),
        );
    _answerReference = _firestore
        .collection(FirestoreCollections.answers)
        .withConverter<Answer>(
          fromFirestore: (snapshot, options) =>
              Answer.fromFirestore(snapshot, options),
          toFirestore: (answer, _) => answer.toFirestore(),
        );
    _gradingReference = _firestore
        .collection(FirestoreCollections.gradings)
        .withConverter<Grading>(
          fromFirestore: (snapshot, options) =>
              Grading.fromFirestore(snapshot, options),
          toFirestore: (grading, _) => grading.toFirestore(),
        );
  }

  CollectionReference<History> getHistoryReference(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.history)
        .withConverter<History>(
          fromFirestore: (snapshot, options) =>
              History.fromFirestore(snapshot, options),
          toFirestore: (history, _) => history.toFirestore(),
        );
  }

  Future<Result<String>> createQuestion(Question question) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.questions)
          .add(question.toFirestore())
          .timeout(_fireStoreTimeout);

      return docRef.id.toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  //todo add pagination
  Future<Result<List<Question>>> getQuestions(String userId) async {
    try {
      final querySnapshot = await _questionsReference
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(_fireStoreTimeout);

      return querySnapshot.docs.map((doc) => doc.data()).toList().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<Question>> getQuestion(String questionId) async {
    try {
      final querySnapshot = await _questionsReference
          .where(FieldPath.documentId, isEqualTo: questionId)
          .limit(1)
          .get()
          .timeout(_fireStoreTimeout);

      if (querySnapshot.docs.isEmpty) {
        return FirestoreError.missingQuestion().toFailure();
      }

      return querySnapshot.docs.first.data().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Stream<List<Question>> getQuestionsStream({
    required String userId,
    int limit = 20,
  }) {
    return _questionsReference
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<Result<bool>> updateHistory(String userId, String questionId) async {
    final history = History(id: questionId, timeStamp: DateTime.now());

    try {
      final user = await getUser(userId);

      if (user.isError()) {
        return user.exceptionOrNull()!.toFailure();
      }
      final historyReference = getHistoryReference(user.getOrThrow().docId!);

      final result = await historyReference
          .where('questionId', isEqualTo: questionId)
          .get();

      if (result.docs.isNotEmpty) {
        await result.docs.first.reference.update(history.toFirestore());
      } else {
        await getHistoryReference(user.getOrThrow().docId!).add(history);
      }

      return true.toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<(List<History>, DocumentSnapshot?)>> getHistory({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final user = await getUser(userId);

      if (user.isError()) {
        return user.exceptionOrNull()!.toFailure();
      }

      var query = getHistoryReference(
        user.getOrThrow().docId!,
      ).orderBy('timeStamp', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query
          .limit(limit)
          .get()
          .timeout(_fireStoreTimeout);

      final historyList = querySnapshot.docs.map((doc) => doc.data()).toList();

      final nextCursor = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : null;

      return (historyList, nextCursor).toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Stream<List<History>> streamHistory(User user, {int limit = 20}) {
    return getHistoryReference(user.docId!)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<Result<String>> createUser(User user) async {
    try {
      final snapshot = await _userReference
          .add(user)
          .timeout(_fireStoreTimeout);

      return Success(snapshot.id);
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<User>> getUser(String userId) async {
    try {
      final snapshot = await _userReference
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get()
          .timeout(_fireStoreTimeout);

      if (snapshot.docs.isEmpty) {
        return FirestoreError.missingUser().toFailure();
      }

      return snapshot.docs.first.data().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<String>> addAnswer({
    required String userId,
    required String? questionId,
    required Iterable<Content> history,
  }) async {
    try {
      final answer = Answer.fromHistory(userId, questionId!, history);

      final reference = await _answerReference
          .add(answer)
          .timeout(_fireStoreTimeout);

      return Success(reference.id);
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Stream<List<Answer>> streamAnswers({
    required String userId,
    required String questionId,
    int limit = 20,
  }) {
    return _answerReference
        .where('questionId', isEqualTo: questionId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  //todo add pagination
  Future<Result<List<Answer>>> getAnswers({
    required String userId,
    required String questionId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _answerReference
          .where('questionId', isEqualTo: questionId)
          .where('userId', isEqualTo: userId)
          .limit(limit)
          .get()
          .timeout(_fireStoreTimeout);

      return snapshot.docs.map((doc) => doc.data()).toList().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<Answer>> getAnswer(String answerId) async {
    try {
      final snapshot = await _answerReference
          .where(FieldPath.documentId, isEqualTo: answerId)
          .limit(1)
          .get()
          .timeout(_fireStoreTimeout);

      return snapshot.docs.first.data().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<String>> createGrading({
    required Answer answer,
    required List<Category> categories,
  }) async {
    try {
      final grading = Grading(
        userId: answer.userId,
        answerId: answer.answerId!,
        questionId: answer.questionId,
        categories: categories,
        createdAt: DateTime.now(),
      );

      final reference = await _gradingReference
          .add(grading)
          .timeout(_fireStoreTimeout);

      return reference.id.toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Future<Result<Grading>> getGrading(String gradingId) async {
    try {
      final snapshot = await _gradingReference
          .where(FieldPath.documentId, isEqualTo: gradingId)
          .limit(1)
          .get()
          .timeout(_fireStoreTimeout);

      return snapshot.docs.first.data().toSuccess();
    } on TimeoutException {
      return const FirestoreTimeoutError().toFailure();
    } catch (e) {
      return FirestoreError.fromFirebaseError(e).toFailure();
    }
  }

  Stream<List<Grading>> streamGradings({
    required String userId,
    required String questionId,
    int limit = 20,
  }) {
    return _gradingReference
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Grading>> streamUserGradings({
    required String userId,
    int limit = 20,
  }) {
    return _gradingReference
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
