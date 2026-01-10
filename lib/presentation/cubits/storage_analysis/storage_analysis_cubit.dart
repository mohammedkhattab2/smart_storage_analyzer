import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/services/timeout_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/storage_analysis_viewmodel.dart';

part 'storage_analysis_state.dart';

class StorageAnalysisCubit extends Cubit<StorageAnalysisState> {
  final StorageAnalysisViewModel _viewModel;
  CancellationToken? _cancellationToken;
  StreamSubscription? _progressSubscription;
  
  // Cache for analysis results
  StorageAnalysisResults? _cachedResults;
  DateTime? _lastAnalysisTime;
  static const Duration _cacheExpiry = Duration(hours: 1);
  bool _isAnalyzing = false;

  StorageAnalysisCubit({required StorageAnalysisViewModel viewModel})
    : _viewModel = viewModel,
      super(StorageAnalysisInitial());

  Future<void> startAnalysis({bool forceRerun = false}) async {
    // Check if analysis is already in progress
    if (_isAnalyzing) {
      Logger.info('[StorageAnalysisCubit] Analysis already in progress, skipping duplicate request');
      return;
    }
    
    // Check if we have valid cached results
    if (!forceRerun && _hasCachedResults()) {
      Logger.info('[StorageAnalysisCubit] Using cached analysis results (cached at: $_lastAnalysisTime)');
      emit(StorageAnalysisCompleted(results: _cachedResults!));
      return;
    }
    
    Logger.info('[StorageAnalysisCubit] Starting fresh analysis (forceRerun: $forceRerun, hasCached: ${_hasCachedResults()})');
    
    // Cancel any previous analysis
    _cancelCurrentAnalysis();
    
    // Create new cancellation token
    _cancellationToken = CancellationToken();
    _isAnalyzing = true;
    
    emit(
      StorageAnalysisInProgress(
        message: 'Preparing to scan storage...',
        progress: 0.0,
      ),
    );

    try {
      // Use TimeoutService with progress timeout
      final results = await TimeoutService.executeWithProgressTimeout<StorageAnalysisResults>(
        operation: (updateProgress) async {
          // Track the last progress to detect stalls
          double lastProgress = 0.0;
          DateTime lastProgressTime = DateTime.now();
          
          return await _viewModel.performDeepAnalysisWithProgress(
            onProgress: (progress, message) {
              if (!isClosed && _cancellationToken?.isCancelled != true) {
                // Update progress for timeout service
                updateProgress(progress);
                
                // Track progress rate for adaptive messaging
                final now = DateTime.now();
                final timeDiff = now.difference(lastProgressTime).inSeconds;
                final progressDiff = progress - lastProgress;
                
                String enhancedMessage = message;
                if (timeDiff > 10 && progressDiff < 0.01) {
                  enhancedMessage = '$message (Processing large files...)';
                }
                
                emit(StorageAnalysisInProgress(
                  message: enhancedMessage,
                  progress: progress,
                ));
                
                lastProgress = progress;
                lastProgressTime = now;
              }
            },
            cancellationToken: _cancellationToken,
          );
        },
        timeout: TimeoutService.fileAnalysisTimeout,
        operationName: 'Storage Analysis',
      );
      
      if (!isClosed) {
        if (_cancellationToken?.isCancelled == true) {
          emit(StorageAnalysisCancelled());
        } else if (results != null) {
          // Cache the results
          _cachedResults = results;
          _lastAnalysisTime = DateTime.now();
          emit(StorageAnalysisCompleted(results: results));
        } else {
          emit(StorageAnalysisError(
            message: 'Analysis completed but no results were found. Please try again.',
          ));
        }
      }
    } catch (e) {
      if (!isClosed) {
        if (e is TimeoutException) {
          emit(
            StorageAnalysisError(
              message: 'Analysis timed out after ${e.timeout.inMinutes} minutes. '
                       'This might happen with very large storage. '
                       'Try analyzing specific folders instead.',
            ),
          );
        } else if (e.toString().contains('cancelled')) {
          emit(StorageAnalysisCancelled());
        } else {
          Logger.error('Storage analysis failed', e);
          emit(
            StorageAnalysisError(
              message: _getErrorMessage(e),
            ),
          );
        }
      }
    } finally {
      _isAnalyzing = false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('permission')) {
      return 'Storage permission required to analyze files';
    } else if (errorStr.contains('timeout')) {
      return 'Analysis took too long. Please try again';
    } else if (errorStr.contains('memory')) {
      return 'Not enough memory. Please close other apps and try again';
    } else {
      return 'Failed to analyze storage. Please try again';
    }
  }


  void cancelAnalysis() {
    Logger.info('User cancelled storage analysis');
    _cancelCurrentAnalysis();
    emit(StorageAnalysisCancelled());
  }

  void _cancelCurrentAnalysis() {
    _cancellationToken?.cancel();
    _cancellationToken = null;
    _progressSubscription?.cancel();
    _progressSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelCurrentAnalysis();
    return super.close();
  }
  
  bool _hasCachedResults() {
    if (_cachedResults == null || _lastAnalysisTime == null) {
      return false;
    }
    
    final age = DateTime.now().difference(_lastAnalysisTime!);
    return age < _cacheExpiry;
  }
  
  void clearCache() {
    _cachedResults = null;
    _lastAnalysisTime = null;
  }
  
  StorageAnalysisResults? getCachedResults() {
    return _hasCachedResults() ? _cachedResults : null;
  }
  
  /// Reset the state to initial
  void resetState() {
    _cancelCurrentAnalysis();
    _isAnalyzing = false;
    emit(StorageAnalysisInitial());
  }
}
