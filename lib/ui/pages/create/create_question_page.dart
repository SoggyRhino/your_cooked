import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:your_cooked/models/question.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/ui/pages/create/tag_form_field.dart';

import '../../../services/firestore/firestore_service.dart';
import 'input_card.dart';

class CreateQuestionPage extends StatefulWidget {
  const CreateQuestionPage({super.key});

  @override
  State<StatefulWidget> createState() => _CreateQuestionPageState();
}

class _CreateQuestionPageState extends State<CreateQuestionPage> {
  //form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final _tagController = StringTagController();
  final TextEditingController _answerController = TextEditingController();
  bool _private = false;

  //ui state
  bool _isLoading = false;
  DateTime? lastPop;

  @override
  void dispose() {
    _questionController.dispose();
    _tagController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = AuthenticationService().currentUser;
      if (user == null) {
        context.goNamed('login');
        return;
      }

      final result = await FirestoreService().createQuestion(
        Question(
          questionText: _questionController.text,
          answerText: _answerController.text,
          tags: _tagController.getTags ?? [],
          visibility: _private ? 'private' : 'public',
          createdAt: DateTime.now(),
          userId: user.uid,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      if (result.isSuccess()) {
        context.pop();
      } else {
        final exception = result.exceptionOrNull();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save question: $exception'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, object) {
        if (didPop) return;

        DateTime now = DateTime.now();

        if (lastPop == null ||
            now.difference(lastPop!) > const Duration(seconds: 3)) {
          lastPop = now;
          _confirmLeave();
        } else {
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Question'),
          centerTitle: true,

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: colorScheme.outlineVariant),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(),
                  _buildTagsCard(),
                  _buildAnswerCard(),
                  _buildVisibilityCard(colorScheme, theme),
                  _buildActionRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputCard _buildQuestionCard() {
    return InputCard(
      label: 'Question',
      icon: Icons.question_mark,

      child: TextFormField(
        controller: _questionController,
        minLines: 5,
        maxLines: null,
        decoration: const InputDecoration(
          hintText: 'Enter your question here...',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Question cannot be empty';
          }
          return null;
        },
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  InputCard _buildTagsCard() {
    return InputCard(
      label: 'Tags',
      icon: Icons.tag,
      child: TagFormField(tagController: _tagController),
    );
  }

  InputCard _buildAnswerCard() {
    return InputCard(
      label: 'Answer',
      icon: Icons.edit,
      child: TextFormField(
        controller: _answerController,
        minLines: 5,
        maxLines: null,
        decoration: const InputDecoration(
          hintText: 'Enter your answer here...',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Answer cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  InputCard _buildVisibilityCard(ColorScheme colorScheme, ThemeData theme) {
    return InputCard(
      label: 'Visibility',
      icon: Icons.visibility,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _private = !_private;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              Icon(
                _private ? Icons.lock : Icons.public,
                color: _private ? colorScheme.secondary : colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _private ? 'Private Question' : 'Public Question',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _private
                          ? 'Only you can see this question'
                          : 'Everyone can see this question',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _private,
                onChanged: (value) {
                  setState(() {
                    _private = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //todo remove cancel ?
  Row _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmLeave(),

            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveQuestion,
            // Removed manual styling to use the theme's ElevatedButtonTheme.
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(),
                  )
                : const Text('Save Question'),
          ),
        ),
      ],
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // This AlertDialog will be styled by the theme automatically.
        return AlertDialog(
          title: const Text('Are you sure you want to leave?'),
          content: const Text('Your changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (context.mounted) {
                  context.pop(); // Leave page
                }
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}
