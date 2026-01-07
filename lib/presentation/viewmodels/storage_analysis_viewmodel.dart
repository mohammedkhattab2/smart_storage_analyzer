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

      onProgress(0.1, 'Checking storage permissions...');
      
      // Execute the analysis with progress reporting
      // Note: Since we can't directly pass progress to the use case,
      // we simulate progress based on time estimation
      final analysisTask = _analyzeStorageUseCase.execute();
      
      // Create a timer to simulate progress updates
      final progressSteps = [
        (0.2, 'Scanning cache files...'),
        (0.3, 'Scanning temporary files...'),
        (0.4, 'Analyzing images...'),
        (0.5, 'Analyzing videos...'),
        (0.6, 'Analyzing documents...'),
        (0.7, 'Finding duplicate files...'),
        (0.8, 'Calculating large files...'),
        (0.9, 'Finalizing analysis...'),
      ];
      
      int currentStep = 0;
      while (!analysisTask.isCompleted && currentStep < progressSteps.length) {
        if (cancellationToken?.isCancelled == true) {
          throw Exception('Analysis cancelled');
        }
        
        final (progress, message) = progressSteps[currentStep];
        onProgress(progress, message);
        currentStep++;
        
        // Wait a bit before next progress update
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Wait for the actual result
      final results = await analysisTask;
      
      // Final progress
      onProgress(1.0, 'Analysis complete!');
      
      Logger.success(
        "StorageAnalysisViewModel: Analysis completed successfully with progress",
      );
      return results;
    } catch (e) {
      Logger.error('StorageAnalysisViewModel: Failed to perform analysis', e);
      rethrow;
    }
  }
}

/// Extension to check if a Future is completed
extension FutureExtension<T> on Future<T> {
  bool get isCompleted {
    var completed = false;
    then((_) => completed = true);
    return completed;
  }

  /// Getter for cancellation status
  bool get isCancelled => false;
}

/// Extension for CancellationToken
extension CancellationTokenExtension on CancellationToken? {
  bool get isCancelled {
    // Simple cancellation check
    var cancelled = false;
    this?.onCancel = () => cancelled = true;
    return cancelled;
  }
}
