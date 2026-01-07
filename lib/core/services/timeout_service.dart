import 'dart:async';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service for managing timeouts across the application
class TimeoutService {
  // Timeout durations
  static const Duration fileAnalysisTimeout = Duration(minutes: 5);
  static const Duration statisticsTimeout = Duration(seconds: 30);
  static const Duration fileScanTimeout = Duration(minutes: 3);
  static const Duration cleanupTimeout = Duration(minutes: 10);
  
  /// Execute an operation with timeout
  static Future<T?> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    String? operationName,
    T? fallbackValue,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          final name = operationName ?? 'Operation';
          Logger.warning('$name timed out after ${timeout.inSeconds} seconds');
          
          if (fallbackValue != null) {
            return fallbackValue;
          }
          
          throw TimeoutException(
            '$name exceeded timeout of ${timeout.inSeconds} seconds',
            timeout,
          );
        },
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      Logger.error('Error in timeout operation', e);
      rethrow;
    }
  }

  /// Execute with retry on timeout
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await executeWithTimeout(
          operation: operation,
          timeout: timeout,
          operationName: operationName,
        );
      } on TimeoutException {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        Logger.info(
          '${operationName ?? 'Operation'} timeout. '
          'Retry $attempts of $maxRetries after ${retryDelay.inSeconds}s',
        );
        
        await Future.delayed(retryDelay);
      }
    }
    
    return null;
  }

  /// Execute with progress timeout (resets on progress)
  static Future<T?> executeWithProgressTimeout<T>({
    required Future<T> Function(Function(double) updateProgress) operation,
    required Duration timeout,
    String? operationName,
  }) async {
    final completer = Completer<T>();
    Timer? timeoutTimer;
    bool isCompleted = false;
    
    // Reset timeout on progress
    void resetTimeout() {
      timeoutTimer?.cancel();
      
      if (!isCompleted) {
        timeoutTimer = Timer(timeout, () {
          if (!isCompleted) {
            isCompleted = true;
            completer.completeError(
              TimeoutException(
                '${operationName ?? 'Operation'} timed out (no progress)',
                timeout,
              ),
            );
          }
        });
      }
    }
    
    // Start initial timeout
    resetTimeout();
    
    // Progress callback that resets timeout
    void onProgress(double progress) {
      Logger.debug('${operationName ?? 'Operation'} progress: ${(progress * 100).toInt()}%');
      resetTimeout();
    }
    
    try {
      final result = await operation(onProgress);
      isCompleted = true;
      timeoutTimer?.cancel();
      
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      
      return result;
    } catch (e) {
      isCompleted = true;
      timeoutTimer?.cancel();
      
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      
      rethrow;
    }
  }
}

/// Custom timeout exception with additional context
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  final DateTime occurredAt;

  TimeoutException(this.message, this.timeout) : occurredAt = DateTime.now();

  @override
  String toString() => 'TimeoutException: $message at $occurredAt';
}