import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/ui/pages/answer/answer_page.dart';
import 'package:your_cooked/ui/pages/answer/standard/answer_standard_page.dart';
import 'package:your_cooked/ui/pages/create/create_question_page.dart';
import 'package:your_cooked/ui/pages/home/home_page.dart';
import 'package:your_cooked/ui/pages/login/login_page.dart';
import 'package:your_cooked/ui/pages/profile/username_page.dart';
import 'package:your_cooked/ui/pages/view/grading/view_grading_page.dart';
import 'package:your_cooked/ui/pages/view/question/view_question_page.dart';

import '../services/auth/auth_service.dart';
import '../services/profile/profile_service.dart';

final router = GoRouter(
  initialLocation: '/home',
  refreshListenable: GoRouterRefreshStream([
    AuthenticationService().authStateStream,
    ProfileService().profileStateStream,
  ]),
  redirect: (context, state) {
    final isAuthenticated = AuthenticationService().isAuthenticated;
    final profileState = ProfileService().state;
    final location = state.matchedLocation;

    // Allow access to login page when not authenticated
    if (!isAuthenticated) {
      return location == '/login' ? null : '/login';
    }

    // User is authenticated, handle profile states
    switch (profileState) {
      case ProfileState.loading:
        // Stay on current page while loading
        return null;

      case ProfileState.setup:
        // Redirect to profile setup unless already there
        return location == '/profile/username' ? null : '/profile/username';

      case ProfileState.error:
        // Could redirect to an error page or stay put
        return null;

      case ProfileState.complete:
        // Profile is complete, allow normal navigation
        // But don't let completed users access setup pages
        if (location == '/profile/username' || location == '/login') {
          return '/home';
        }
        return null;
    }
  },
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/create/question',
      name: 'create-question',
      builder: (context, state) => const CreateQuestionPage(),
    ),
    GoRoute(
      path: '/view/question/:questionId',
      name: 'view-question',
      builder: (context, state) {
        final questionId =
            state.pathParameters['questionId'] ?? 'Missing question Id';

        return ViewQuestionPage(questionId: questionId);
      },
      redirect: (context, state) =>
          state.pathParameters['questionId'] == null ? '/home' : null,
    ),
    GoRoute(
      path: '/view/grading/:answerId',
      name: 'view-grading',
      builder: (context, state) {
        final answerId =
            state.pathParameters['answerId'] ?? 'Missing answer Id';
        return ViewGradingPage.fromAnswer(answerId: answerId);
      },
      redirect: (context, state) =>
          state.pathParameters['gradingId'] == null ? '/home' : null,
    ),
    GoRoute(
      path: '/view/grading/by-answer/:answerId', // Changed path
      name: 'view-grading-by-answer', // Unique name
      builder: (context, state) {
        final answerId =
            state.pathParameters['answerId'] ?? 'Missing answer Id';
        // Consider error handling if 'answerId' is truly missing
        // instead of defaulting to 'Missing answer Id'
        return ViewGradingPage.fromAnswer(answerId: answerId);
      },
      redirect: (context, state) =>
          state.pathParameters['answerId'] == null ? '/home' : null,
    ),
    GoRoute(
      path: '/view/grading/by-id/:gradingId', // Changed path
      name: 'view-grading-by-id', // Unique name
      builder: (context, state) {
        final gradingId =
            state.pathParameters['gradingId'] ?? 'Missing grading Id';
        return ViewGradingPage(gradingId: gradingId);
      },
      redirect: (context, state) =>
          state.pathParameters['gradingId'] == null ? '/home' : null,
    ),

    GoRoute(
      path: "/answer:questionId",
      name: "answer",
      builder: (context, state) {
        final questionId =
            state.pathParameters['questionId'] ?? 'Missing question Id';

        return AnswerPage(questionId: questionId);
      },
      redirect: (context, state) =>
          state.pathParameters['questionId'] == null ? '/home' : null,

      routes: [
        GoRoute(
          path: 'standard',
          name: 'answer-standard',

          builder: (context, state) {
            final questionId =
                state.pathParameters['questionId'] ?? 'Missing question Id';

            return AnswerStandardPage(questionId: questionId);
          },
          redirect: (context, state) =>
              state.pathParameters['questionId'] == null ? '/home' : null,
        ),
      ],
    ),
    GoRoute(
      path: '/profile/username',
      name: 'profile-username',
      builder: (context, state) => UsernamePage(isNewUser: true),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(List<Stream<dynamic>> stream) {
    _subscriptions = [];
    for (final s in stream) {
      _subscriptions.add(
        s.asBroadcastStream().listen((_) => notifyListeners()),
      );
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
