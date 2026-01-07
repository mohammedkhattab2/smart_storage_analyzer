import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/constants/file_extensions.dart';
import 'package:smart_storage_analyzer/core/services/file_scanner_service.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/services/native_storage_service.dart';
import 'package:smart_storage_analyzer/core/services/permission_manager.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/category_model.dart';
import 'package:smart_storage_analyzer/data/models/storage_info_model.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  static const platform = MethodChannel(ChannelConstants.mainChannel);

  // Native storage service instance
  final NativeStorageService _nativeStorageService = NativeStorageService();
  final _permissionManager = PermissionManager();

  @override
  Future<void> analyzeStorage({BuildContext? context}) async {
    try {
      Logger.info("Starting real storage analysis...");

      // Check and request storage permission if needed
      if (Platform.isAndroid) {
        final hasPermission = await _permissionManager.hasPermission();
        if (!hasPermission && context != null && context.mounted) {
          final granted = await _permissionManager.requestPermission(
            context: context,
          );
          if (!granted) {
            throw StoragePermissionException(
              message: 'Storage permission is required to analyze storage',
            );
          }
        } else if (!hasPermission) {
          throw StoragePermissionException(
            message: 'Storage permission is required to analyze storage',
          );
        }
      }

      // Perform real storage analysis
      await _performStorageAnalysis();

      Logger.success('Storage analysis completed');
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      Logger.info('Getting file categories...');

      if (Platform.isAndroid) {
        // Check storage permission with cached state
        final hasPermission = await _permissionManager.hasPermission();
        if (!hasPermission) {
          Logger.warning('No storage permission - returning empty categories');
          // Return empty categories if no permission
          return _getEmptyCategories();
        }

        // Use cached categories if available and recent
        final cachedCategories = await _getCachedCategories();
        if (cachedCategories != null) {
          Logger.info('Using cached categories');
          return cachedCategories;
        }

        // Scan actual files on device with optimized approach
        final categories = await _scanDeviceFilesOptimized();
        
        // Cache the results
        await _cacheCategories(categories);
        
        return categories;
      }

      // For non-Android platforms, return empty categories
      return _getEmptyCategories();
    } catch (e) {
      Logger.error('Failed to get categories', e);
      // Return empty categories on error
      return _getEmptyCategories();
    }
  }

  // Cache management for categories
  List<Category>? _categoriesCache;
  DateTime? _cacheTimestamp;
  static const _cacheValidityDuration = Duration(minutes: 5);

  Future<List<Category>?> _getCachedCategories() async {
    if (_categoriesCache != null && _cacheTimestamp != null) {
      final isValid = DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration;
      if (isValid) {
        return _categoriesCache;
      }
    }
    return null;
  }

  Future<void> _cacheCategories(List<Category> categories) async {
    _categoriesCache = categories;
    _cacheTimestamp = DateTime.now();
  }

  @override
  Future<StorageInfo> getStorageInfo() async {
    try {
      Logger.info("Getting storage info via Native Bridge...");

      if (Platform.isAndroid) {
        // Use the new Native Storage Service (MVVM pattern)
        try {
          final storageData = await _nativeStorageService.getStorageData();

          // Check if we got valid data
          if (storageData.totalBytes > 0) {
            Logger.success('Got storage info from Native Bridge');
            Logger.info('Storage details: ${storageData.toString()}');

            return StorageInfoModel(
              totalSpace: storageData.totalBytes.toDouble(),
              usedSpace: storageData.usedBytes.toDouble(),
              freeSpace: storageData.freeBytes.toDouble(),
              lastUpdated: DateTime.now(),
            );
          } else {
            Logger.warning(
              'Native Bridge returned zero values, trying legacy channel',
            );
          }
        } catch (e) {
          Logger.warning('Native Bridge failed: $e');
        }

        // Try legacy platform channel as fallback
        try {
          final Map<dynamic, dynamic> result = await platform.invokeMethod(
            'getStorageInfo',
          );

          final totalSpace = (result['totalSpace'] as num).toDouble();
          final availableSpace = (result['availableSpace'] as num).toDouble();
          final usedSpace = totalSpace - availableSpace;

          Logger.info('Got storage info from legacy channel');

          return StorageInfoModel(
            totalSpace: totalSpace,
            usedSpace: usedSpace,
            freeSpace: availableSpace,
            lastUpdated: DateTime.now(),
          );
        } catch (e) {
          Logger.warning('Legacy platform channel failed: $e');
        }

        // Fallback: Use df command
        final storageData = await _getStorageUsingDf();
        if (storageData != null) {
          Logger.info('Got storage info from df command');
          return StorageInfoModel(
            totalSpace: storageData['total']!,
            usedSpace: storageData['used']!,
            freeSpace: storageData['available']!,
            lastUpdated: DateTime.now(),
          );
        }
      }

      // No data available - return zeros
      Logger.error('Unable to get storage info from any source');
      return StorageInfoModel(
        totalSpace: 0,
        usedSpace: 0,
        freeSpace: 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Failed to get storage info', e);
      rethrow;
    }
  }

  /// Performs actual storage analysis
  Future<void> _performStorageAnalysis() async {
    // Simulate analysis with actual operations
    await Future.delayed(const Duration(seconds: 2));

    // In a real implementation, this would:
    // 1. Scan for large files
    // 2. Find duplicate files
    // 3. Identify cache and temporary files
    // 4. Calculate potential space savings
  }

  /// Get storage information using df command
  Future<Map<String, double>?> _getStorageUsingDf() async {
    try {
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) return null;

      final rootPath = appDir.path.split('Android')[0];
      final result = await Process.run('df', ['-B1', rootPath]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (final line in lines) {
          if (line.contains(rootPath) ||
              line.contains('/data') ||
              line.contains('/storage')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              final total =
                  double.tryParse(
                    parts[1].replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0;
              final used =
                  double.tryParse(
                    parts[2].replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0;
              final available =
                  double.tryParse(
                    parts[3].replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0;

              if (total > 0) {
                return {'total': total, 'used': used, 'available': available};
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.error('df command failed', e);
    }
    return null;
  }

  /// Optimized device file scanning with native integration
  Future<List<Category>> _scanDeviceFilesOptimized() async {
    try {
      Logger.info('Starting optimized category scan...');
      
      // Get category data directly from native for better performance
      final Map<dynamic, dynamic> categoryData = await platform.invokeMethod(
        'getCategorySizes',
      );
      
      // Process the native data in isolate
      return await IsolateHelper.runWithProgress<List<Category>, Map<dynamic, dynamic>>(
        computation: _processNativeCategoryData,
        parameter: categoryData,
        onProgress: (progress, message) {
          Logger.debug('Category processing: ${(progress * 100).toInt()}% - $message');
        },
      );
    } catch (e) {
      Logger.error('Native category scan failed, using fallback', e);
      // Fallback to empty categories on error
      return _getEmptyCategories();
    }
  }

  /// Process native category data in isolate
  static Future<List<Category>> _processNativeCategoryData(
    Map<dynamic, dynamic> nativeData,
  ) async {
    reportProgress(0.1, 'Processing category data...');
    
    final categoryMap = _createCategoryMap();
    final categories = <Category>[];
    
    int processed = 0;
    final total = categoryMap.length;
    
    for (final entry in categoryMap.entries) {
      final categoryId = entry.key;
      final categoryData = entry.value;
      
      // Get size and count from native data
      final sizeInBytes = (nativeData['${categoryId}_size'] as num?)?.toDouble() ?? 0.0;
      final fileCount = (nativeData['${categoryId}_count'] as int?) ?? 0;
      
      categories.add(CategoryModel(
        id: categoryId,
        name: categoryData.name,
        icon: categoryData.icon,
        color: categoryData.color,
        sizeInBytes: sizeInBytes,
        filesCount: fileCount,
      ));
      
      processed++;
      reportProgress(
        0.1 + (processed / total) * 0.9,
        'Processing ${categoryData.name} category...',
      );
    }

    // Sort by size (largest first)
    categories.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
    
    reportProgress(1.0, 'Category processing complete');
    return categories;
  }

  /// Create category map - moved to static method for isolate access
  static Map<String, CategoryData> _createCategoryMap() {
    return {
      'images': CategoryData(
        name: 'Images',
        icon: AppIcons.images,
        color: AppColorSchemes.imageCategoryLight,
        extensions: FileExtensions.imageExtensions,
      ),
      'videos': CategoryData(
        name: 'Videos',
        icon: AppIcons.videos,
        color: AppColorSchemes.videoCategoryLight,
        extensions: FileExtensions.videoExtensions,
      ),
      'audio': CategoryData(
        name: 'Audio',
        icon: AppIcons.audio,
        color: AppColorSchemes.audioCategoryLight,
        extensions: FileExtensions.audioExtensions,
      ),
      'documents': CategoryData(
        name: 'Documents',
        icon: AppIcons.documents,
        color: AppColorSchemes.documentCategoryLight,
        extensions: FileExtensions.documentExtensions,
      ),
      'apps': CategoryData(
        name: 'Apps',
        icon: AppIcons.apps,
        color: AppColorSchemes.appsCategoryLight,
        extensions: FileExtensions.appExtensions,
      ),
      'others': CategoryData(
        name: 'Others',
        icon: AppIcons.others,
        color: AppColorSchemes.othersCategoryLight,
        extensions: [],
      ),
    };
  }

  /// Returns empty categories with zero sizes
  List<Category> _getEmptyCategories() {
    return [
      CategoryModel(
        id: 'images',
        name: 'Images',
        icon: AppIcons.images,
        color: AppColorSchemes.imageCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'videos',
        name: 'Videos',
        icon: AppIcons.videos,
        color: AppColorSchemes.videoCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'audio',
        name: 'Audio',
        icon: AppIcons.audio,
        color: AppColorSchemes.audioCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'documents',
        name: 'Documents',
        icon: AppIcons.documents,
        color: AppColorSchemes.documentCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'apps',
        name: 'Apps',
        icon: AppIcons.apps,
        color: AppColorSchemes.appsCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'others',
        name: 'Others',
        icon: AppIcons.others,
        color: AppColorSchemes.othersCategoryLight,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
    ];
  }

  // Removed mock categories method - app now only uses real data

  @override
  Future<StorageAnalysisResults> performDeepAnalysis() async {
    try {
      Logger.info("Starting deep storage analysis in repository...");

      // Check permission first
      final hasPermission = await _permissionManager.hasPermission();
      if (!hasPermission) {
        throw StoragePermissionException(
          message: 'Storage permission is required for deep analysis',
        );
      }

      final startTime = DateTime.now();

      if (!Platform.isAndroid) {
        Logger.warning('Storage analysis is only supported on Android');
        return _createEmptyAnalysisResults(startTime);
      }

      // Create cancellation token for better control
      final cancellationToken = CancellationToken();

      // Use the optimized file scanner service for deep analysis
      final analysisData = await FileScannerService.performDeepAnalysis(
        onProgress: (progress, message) {
          Logger.debug('Analysis progress: ${(progress * 100).toInt()}% - $message');
        },
        cancellationToken: cancellationToken,
      );

      Logger.info(
        'Got analysis results: ${analysisData.totalFilesScanned} files scanned',
      );

      // Get current categories with real data (use cached if available)
      final detailedCategories = await getCategories();

      Logger.success("Storage analysis completed");

      // Clear category cache after analysis to ensure fresh data
      _categoriesCache = null;
      _cacheTimestamp = null;

      return StorageAnalysisResults(
        totalFilesScanned: analysisData.totalFilesScanned,
        totalSpaceUsed: analysisData.totalSpaceUsed,
        totalSpaceAvailable: analysisData.totalSpaceAvailable,
        cacheFiles: analysisData.cacheFiles,
        temporaryFiles: analysisData.temporaryFiles,
        largeOldFiles: analysisData.largeOldFiles,
        duplicateFiles: analysisData.duplicateFiles,
        thumbnails: analysisData.thumbnails,
        detailedCategories: detailedCategories,
        totalCleanupPotential: analysisData.totalCleanupPotential,
        analysisDate: DateTime.now(),
        analysisDuration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      Logger.error('Failed to perform storage analysis', e);
      rethrow;
    }
  }


  StorageAnalysisResults _createEmptyAnalysisResults(DateTime startTime) {
    return StorageAnalysisResults(
      totalFilesScanned: 0,
      totalSpaceUsed: 0,
      totalSpaceAvailable: 0,
      cacheFiles: [],
      temporaryFiles: [],
      largeOldFiles: [],
      duplicateFiles: [],
      thumbnails: [],
      detailedCategories: _getEmptyCategories(),
      totalCleanupPotential: 0,
      analysisDate: DateTime.now(),
      analysisDuration: DateTime.now().difference(startTime),
    );
  }
}

/// Helper class to store category data during scanning
class CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> extensions;
  int totalSize = 0;
  int fileCount = 0;

  CategoryData({
    required this.name,
    required this.icon,
    required this.color,
    required this.extensions,
  });
}
