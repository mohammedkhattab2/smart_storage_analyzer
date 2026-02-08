import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/constants/file_extensions.dart';
import 'package:smart_storage_analyzer/core/services/file_scanner_service.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/services/native_storage_service.dart';
import 'package:smart_storage_analyzer/core/services/permission_manager.dart';
import 'package:smart_storage_analyzer/core/services/document_scanner_service.dart';
import 'package:smart_storage_analyzer/core/services/others_scanner_service.dart';
import 'package:smart_storage_analyzer/core/services/media_scan_cache_service.dart';
import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/data/models/category_model.dart';
import 'package:smart_storage_analyzer/data/models/storage_info_model.dart';
import 'package:smart_storage_analyzer/data/repositories/file_repository_impl.dart';
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
  Future<void> analyzeStorage() async {
    try {
      Logger.info("Starting real storage analysis...");

      // Check storage permission if needed
      if (Platform.isAndroid) {
        final hasPermission = await _permissionManager.hasPermission();
        if (!hasPermission) {
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
      Logger.info('Getting file categories from FileRepository...');

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

        // Calculate categories from FileRepository for consistency
        final categories = await _calculateCategoriesFromFileRepository();
        
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
  
  // Public method to clear cache when needed
  void clearCategoriesCache() {
    _categoriesCache = null;
    _cacheTimestamp = null;
  }

  Future<List<Category>?> _getCachedCategories() async {
    if (_categoriesCache != null && _cacheTimestamp != null) {
      final isValid = DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration;
      if (isValid) {
        // Check if media scan cache has newer data - if so, invalidate our cache
        final mediaCacheService = MediaScanCacheService();
        if (mediaCacheService.hasNewerCacheThan(_cacheTimestamp)) {
          Logger.info('Media scan cache is newer than categories cache - invalidating');
          _categoriesCache = null;
          _cacheTimestamp = null;
          return null;
        }
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

  /// Calculate categories from FileRepository for consistency
  /// This ensures Dashboard/All Categories show the same data as Category Details
  Future<List<Category>> _calculateCategoriesFromFileRepository() async {
    try {
      Logger.info('Calculating categories from FileRepository...');
      
      final categories = <Category>[];
      final categoryMap = _createCategoryMap();
      final mediaCacheService = MediaScanCacheService();
      
      // Calculate each category using the same source as Category Details
      for (final categoryEntry in categoryMap.entries) {
        final categoryId = categoryEntry.key;
        final categoryInfo = categoryEntry.value;
        
        try {
          Logger.info('Calculating $categoryId category...');
          
          // Special handling for media categories - use SAF cache if available
          if (categoryId == 'images' || categoryId == 'videos' || categoryId == 'audio') {
            try {
              MediaType mediaType;
              if (categoryId == 'images') {
                mediaType = MediaType.images;
              } else if (categoryId == 'videos') {
                mediaType = MediaType.videos;
              } else {
                mediaType = MediaType.audio;
              }
              
              final cachedResult = mediaCacheService.getCachedResult(mediaType);
              if (cachedResult != null) {
                categories.add(CategoryModel(
                  id: categoryId,
                  name: categoryInfo.name,
                  sizeInBytes: cachedResult.result.totalSize.toDouble(),
                  filesCount: cachedResult.result.fileCount,
                ));
                Logger.info('$categoryId (SAF Cache): ${cachedResult.result.fileCount} files, ${cachedResult.result.totalSize / (1024 * 1024)} MB');
                continue; // Skip regular scanning for this media category
              } else {
                Logger.info('$categoryId: No SAF cache available, using estimates');
              }
            } catch (e) {
              Logger.warning('Failed to get cached media data for $categoryId: $e');
            }
          }
          
          // Special handling for documents category - use SAF data if available
          if (categoryId == 'documents') {
            try {
              // Use the singleton DocumentScannerService from service locator
              final documentScannerService = sl<DocumentScannerService>();
              
              // Check if folder has been selected
              if (documentScannerService.hasFolderAccess) {
                Logger.info('Documents category: SAF folder access detected');
                
                // Scan documents using SAF
                final safDocuments = await documentScannerService.scanDocuments(useCache: true);
                
                if (safDocuments.isNotEmpty) {
                  // Calculate total size from SAF documents
                  double totalSize = 0;
                  for (final doc in safDocuments) {
                    totalSize += doc.size;
                  }
                  
                  categories.add(CategoryModel(
                    id: categoryId,
                    name: categoryInfo.name,
                    sizeInBytes: totalSize,
                    filesCount: safDocuments.length,
                  ));
                  
                  Logger.info('Documents (SAF): ${safDocuments.length} files, ${totalSize / (1024 * 1024)} MB');
                  continue; // Skip regular scanning for documents
                } else {
                  Logger.info('Documents category: SAF folder selected but no documents found');
                }
              } else {
                Logger.info('Documents category: No SAF folder access');
              }
            } catch (e) {
              Logger.warning('Failed to get SAF documents: $e');
              // Fall back to regular scanning
            }
          }
          
          // Special handling for others category - use SAF data if available
          if (categoryId == 'others') {
            try {
              // Use the singleton OthersScannerService from service locator
              final othersScannerService = sl<OthersScannerService>();
              
              // Check if folder has been selected
              if (othersScannerService.persistedUri != null) {
                Logger.info('Others category: SAF folder access detected');
                
                // Scan others using SAF
                final safOthers = await othersScannerService.scanOthers();
                
                if (safOthers.isNotEmpty) {
                  // Calculate total size from SAF others
                  double totalSize = 0;
                  for (final file in safOthers) {
                    totalSize += file.size;
                  }
                  
                  categories.add(CategoryModel(
                    id: categoryId,
                    name: categoryInfo.name,
                    sizeInBytes: totalSize,
                    filesCount: safOthers.length,
                  ));
                  
                  Logger.info('Others (SAF): ${safOthers.length} files, ${totalSize / (1024 * 1024)} MB');
                  continue; // Skip regular scanning for others
                } else {
                  Logger.info('Others category: SAF folder selected but no files found');
                }
              } else {
                Logger.info('Others category: No SAF folder access');
              }
            } catch (e) {
              Logger.warning('Failed to get SAF others: $e');
              // Fall back to regular scanning
            }
          }
          
          // Regular scanning for all other categories (and documents if SAF not available)
          final files = await FileScannerService.scanFilesByCategory(
            categoryId,
            onProgress: (progress, message) {
              Logger.debug('Calculating $categoryId: ${(progress * 100).toInt()}%');
            },
          );
          
          // Calculate total size
          double totalSize = 0;
          for (final file in files) {
            totalSize += file.sizeInBytes;
          }
          
          categories.add(CategoryModel(
            id: categoryId,
            name: categoryInfo.name,
            sizeInBytes: totalSize,
            filesCount: files.length,
          ));
          
          Logger.info('$categoryId: ${files.length} files, ${totalSize / (1024 * 1024)} MB');
          
        } catch (e) {
          Logger.warning('Failed to calculate $categoryId: $e');
          // Add empty category on error
          categories.add(CategoryModel(
            id: categoryId,
            name: categoryInfo.name,
            sizeInBytes: 0.0,
            filesCount: 0,
          ));
        }
      }
      
      // Sort by size (largest first)
      categories.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
      
      Logger.success('Category calculation completed');
      return categories;
      
    } catch (e) {
      Logger.error('Category calculation failed', e);
      return _getEmptyCategories();
    }
  }


  /// Create category map - moved to static method for isolate access
  static Map<String, CategoryData> _createCategoryMap() {
    return {
      'images': CategoryData(
        name: 'Images',
        extensions: FileExtensions.imageExtensions,
      ),
      'videos': CategoryData(
        name: 'Videos',
        extensions: FileExtensions.videoExtensions,
      ),
      'audio': CategoryData(
        name: 'Audio',
        extensions: FileExtensions.audioExtensions,
      ),
      'documents': CategoryData(
        name: 'Documents',
        extensions: FileExtensions.documentExtensions,
      ),
      'apps': CategoryData(
        name: 'Apps',
        extensions: FileExtensions.appExtensions,
      ),
      'others': CategoryData(
        name: 'Others',
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
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'videos',
        name: 'Videos',
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'audio',
        name: 'Audio',
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'documents',
        name: 'Documents',
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'apps',
        name: 'Apps',
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'others',
        name: 'Others',
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

      // Clear all file repository caches before analysis to ensure fresh data
      FileRepositoryImpl.clearAllCaches();
      Logger.info("Cleared file caches before deep analysis");

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

  Future<void> deleteCategory(String categoryId) async {
    try {
      Logger.info('Deleting category: $categoryId');
      
      // Remove from cache if it exists
      if (_categoriesCache != null) {
        _categoriesCache = _categoriesCache!
            .where((category) => category.id != categoryId)
            .toList();
      }
      
      // In a real app, you might want to persist this deletion
      // For now, we're just removing it from the cached list
      // The category will reappear after cache expiration or app restart
      
      Logger.success('Category deleted successfully: $categoryId');
    } catch (e) {
      Logger.error('Failed to delete category', e);
      rethrow;
    }
  }
  
}

/// Helper class to store category data during scanning
class CategoryData {
  final String name;
  final List<String> extensions;
  int totalSize = 0;
  int fileCount = 0;

  CategoryData({
    required this.name,
    required this.extensions,
  });
}
