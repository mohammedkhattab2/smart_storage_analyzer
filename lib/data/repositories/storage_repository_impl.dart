import 'package:smart_storage_analyzer/core/constants/storage_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/category_model.dart';
import 'package:smart_storage_analyzer/data/models/storage_info_model.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  @override
  Future<void> analyzeStorage() async {
    try {
      Logger.info("Starting storage analysis...");
      await Future.delayed(Duration(seconds: 3));
      Logger.success('Storage analysis completed');
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      Logger.info('Getting categories...');
      await Future.delayed(Duration(milliseconds: 500));
      return CategoryModel.getDefaultCategories();
    } catch (e) {
      Logger.error('Failed to get categories', e);
      rethrow;
    }
  }

  @override
  Future<StorageInfo> getStorageInfo() async {
    try {
      Logger.info("Getting storage info...");
      await Future.delayed(Duration(seconds: 1));
      return StorageInfoModel(
        totalSpace: StorageConstants.mockTotalSpace * 1024 * 1024 * 1024,
        usedSpace: StorageConstants.mockUsedSpace.toDouble(),
        freeSpace: StorageConstants.mockFreeSpace * 1024 * 1024 * 1024,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Failed to get storage info', e);
      rethrow;
    }
  }
}
