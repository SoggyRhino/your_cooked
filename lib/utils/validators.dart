final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

/// Simple regex based email validation
bool isValidEmail(String email) {
  return emailRegex.hasMatch(email);
}

/// At least 8 characters, contains uppercase, lowercase, number
bool isStrongPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);
}
