/// Validation helpers for authentication inputs.
///
/// These validators enforce the strict security requirements
/// defined in the application specification.

/// Validates an email address format.
///
/// Returns null if valid, or an error message if invalid.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }

  // RFC 5322 compliant email regex pattern
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address';
  }

  return null;
}

/// Validates a password against security requirements.
///
/// Requirements:
/// - Minimum 8 characters
/// - At least one uppercase letter
/// - At least one lowercase letter
/// - At least one number
///
/// Returns null if valid, or an error message if invalid.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }

  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Password must contain at least one uppercase letter';
  }

  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Password must contain at least one lowercase letter';
  }

  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Password must contain at least one number';
  }

  return null;
}

/// Validates that confirm password matches the original password.
///
/// Returns null if valid, or an error message if invalid.
String? validateConfirmPassword(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Please confirm your password';
  }

  if (password != confirmPassword) {
    return 'Passwords do not match';
  }

  return null;
}

/// Validates a field is not empty.
///
/// Returns null if valid, or an error message if invalid.
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}
