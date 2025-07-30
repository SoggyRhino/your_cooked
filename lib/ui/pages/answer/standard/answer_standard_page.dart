import 'package:flutter/material.dart';
import 'package:your_cooked/ui/pages/answer/standard/chat_interview.dart';

import '../../../../services/auth/auth_service.dart';
import '../../../../services/firestore/firestore_service.dart';
import '../../../commons/confirm_leave.dart';

class AnswerStandardPage extends StatefulWidget {
  final String questionId;

  const AnswerStandardPage({super.key, required this.questionId});

  @override
  State<StatefulWidget> createState() => _AnswerStandardPageState();
}

class _AnswerStandardPageState extends State<AnswerStandardPage> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = AuthenticationService().currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConfirmLeaveScope(
      title: 'Are you sure you want to leave?',
      content: 'Your interview will be lost.',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          title: Text(
            'Interview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: FutureBuilder(
            future: FirestoreService().getQuestion(widget.questionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data != null) {
                  final result = snapshot.data!;
                  if (result.isError()) {
                    return _buildError(
                      result.exceptionOrNull()?.toString() ?? 'Unknown error',
                    );
                  }
                  return ChatInterview(
                    userId: userId,
                    question: result.getOrThrow(),
                  );
                }
              }
              return _buildLoading();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(String errorMessage) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $errorMessage',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer.withValues(
                  alpha: 0.8,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading interview...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
