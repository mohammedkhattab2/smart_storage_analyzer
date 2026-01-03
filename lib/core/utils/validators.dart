class Validators {
  Validators._();

  /// Validate file name
  static String? validateFileName(String? value) {
    if (value == null || value.isEmpty) {
      return 'File name cannot be empty';
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(value)) {
      return 'File name contains invalid characters';
    }

    return null;
  }

  /// Validate size input
  static String? validateSize(String? value) {
    if (value == null || value.isEmpty) {
      return 'Size cannot be empty';
    }

    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return 'Invalid size value';
    }

    return null;
  }

  /// Validate email (للـ sign in المستقبلي)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }
}
