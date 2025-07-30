import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:result_dart/result_dart.dart';

import 'auth_errors.dart';

enum AuthState { initial, authenticated, unauthenticated, loading, error }

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const Duration _authTimeout = Duration(seconds: 30);

  /// Streams of authentication state changes
  final _authStateController = StreamController<AuthState>.broadcast();
  final _userController = StreamController<User?>.broadcast();
  User? _currentUser;

  AuthenticationService._();

  static final AuthenticationService _instance = AuthenticationService._();

  factory AuthenticationService() => _instance;

  Stream<AuthState> get authStateStream => _authStateController.stream;

  Stream<User?> get userStream => _userController.stream;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    try {
      await _googleSignIn.initialize(
        clientId:
            '661306578439-bagsq2hh8dgk5sgvnerknqpf1kjjvpbq.apps.googleusercontent.com',
      );

      // Listen to auth state changes
      _firebaseAuth.authStateChanges().listen((user) {
        _currentUser = user;
        _userController.add(user);
        _authStateController.add(
          user != null ? AuthState.authenticated : AuthState.unauthenticated,
        );
      });

      // Set initial state
      _authStateController.add(
        _firebaseAuth.currentUser != null
            ? AuthState.authenticated
            : AuthState.unauthenticated,
      );
    } catch (e) {
      _authStateController.add(AuthState.error);
      rethrow;
    }
  }

  Future<Result<UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _authStateController.add(AuthState.loading);

    try {
      final result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_authTimeout);

      _authStateController.add(AuthState.authenticated);
      return Success(result);
    } on TimeoutException {
      _authStateController.add(AuthState.error);
      return Failure(const AuthTimeoutError());
    } catch (e) {
      _authStateController.add(AuthState.error);
      return Failure(EmailPasswordAuthError.fromFirebaseError(e));
    }
  }

  Future<Result<UserCredential>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _authStateController.add(AuthState.loading);

    try {
      final result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_authTimeout);

      _authStateController.add(AuthState.authenticated);
      return Success(result);
    } on TimeoutException {
      _authStateController.add(AuthState.error);
      return Failure(const AuthTimeoutError());
    } catch (e) {
      _authStateController.add(AuthState.error);
      return Failure(EmailPasswordAuthError.fromFirebaseError(e));
    }
  }

  Future<Result<UserCredential>> signInWithGoogle() async {
    _authStateController.add(AuthState.loading);

    try {
      // Sign out any existing Google session first
      await _googleSignIn.signOut();

      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate()
          .timeout(_authTimeout);

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        _authStateController.add(AuthState.error);
        return Failure(
          const GoogleSignInError('Failed to get Google ID token', 'no-token'),
        );
      }

      final result = await _firebaseAuth
          .signInWithCredential(
            GoogleAuthProvider.credential(idToken: googleAuth.idToken),
          )
          .timeout(_authTimeout);

      _authStateController.add(AuthState.authenticated);
      return Success(result);
    } on TimeoutException {
      _authStateController.add(AuthState.error);
      return Failure(const AuthTimeoutError());
    } catch (e) {
      _authStateController.add(AuthState.error);
      return Failure(GoogleSignInError.fromError(e));
    }
  }

  Future<Result<bool>> signOut() async {
    _authStateController.add(AuthState.loading);

    try {
      // Sign out from both Firebase and Google
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]).timeout(_authTimeout);

      _authStateController.add(AuthState.unauthenticated);
      return Success(true);
    } on TimeoutException {
      _authStateController.add(AuthState.error);
      return Failure(const AuthTimeoutError());
    } catch (e) {
      _authStateController.add(AuthState.error);
      return Failure(AuthError('Sign out failed: $e', 'sign-out-failed'));
    }
  }
}
