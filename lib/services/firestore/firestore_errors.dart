import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreError implements Exception {
  final String message;
  final String code;

  const FirestoreError(this.message, this.code);

  factory FirestoreError.fromFirebaseError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const FirestoreError(
            'Permission denied. Check your Firestore Security Rules.',
            'permission-denied',
          );
        case 'unavailable':
          return const FirestoreError(
            'The service is currently unavailable. This is a most likely a network condition, so please check your internet connection.',
            'unavailable',
          );
        case 'invalid-argument':
          return const FirestoreError(
            'Invalid argument provided to Firestore operation.',
            'invalid-argument',
          );
        case 'unauthenticated':
          return const FirestoreError(
            'The request does not have valid authentication credentials for the operation.',
            'unauthenticated',
          );
        case 'resource-exhausted':
          return const FirestoreError(
            'Resource has been exhausted (e.g. check quota).',
            'resource-exhausted',
          );
        default:
          return FirestoreError(
            'Firestore error: ${error.message}',
            error.code,
          );
      }
    }
    return FirestoreError('Unknown authentication error: $error', 'unknown');
  }

  factory FirestoreError.missingQuestion() =>
      const FirestoreError('Missing question', 'missing-question');

  factory FirestoreError.missingUser() =>
      const FirestoreError('Missing user', 'missing-user');

  @override
  String toString() => 'FirestoreError($code): $message';
}

class FirestoreTimeoutError extends FirestoreError {
  const FirestoreTimeoutError()
    : super('Firestore request timed out', 'timeout');
}
