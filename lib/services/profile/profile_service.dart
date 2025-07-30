import 'dart:async';

import 'package:your_cooked/services/firestore/firestore_service.dart';

import '../../models/user.dart';
import '../auth/auth_service.dart';
import '../firestore/firestore_errors.dart';

enum ProfileState { setup, loading, error, complete }

class ProfileService {
  final _profileController = StreamController<ProfileState>.broadcast();
  User? _currentUser;
  ProfileState _state = ProfileState.loading;
  StreamSubscription? _authSubscription;

  ProfileService._();

  static final ProfileService _instance = ProfileService._();

  factory ProfileService() => _instance;

  Stream<ProfileState> get profileStateStream => _profileController.stream;

  User? get currentUser => _currentUser;

  ProfileState get state => _state;

  Future<void> initialize() async {
    // Cancel existing subscription if any
    await _authSubscription?.cancel();

    _authSubscription = AuthenticationService().userStream.listen((user) async {
      if (user == null) {
        _currentUser = null;
        _updateState(ProfileState.loading);
        return;
      }

      await refreshProfile();
    });

    if (AuthenticationService().currentUser != null) {
      await refreshProfile();
    }
  }

  void _updateState(ProfileState newState) {
    if (_state != newState) {
      _state = newState;
      _profileController.add(newState);
    }
  }

  Future<void> updateProfile(User user) async {
    _currentUser = user;
    _updateState(ProfileState.complete);
  }

  Future<void> refreshProfile() async {
    final currentUser = AuthenticationService().currentUser;
    if (currentUser == null) return;

    _updateState(ProfileState.loading);
    try {
      final result = await FirestoreService().getUser(currentUser.uid);

      if (result.isSuccess()) {
        final userData = result.getOrThrow();
        _currentUser = userData;
        _updateState(ProfileState.complete);
      } else {
        final exception = result.exceptionOrNull();

        if (exception is FirestoreError && exception.code == 'not-found') {
          _updateState(ProfileState.setup);
        } else {
          print('Profile service error: $exception');
          _updateState(ProfileState.error);
        }
      }
    } catch (e) {
      print('Unexpected error in profile service: $e');
      _updateState(ProfileState.error);
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _profileController.close();
  }
}
