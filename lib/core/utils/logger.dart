import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[LOG] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('[ERROR] $message: $error');
      } else {
        debugPrint('[ERROR] $message');
      }
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] $message');
    }
  }
}
