import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';

abstract class StorageRepository {
  Future<StorageInfo> getStorageInfo();
  Future<List<Category>> getCategories();
  Future<void> analyzeStorage();
  Future<StorageAnalysisResults> performDeepAnalysis();
}
