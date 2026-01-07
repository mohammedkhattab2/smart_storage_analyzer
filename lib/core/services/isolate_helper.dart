import 'dart:async';
import 'dart:isolate';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Helper class for running heavy operations in isolates
/// This prevents UI thread blocking and ANR issues
class IsolateHelper {
  /// Run a computation in an isolate with progress updates
  static Future<T> runWithProgress<T, P>({
    required IsolateComputeFunction<T, P> computation,
    required P parameter,
    void Function(double progress, String message)? onProgress,
  }) async {
    Logger.info('Starting isolate computation...');
    
    // Create a receive port for communication
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    
    // Create progress port for receiving progress updates
    final progressPort = ReceivePort();
    
    try {
      // Spawn the isolate
      final isolate = await Isolate.spawn(
        _isolateEntryPoint<T, P>,
        _IsolateData(
          computation: computation,
          parameter: parameter,
          sendPort: receivePort.sendPort,
          progressPort: progressPort.sendPort,
        ),
        onError: errorPort.sendPort,
        errorsAreFatal: true,
      );

      // Set up progress listener
      final progressSubscription = progressPort.listen((message) {
        if (message is _ProgressMessage && onProgress != null) {
          onProgress(message.progress, message.message);
        }
      });

      // Set up error listener
      final errorSubscription = errorPort.listen((error) {
        Logger.error('Isolate error: $error');
      });

      // Wait for computation result
      final completer = Completer<T>();
      final subscription = receivePort.listen((message) {
        if (message is T) {
          completer.complete(message);
        } else if (message is _IsolateError) {
          completer.completeError(Exception(message.error));
        }
      });

      try {
        final result = await completer.future;
        Logger.success('Isolate computation completed');
        return result;
      } finally {
        // Clean up
        subscription.cancel();
        progressSubscription.cancel();
        errorSubscription.cancel();
        receivePort.close();
        errorPort.close();
        progressPort.close();
        isolate.kill(priority: Isolate.immediate);
      }
    } catch (e) {
      Logger.error('Failed to run isolate computation', e);
      rethrow;
    }
  }

  /// Simple isolate computation without progress
  static Future<T> compute<T, P>({
    required IsolateComputeFunction<T, P> computation,
    required P parameter,
  }) async {
    return runWithProgress(
      computation: computation,
      parameter: parameter,
    );
  }

