import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Use case for performing deep storage analysis
/// Following Clean Architecture principles
class AnalyzeStorageUseCase {
  final StorageRepository _repository;

  AnalyzeStorageUseCase(this._repository);

  Future<StorageAnalysisResults> execute() async {
    try {
      Logger.info("Executing storage analysis use case...");

      // Delegate to repository which handles the actual implementation
      final results = await _repository.performDeepAnalysis();

      Logger.success("Storage analysis completed successfully");
      return results;
    } catch (e) {
      Logger.error('Failed to analyze storage in use case', e);
      rethrow;
    }
  }
}
