import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmLeaveScope extends StatelessWidget {
  final Widget child;
  final String title;
  final String? content;

  const ConfirmLeaveScope({
    super.key,
    required this.child,
    required this.title,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    // PopScope is the modern way to handle back gestures.
    return PopScope(
      // CRITICAL: Set canPop to false. This prevents the screen from
      // popping automatically and allows our onPopInvoked logic to run instead.
      canPop: false,
      // Use the correct property name: onPopInvoked.
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // This 'didPop' will be false because we set canPop to false.
        // We can add a guard here just in case.
        if (didPop) return;

        // When the user presses back, we now trigger our confirmation dialog.
        _confirmLeave(context);
      },
      child: child,
    );
  }

  /// Shows the confirmation dialog.
  Future<void> _confirmLeave(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: content != null ? Text(content!) : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (shouldPop ?? false) {
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