  /// Entry point for the isolate
  static void _isolateEntryPoint<T, P>(_IsolateData<T, P> data) async {
    try {
      // Set up progress reporting
      _progressReporter = (progress, message) {
        data.progressPort.send(_ProgressMessage(progress, message));
      };

      // Run the computation
      final result = await data.computation(data.parameter);
      
      // Send result back to main isolate
      data.sendPort.send(result);
    } catch (e, stackTrace) {
      // Send error back to main isolate
      data.sendPort.send(
        _IsolateError(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
  }

  /// Run batch processing with cancellation support
  static Future<T> runBatchProcess<T>({
    required BatchProcessor<T> processor,
    CancellationToken? cancellationToken,
  }) async {
    final receivePort = ReceivePort();
    final cancelPort = ReceivePort();
    
    try {
      final isolate = await Isolate.spawn(
        _batchProcessorEntryPoint<T>,
        _BatchProcessData(
          processor: processor,
          sendPort: receivePort.sendPort,
          cancelPort: cancelPort.sendPort,
        ),
      );

      // Set up cancellation listener
      if (cancellationToken != null) {
        cancellationToken.onCancel = () {
          cancelPort.sendPort.send('cancel');
          isolate.kill(priority: Isolate.immediate);
        };
      }

      final completer = Completer<T>();
      receivePort.listen((message) {
        if (message is T) {
          completer.complete(message);
        } else if (message is _IsolateError) {
          completer.completeError(Exception(message.error));
        }
      });

      return await completer.future;
    } finally {
      receivePort.close();
      cancelPort.close();
    }
  }

  static void _batchProcessorEntryPoint<T>(_BatchProcessData<T> data) async {
    final cancelReceiver = ReceivePort();
    data.cancelPort.send(cancelReceiver.sendPort);
    
    bool isCancelled = false;
    cancelReceiver.listen((_) {
      isCancelled = true;
    });

    try {
      final result = await data.processor.process(() => isCancelled);
      if (!isCancelled) {
        data.sendPort.send(result);
      }
    } catch (e, stackTrace) {
      data.sendPort.send(
        _IsolateError(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
  }
}

/// Function signature for isolate computations
typedef IsolateComputeFunction<T, P> = FutureOr<T> Function(P parameter);

/// Function to report progress from isolate
typedef ProgressReporter = void Function(double progress, String message);

/// Global progress reporter for use inside isolate computations
ProgressReporter? _progressReporter;

/// Report progress from within an isolate computation
void reportProgress(double progress, String message) {
  _progressReporter?.call(progress, message);
}

/// Base class for batch processors
abstract class BatchProcessor<T> {
  /// Process data in batches with cancellation check
  Future<T> process(bool Function() isCancelled);
}

/// Cancellation token for batch operations
class CancellationToken {
  void Function()? onCancel;
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
    onCancel?.call();
  }
}

/// Internal data structure for isolate communication
class _IsolateData<T, P> {
  final IsolateComputeFunction<T, P> computation;
  final P parameter;
  final SendPort sendPort;
  final SendPort progressPort;

  _IsolateData({
    required this.computation,
    required this.parameter,
    required this.sendPort,
    required this.progressPort,
  });
}

/// Internal data structure for batch processing
class _BatchProcessData<T> {
  final BatchProcessor<T> processor;
  final SendPort sendPort;
  final SendPort cancelPort;

  _BatchProcessData({
    required this.processor,
    required this.sendPort,
    required this.cancelPort,
  });
}

/// Progress message structure
class _ProgressMessage {
  final double progress;
  final String message;

  _ProgressMessage(this.progress, this.message);
}

/// Error message structure
class _IsolateError {
  final String error;
  final String stackTrace;

  _IsolateError({required this.error, required this.stackTrace});
}

/// Chunked data processor for handling large datasets
class ChunkedProcessor<T, R> {
  final List<T> items;
  final int chunkSize;
  final Future<R> Function(List<T> chunk, int chunkIndex) processChunk;
  final R Function(List<R> results) combineResults;

  ChunkedProcessor({
    required this.items,
    required this.chunkSize,
    required this.processChunk,
    required this.combineResults,
  });

  /// Process data in chunks with progress reporting
  Future<R> process({
    void Function(double progress, String message)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final results = <R>[];
    final totalChunks = (items.length / chunkSize).ceil();
    
    for (int i = 0; i < totalChunks; i++) {
      if (isCancelled?.call() == true) {
        throw Exception('Operation cancelled');
      }

      final start = i * chunkSize;
      final end = (start + chunkSize > items.length) 
          ? items.length 
          : start + chunkSize;
      
      final chunk = items.sublist(start, end);
      final result = await processChunk(chunk, i);
      results.add(result);

      final progress = (i + 1) / totalChunks;
      onProgress?.call(
        progress,
        'Processing chunk ${i + 1} of $totalChunks',
      );
    }

    return combineResults(results);
  }
}

/// Platform channel communication helper for isolates
class IsolateMethodChannel {
  /// Call method channel from isolate using platform channel proxy
  /// Note: Direct platform channel calls from isolates are not supported
  /// This should be called from the main isolate only
  static Future<T> invokeMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    // Platform channels cannot be directly called from isolates
    // The computation should return data that can be processed
    // in the main isolate where platform channels are available
    throw UnsupportedError(
      'Platform channels cannot be called directly from isolates. '
      'Return the data from isolate and call platform methods in main thread.',
    );
  }
}

/// Extension for running heavy operations in isolates
extension IsolateExtension<T> on Future<T> Function() {
  /// Run this function in an isolate
  Future<T> runInIsolate() async {
    return IsolateHelper.compute(
      computation: (_) => this(),
      parameter: null,
    );
  }
}