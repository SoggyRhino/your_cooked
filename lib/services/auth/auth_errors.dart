import 'package:firebase_auth/firebase_auth.dart';

class AuthError implements Exception {
  final String message;
  final String code;

  const AuthError(this.message, this.code);

  @override
  String toString() => 'AuthError($code): $message';
}

class EmailPasswordAuthError extends AuthError {
  const EmailPasswordAuthError(super.message, super.code);

  factory EmailPasswordAuthError.fromFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return const EmailPasswordAuthError(
            'No user found with this email address',
            'user-not-found',
          );
        case 'wrong-password':
          return const EmailPasswordAuthError(
            'Incorrect password',
            'wrong-password',
          );
        case 'invalid-email':
          return const EmailPasswordAuthError(
            'Invalid email address format',
            'invalid-email',
          );
        case 'user-disabled':
          return const EmailPasswordAuthError(
            'This account has been disabled',
            'user-disabled',
          );
        case 'too-many-requests':
          return const EmailPasswordAuthError(
            'Too many failed attempts. Please try again later',
            'too-many-requests',
          );
        case 'email-already-in-use':
          return const EmailPasswordAuthError(
            'An account with this email already exists',
            'email-already-in-use',
          );
        case 'weak-password':
          return const EmailPasswordAuthError(
            'Password is too weak',
            'weak-password',
          );
        default:
          return EmailPasswordAuthError(
            'Authentication failed: ${error.message}',
            error.code,
          );
      }
    }
    return EmailPasswordAuthError(
      'Unknown authentication error: $error',
      'unknown',
    );
  }
}

class GoogleSignInError extends AuthError {
  const GoogleSignInError(super.message, super.code);

  factory GoogleSignInError.fromError(dynamic error) {
    if (error.toString().contains('sign_in_canceled')) {
      return const GoogleSignInError(
        'Sign in was cancelled',
        'sign-in-cancelled',
      );
    } else if (error.toString().contains('network_error')) {
      return const GoogleSignInError('Network error occurred', 'network-error');
    } else if (error.toString().contains('sign_in_failed')) {
      return const GoogleSignInError('Google sign in failed', 'sign-in-failed');
    }
    return GoogleSignInError('Google sign in error: $error', 'unknown');
  }
}

class AuthTimeoutError extends AuthError {
  const AuthTimeoutError()
    : super('Authentication request timed out', 'timeout');
}
