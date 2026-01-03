import 'package:flutter/foundation.dart';

class Logger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';

  /// Log info
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_blue[INFO]$_reset $message');
      if (data != null) print(data);
    }
  }

  /// Log success
  static void success(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_green[SUCCESS]$_reset $message');
      if (data != null) print(data);
    }
  }

  /// Log warning
  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_yellow[WARNING]$_reset $message');
      if (data != null) print(data);
    }
  }

  /// Log error
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_red[ERROR]$_reset $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  /// Log network (للمستقبل)
  static void network(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_magenta[NETWORK]$_reset $message');
      if (data != null) print(data);
    }
  }
}
