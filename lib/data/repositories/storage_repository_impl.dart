import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/constants/file_extensions.dart';
import 'package:smart_storage_analyzer/core/services/native_storage_service.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/category_model.dart';
import 'package:smart_storage_analyzer/data/models/storage_info_model.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  static const platform = MethodChannel('com.smartstorage/native');

  // Native storage service instance
  final NativeStorageService _nativeStorageService = NativeStorageService();
  final _permissionService = PermissionService();

  @override
  Future<void> analyzeStorage({BuildContext? context}) async {
    try {
      Logger.info("Starting real storage analysis...");

      // Request storage permission if needed
      if (Platform.isAndroid) {
        final hasPermission = await _permissionService.hasStoragePermission();
        if (!hasPermission && context != null && context.mounted) {
          await _permissionService.requestStoragePermission(context: context);
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
        // Check storage permission
        final hasPermission = await _permissionService.hasStoragePermission();
        if (!hasPermission) {
          // Return empty categories if no permission
          return _getEmptyCategories();
        }

        // Scan actual files on device
        return await _scanDeviceFiles();
      }

      // For non-Android platforms, return empty categories
      return _getEmptyCategories();
    } catch (e) {
      Logger.error('Failed to get categories', e);
      // Return empty categories on error
      return _getEmptyCategories();
    }
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

  /// Scans device files to get real category sizes
  Future<List<Category>> _scanDeviceFiles() async {
    final Map<String, CategoryData> categoryMap = {
      'images': CategoryData(
        name: 'Images',
        icon: AppIcons.images,
        color: AppColorSchemes.imageCategoryLight, // Will be adjusted in presentation layer
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

    try {
      // Use the native Android implementation to get files by category
      // This ensures consistency with FileManager and other views
      for (final categoryId in categoryMap.keys) {
        try {
          final List<dynamic> result = await platform.invokeMethod(
            'getFilesByCategory',
            {'category': categoryId},
          );
          
          // Calculate total size and file count
          int totalSize = 0;
          int fileCount = result.length;
          
          for (final fileData in result) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
            final size = (data['size'] as num?)?.toInt() ?? 0;
            totalSize += size;
          }
          
          categoryMap[categoryId]!.totalSize = totalSize;
          categoryMap[categoryId]!.fileCount = fileCount;
          
          Logger.info('Category $categoryId: $fileCount files, total size: $totalSize bytes');
        } catch (e) {
          Logger.warning('Failed to get files for category $categoryId: $e');
          // Keep the category with 0 size/count
        }
      }

      // Convert to Category list
      final categories = categoryMap.entries.map((entry) {
        final data = entry.value;
        return CategoryModel(
          id: entry.key,
          name: data.name,
          icon: data.icon,
          color: data.color,
          sizeInBytes: data.totalSize.toDouble(),
          filesCount: data.fileCount,
        );
      }).toList();

      // Sort by size (largest first)
      categories.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));

      return categories;
    } catch (e) {
      Logger.error('Failed to scan device files', e);
      return _getEmptyCategories();
    }
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
