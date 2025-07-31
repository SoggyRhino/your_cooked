// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/services/profile/profile_service.dart';

import '../../../models/user.dart';
import '../../../services/firestore/firestore_service.dart';

class UsernamePage extends StatefulWidget {
  final bool isNewUser;

  const UsernamePage({super.key, required this.isNewUser});

  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  late final String userId;
  late final String? displayName;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    userId = AuthenticationService().currentUser!.uid;
    displayName = AuthenticationService().currentUser!.displayName;
    _usernameController.text = displayName ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.isNewUser ? 'Create Username' : 'Update Username',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: "Enter your username",
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username cannot be empty';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Set UserName'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      //todo better handling but should never be null
      final User user = User(
        userId: AuthenticationService().currentUser!.uid,
        userName: _usernameController.text,
        joined: DateTime.now(),
      );

      final result = await FirestoreService().createUser(user);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result.isSuccess()) {
        await ProfileService().updateProfile(user);
        context.replaceNamed('home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.exceptionOrNull()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
