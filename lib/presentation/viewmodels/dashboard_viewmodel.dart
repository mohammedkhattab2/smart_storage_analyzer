
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';

/// ViewModel for Dashboard screen following MVVM pattern
/// Handles all business logic and data operations
class DashboardViewModel {
  final GetStorageInfoUsecase _getStorageInfoUsecase;
  final GetCategoriesUsecase _getCategoriesUsecase;
  final AnalyzeStorageUsecase _analyzeStorageUsecase;
  final _permissionService = PermissionService();

  DashboardViewModel({
    required GetStorageInfoUsecase getStorageInfoUsecase,
    required GetCategoriesUsecase getCategoriesUsecase,
    required AnalyzeStorageUsecase analyzeStorageUsecase,
  })  : _getStorageInfoUsecase = getStorageInfoUsecase,
        _getCategoriesUsecase = getCategoriesUsecase,
        _analyzeStorageUsecase = analyzeStorageUsecase;

  /// Load dashboard data (storage info and categories)
  Future<DashboardData> loadDashboardData({BuildContext? context}) async {
    try {
      Logger.info("Loading dashboard data...");

      // Check storage permission
      final hasPermission = await checkStoragePermission(context: context);
      if (!hasPermission) {
        throw PermissionException(
          'Storage permission is required to analyze your device storage',
        );
      }

      // Load data in parallel
      final results = await Future.wait([
        _getStorageInfoUsecase.excute(),
        _getCategoriesUsecase.excute(),
      ]);

      final storageInfo = results[0] as StorageInfo;
      final categories = results[1] as List<Category>;

      Logger.success("Dashboard data loaded successfully");

      return DashboardData(
        storageInfo: storageInfo,
        categories: categories,
      );
    } catch (e) {
      Logger.error('Failed to load dashboard data', e);
      rethrow;
    }
  }

  /// Analyze storage
  Future<void> analyzeStorage() async {
    try {
      Logger.info("Starting storage analysis...");
      await _analyzeStorageUsecase.excute();
      Logger.success("Storage analysis completed");
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      rethrow;
    }
  }

  /// Check and request storage permission
  Future<bool> checkStoragePermission({BuildContext? context}) async {
    try {
      // Skip permission check in debug mode
      if (kDebugMode) {
        Logger.info('Debug mode: Skipping permission check');
        return true;
      }

      // Use centralized permission service
      return await _permissionService.requestStoragePermission(context: context);
    } catch (e) {
      Logger.warning('Permission check failed: $e');
      return true;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    try {
      return await _permissionService.requestStoragePermission(context: context);
    } catch (e) {
      Logger.error('Failed to request permission', e);
      return false;
    }
  }
}

/// Data class for dashboard information
class DashboardData {
  final StorageInfo storageInfo;
  final List<Category> categories;

  DashboardData({
    required this.storageInfo,
    required this.categories,
  });
}

/// Exception for permission errors
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => message;
}
