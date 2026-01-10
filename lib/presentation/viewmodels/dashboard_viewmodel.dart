import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/core/services/permission_manager.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/models/permission_request.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_use_case.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';

/// ViewModel for Dashboard screen following MVVM pattern
/// Handles all business logic and data operations
class DashboardViewModel {
  final GetStorageInfoUseCase _getStorageInfoUsecase;
  final GetCategoriesUseCase _getCategoriesUsecase;
  final AnalyzeStorageUseCase _analyzeStorageUsecase;
  final _permissionManager = PermissionManager();
  
  // Cache for dashboard data
  DashboardData? _cachedData;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  DashboardViewModel({
    required GetStorageInfoUseCase getStorageInfoUsecase,
    required GetCategoriesUseCase getCategoriesUsecase,
    required AnalyzeStorageUseCase analyzeStorageUsecase,
  }) : _getStorageInfoUsecase = getStorageInfoUsecase,
       _getCategoriesUsecase = getCategoriesUsecase,
       _analyzeStorageUsecase = analyzeStorageUsecase;

  /// Load dashboard data (storage info and categories)
  Future<DashboardData> loadDashboardData({
    bool forceReload = false,
    bool autoRequestPermission = false,
    Function(PermissionRequest)? onPermissionRequest,
  }) async {
    try {
      // Check if we have valid cached data
      if (!forceReload && _hasCachedData()) {
        Logger.info("Using cached dashboard data");
        return _cachedData!;
      }
      
      Logger.info("Loading dashboard data...");

      // Check storage permission (without automatically requesting)
      final hasPermission = await _permissionManager.hasPermission();
      
      if (!hasPermission) {
        // Only request permission if explicitly told to (e.g., user clicked button)
        if (autoRequestPermission && onPermissionRequest != null) {
          // Use callback to request permission from UI layer
          final request = PermissionRequest(
            type: PermissionType.storage,
            rationale: 'Storage permission is required to analyze your device storage',
          );
          onPermissionRequest(request);
          
          // The UI will handle the actual permission request
          throw PermissionException(
            'Storage permission is required to analyze your device storage',
          );
        } else {
          // Just throw exception without requesting permission
          throw PermissionException(
            'Storage permission is required to analyze your device storage',
          );
        }
      }

      // Load data in parallel
      final results = await Future.wait([
        _getStorageInfoUsecase.excute(),
        _getCategoriesUsecase.excute(),
      ]);

      final storageInfo = results[0] as StorageInfo;
      final categories = results[1] as List<Category>;

      Logger.success("Dashboard data loaded successfully");
      
      // Cache the data
      final data = DashboardData(storageInfo: storageInfo, categories: categories);
      _cachedData = data;
      _lastLoadTime = DateTime.now();

      return data;
    } catch (e) {
      Logger.error('Failed to load dashboard data', e);
      rethrow;
    }
  }
  
  /// Check if cached data is still valid
  bool _hasCachedData() {
    if (_cachedData == null || _lastLoadTime == null) {
      return false;
    }
    
    final age = DateTime.now().difference(_lastLoadTime!);
    return age < _cacheExpiry;
  }
  
  /// Clear cached data
  void clearCache() {
    _cachedData = null;
    _lastLoadTime = null;
  }

  /// Analyze storage
  Future<void> analyzeStorage() async {
    try {
      Logger.info("Starting storage analysis...");
      // The new use case returns StorageAnalysisResults, not void
      // For now, just execute it - the results will be used in storage analysis screen
      await _analyzeStorageUsecase.execute();
      Logger.success("Storage analysis completed");
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      rethrow;
    }
  }

  /// Check storage permission
  Future<bool> checkStoragePermission() async {
    try {
      // Only check permission status, don't request
      final hasPermission = await _permissionManager.hasPermission();
      return hasPermission;
    } catch (e) {
      Logger.warning('Permission check failed: $e');
      return false;
    }
  }
  
  /// Dispose resources (if any future resources need cleanup)
  void dispose() {
    // Currently no resources to dispose, but method added for future use
    // and consistency with other ViewModels
  }
}

/// Data class for dashboard information
class DashboardData {
  final StorageInfo storageInfo;
  final List<Category> categories;

  DashboardData({required this.storageInfo, required this.categories});
}

/// Exception for permission errors
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => message;
}
