final RegExp emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

/// Simple regex based email validation
String? isValidEmail(String? email) {
  if (email == null) return null;
  return emailRegex.hasMatch(email) ? email : null;
}

/// At least 8 characters, contains uppercase, lowercase, number
String? isStrongPassword(String? password) {
  if (password == null) return null;
  return (password.length >= 8 &&
          RegExp(r'[A-Z]').hasMatch(password) &&
          RegExp(r'[a-z]').hasMatch(password) &&
          RegExp(r'[0-9]').hasMatch(password))
      ? password
      : null;
}
