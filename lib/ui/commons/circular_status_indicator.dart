import 'package:flutter/material.dart';

class CircularStatusIndicator extends StatelessWidget {
  final Color accentColor;
  final String? text;
  final IconData? icon;

  const CircularStatusIndicator.icon({
    super.key,
    this.accentColor = Colors.transparent,
    required this.icon,
  }) : text = null;

  const CircularStatusIndicator.text({
    super.key,
    this.accentColor = Colors.transparent,
    required this.text,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Center(
        child: (text != null)
            ? Text(
                text!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 24),
      ),
    );
  }
}
