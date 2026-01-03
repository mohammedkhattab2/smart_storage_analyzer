import 'package:flutter/material.dart';

/// Base Error class
abstract class AppError implements Exception {
  final String message;
  final String? code;

  const AppError(this.message, [this.code]);
}

/// Permission Error
class PermissionError extends AppError {
  const PermissionError([String message = 'Permission denied'])
    : super(message, 'PERMISSION_ERROR');
}

/// Storage Error
class StorageError extends AppError {
  const StorageError([String message = 'Storage error occurred'])
    : super(message, 'STORAGE_ERROR');
}

/// File System Error
class FileSystemError extends AppError {
  const FileSystemError([String message = 'File system error'])
    : super(message, 'FILE_ERROR');
}

/// Network Error (للمستقبل)
class NetworkError extends AppError {
  const NetworkError([String message = 'Network error'])
    : super(message, 'NETWORK_ERROR');
}

/// Error Handler
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppError) {
      return error.message;
    } else if (error is Exception) {
      return 'An unexpected error occurred';
    }
    return error.toString();
  }

  /// Show Error Dialog
  static void showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(getErrorMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show Error Snackbar
  static void showErrorSnackbar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
