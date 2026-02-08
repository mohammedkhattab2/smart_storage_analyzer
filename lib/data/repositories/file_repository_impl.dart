import 'dart:io';

import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/services/file_scanner_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class FileRepositoryImpl implements FileRepository {
  static const platform = MethodChannel(ChannelConstants.mainChannel);
  // Cache for file lists to avoid repeated scans
  static final Map<String, List<FileItem>> _fileCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 2);
  
  @override
  Future<void> deleteFiles(List<String> fileIds) async {
    if (!Platform.isAndroid) {
      Logger.warning('Delete operation not supported on non-Android platforms');
      return;
    }

    try {
      // Get file paths from fileIds (which are actually paths in our implementation)
      final filePaths = fileIds;
      
      Logger.info('Attempting to delete ${filePaths.length} files');
      for (final path in filePaths) {
        Logger.debug('File to delete: $path');
      }

      final int deletedCount = await platform.invokeMethod('deleteFiles', {
        'paths': filePaths,
      });

      if (deletedCount > 0) {
        Logger.success('Successfully deleted $deletedCount out of ${filePaths.length} files');
      } else {
        Logger.warning('No files were deleted out of ${filePaths.length} requested');
      }
      
      // Clear all file caches after deletion to ensure fresh data
      clearAllCaches();
      Logger.info('Cleared file caches after deletion');
      
      // If not all files were deleted, throw an error with details
      if (deletedCount < filePaths.length) {
        final failedCount = filePaths.length - deletedCount;
        throw Exception('Failed to delete $failedCount out of ${filePaths.length} files. This may be due to permission restrictions on Android 10+.');
      }
    } catch (e) {
      Logger.error('Failed to delete files', e);
      throw Exception('Failed to delete files: $e');
    }
  }
  
  /// Clear all cached file data
  static void clearAllCaches() {
    _fileCache.clear();
    _cacheTimestamps.clear();
    Logger.info('All file caches cleared');
  }

  @override
  Future<List<FileItem>> getAllFiles() async {
    return _getFilesByCategory('all');
  }

  @override
  Future<List<FileItem>> getDuplicateFiles() async {
    return _getFilesByCategory('duplicates');
  }

  @override
  Future<List<FileItem>> getLargeFiles() async {
    return _getFilesByCategory('large');
  }

  @override
  Future<List<FileItem>> getOldFiles() async {
    return _getFilesByCategory('old');
  }

  Future<List<FileItem>> _getFilesByCategory(String category) async {
    if (!Platform.isAndroid) {
      Logger.info('Non-Android platform: returning empty file list');
      return [];
    }

    // Check cache first
    final cacheKey = 'category_$category';
    if (_fileCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheValidDuration) {
        Logger.info('Returning cached files for category: $category');
        return _fileCache[cacheKey]!;
      }
    }

    try {
      // Use the optimized file scanner service that runs in isolates
      final files = await FileScannerService.scanFilesByCategory(
        category,
        onProgress: (progress, message) {
          Logger.debug('File scan progress: ${(progress * 100).toInt()}% - $message');
        },
      );

      Logger.info(
        'Got ${files.length} files from optimized scanner for category: $category',
      );

      // Cache the results
      _fileCache[cacheKey] = files;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return files;
    } catch (e) {
      Logger.error('Failed to get files from native scanner', e);
      // Return empty list on error
      return [];
    }
  }

  @override
  Future<List<FileItem>> getImageFiles() async {
    return _getFilesByCategory('images');
  }

  @override
  Future<List<FileItem>> getVideoFiles() async {
    return _getFilesByCategory('videos');
  }

  @override
  Future<List<FileItem>> getAudioFiles() async {
    return _getFilesByCategory('audio');
  }

  @override
  Future<List<FileItem>> getDocumentFiles() async {
    return _getFilesByCategory('documents');
  }

  @override
  Future<List<FileItem>> getAppFiles() async {
    return _getFilesByCategory('apps');
  }

  @override
  Future<List<FileItem>> getOtherFiles() async {
    return _getFilesByCategory('others');
  }

  @override
  Future<List<FileItem>> getFilesByCategory(FileCategory category) async {
    switch (category) {
      case FileCategory.all:
        return getAllFiles();
      case FileCategory.large:
        return getLargeFiles();
      case FileCategory.duplicates:
        return getDuplicateFiles();
      case FileCategory.old:
        return getOldFiles();
      case FileCategory.images:
        return getImageFiles();
      case FileCategory.videos:
        return getVideoFiles();
      case FileCategory.audio:
        return getAudioFiles();
      case FileCategory.documents:
        return getDocumentFiles();
      case FileCategory.apps:
        return getAppFiles();
      case FileCategory.others:
        return getOtherFiles();
    }
  }

  @override
  Future<List<FileItem>> getFilesByCategoryPaginated({
    required FileCategory category,
    required int page,
    required int pageSize,
  }) async {
    try {
      // Use optimized pagination from file scanner service
      final result = await FileScannerService.scanFilesWithPagination(
        category: _getCategoryString(category),
        page: page,
        pageSize: pageSize,
        onProgress: (progress, message) {
          Logger.debug('Paginated scan: ${(progress * 100).toInt()}% - $message');
        },
      );

      return result.files;
    } catch (e) {
      Logger.error('Failed to get paginated files', e);
      return [];
    }
  }

  @override
  Future<int> getFilesCount(FileCategory category) async {
    // Get all files for the category to count them
    final files = await getFilesByCategory(category);
    return files.length;
  }

  // Helper method to convert FileCategory to string
  String _getCategoryString(FileCategory category) {
    switch (category) {
      case FileCategory.all:
        return 'all';
      case FileCategory.large:
        return 'large';
      case FileCategory.duplicates:
        return 'duplicates';
      case FileCategory.old:
        return 'old';
      case FileCategory.images:
        return 'images';
      case FileCategory.videos:
        return 'videos';
      case FileCategory.audio:
        return 'audio';
      case FileCategory.documents:
        return 'documents';
      case FileCategory.apps:
        return 'apps';
      case FileCategory.others:
        return 'others';
    }
  }

  // Removed all mock file methods - app now only uses real file data
}
