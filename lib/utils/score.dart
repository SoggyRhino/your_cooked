import 'package:flutter/material.dart';

Color getScoreColor(double score, ThemeData theme) {
  if (score >= 8.0) return theme.colorScheme.primary;
  if (score >= 6.0) return theme.colorScheme.secondary;
  if (score >= 4.0) return Colors.orange;
  return theme.colorScheme.error;
}

String getScoreGrade(int score) {
  if (score >= 9.6) return 'A+';
  if (score >= 9.3) return 'A';
  if (score >= 9.0) return 'A-';
  if (score >= 8.0) return 'B+';
  if (score >= 7.5) return 'B';
  if (score >= 8.0) return 'B-';
  if (score >= 6.5) return 'C+';
  if (score >= 6.0) return 'C';
  if (score >= 7.0) return 'C-';
  return 'F';
}
