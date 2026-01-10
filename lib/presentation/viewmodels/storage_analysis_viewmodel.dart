import 'dart:async';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_use_case.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// ViewModel for storage analysis following MVVM pattern
/// Only coordinates between UI and use cases - no business logic
class StorageAnalysisViewModel {
  final AnalyzeStorageUseCase _analyzeStorageUseCase;

  StorageAnalysisViewModel(this._analyzeStorageUseCase);

  Future<StorageAnalysisResults> performDeepAnalysis() async {
    try {
      Logger.info("StorageAnalysisViewModel: Initiating deep analysis...");

      // Delegate to use case - no business logic here
      final results = await _analyzeStorageUseCase.execute();

      Logger.success(
        "StorageAnalysisViewModel: Analysis completed successfully",
      );
      return results;
    } catch (e) {
      Logger.error('StorageAnalysisViewModel: Failed to perform analysis', e);
      rethrow;
    }
  }

  /// Perform deep analysis with progress reporting
  Future<StorageAnalysisResults> performDeepAnalysisWithProgress({
    required void Function(double progress, String message) onProgress,
    CancellationToken? cancellationToken,
  }) async {
    try {
      Logger.info("StorageAnalysisViewModel: Initiating deep analysis with progress...");

      // Report initial progress
      onProgress(0.0, 'Initializing storage analysis...');

      // Check if cancelled
      if (cancellationToken?.isCancelled == true) {
        throw Exception('Analysis cancelled');
      }

      // Small delay to show initialization
      await Future.delayed(const Duration(milliseconds: 300));
      onProgress(0.1, 'Checking storage permissions...');
      
      // Progress steps with proper timing
      final progressSteps = [
        (0.2, 'Scanning cache files...', 800),
        (0.3, 'Scanning temporary files...', 700),
        (0.4, 'Analyzing images...', 900),
        (0.5, 'Analyzing videos...', 1000),
        (0.6, 'Analyzing documents...', 800),
        (0.7, 'Finding duplicate files...', 1200),
        (0.8, 'Calculating large files...', 900),
        (0.9, 'Finalizing analysis...', 600),
      ];
      
      // Start the actual analysis task
      final analysisCompleter = Completer<StorageAnalysisResults>();
      final analysisTask = _analyzeStorageUseCase.execute();
      
      // Complete when analysis is done
      analysisTask.then((result) {
        if (!analysisCompleter.isCompleted) {
          analysisCompleter.complete(result);
        }
      }).catchError((error) {
        if (!analysisCompleter.isCompleted) {
          analysisCompleter.completeError(error);
        }
      });
      
      // Simulate progress updates
      bool analysisComplete = false;
      int currentStep = 0;
      
      // Progress simulation with proper timing
      while (currentStep < progressSteps.length && !analysisComplete) {
        if (cancellationToken?.isCancelled == true) {
          throw Exception('Analysis cancelled');
        }
        
        final (progress, message, duration) = progressSteps[currentStep];
        onProgress(progress, message);
        Logger.debug('Analysis progress: ${(progress * 100).toInt()}% - $message');
        currentStep++;
        
        // Wait for the specified duration or until analysis completes
        await Future.any([
          Future.delayed(Duration(milliseconds: duration)),
          analysisCompleter.future.then((_) => analysisComplete = true),
        ]);
      }
      
      // If analysis is still running, show waiting state
      if (!analysisComplete) {
        onProgress(0.95, 'Completing analysis...');
        Logger.debug('Waiting for analysis to complete...');
      }
      
      // Wait for the actual result (timeout handled by TimeoutService in Cubit)
      final results = await analysisCompleter.future;
      
      // Report completion
      onProgress(1.0, 'Analysis complete!');
      Logger.success(
        "StorageAnalysisViewModel: Analysis completed successfully with progress",
      );
      
      // Small delay to show 100% before navigation
      await Future.delayed(const Duration(milliseconds: 500));
      
      return results;
    } catch (e) {
      Logger.error('StorageAnalysisViewModel: Failed to perform analysis', e);
      // Ensure we report the error state
      if (e is! Exception || !e.toString().contains('cancelled')) {
        onProgress(0.0, 'Analysis failed');
      }
      rethrow;
    }
  }
}

/// Extension for CancellationToken proper implementation
extension CancellationTokenExtension on CancellationToken? {
  bool get isCancelled {
    // Use the actual isCancelled property from CancellationToken
    return this?.isCancelled ?? false;
  }
}
