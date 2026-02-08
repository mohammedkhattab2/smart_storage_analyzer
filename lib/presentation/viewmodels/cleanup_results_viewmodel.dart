import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:path_provider/path_provider.dart';

class CleanupResultsViewModel {
  final _permissionService = PermissionService();
  StreamController<double>? _progressController;
  CancellationToken? _currentCancellationToken;

  /// Delete files with progress reporting and cancellation support
  Future<bool> deleteFiles(
    List<FileItem> files, {
    BuildContext? context,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      Logger.info('Starting deletion of ${files.length} files...');

      // Check if we have storage permission
      final hasPermission = await _permissionService.requestStoragePermission(
        context: context,
      );
      if (!hasPermission) {
        Logger.error('Storage permission denied');
        return false;
      }

      // Create cancellation token for this operation
      _currentCancellationToken = CancellationToken();
      
      // Delete files in batches for better performance
      const batchSize = 50;
      final result = await _deleteFilesInBatches(
        files,
        batchSize: batchSize,
        onProgress: onProgress,
        cancellationToken: _currentCancellationToken!,
      );

      Logger.success(
        'Deletion completed. Success: ${result.successCount}, Failed: ${result.failCount}',
      );
      return result.failCount == 0;
    } catch (e) {
      Logger.error('Failed to delete files', e);
      return false;
    } finally {
      _currentCancellationToken = null;
    }
  }

  /// Cancel ongoing deletion operation
  void cancelDeletion() {
    _currentCancellationToken?.cancel();
  }

  /// Delete files in batches with progress reporting
  Future<_DeletionResult> _deleteFilesInBatches(
    List<FileItem> files,
    {
      required int batchSize,
      void Function(double progress, String message)? onProgress,
      required CancellationToken cancellationToken,
    }
  ) async {
    int successCount = 0;
    int failCount = 0;
    
    // Process files in batches
    for (int i = 0; i < files.length; i += batchSize) {
      if (cancellationToken.isCancelled) {
        Logger.info('Deletion cancelled by user');
        break;
      }

      final end = (i + batchSize).clamp(0, files.length);
      final batch = files.sublist(i, end);
      
      // Delete batch in isolate for large batches
      if (batch.length > 10) {
        final result = await IsolateHelper.compute<_DeletionResult, _BatchDeletionData>(
          computation: _deleteBatchInIsolate,
          parameter: _BatchDeletionData(
            filePaths: batch.map((f) => f.path).toList(),
          ),
        );
        
        successCount += result.successCount;
        failCount += result.failCount;
      } else {
        // Delete small batches directly
        for (final file in batch) {
          try {
            final fileToDelete = File(file.path);
            if (await fileToDelete.exists()) {
              await fileToDelete.delete();
              successCount++;
            }
          } catch (e) {
            failCount++;
            Logger.error('Failed to delete ${file.path}: $e');
          }
        }
      }
      
      // Report progress
      final progress = (i + batch.length) / files.length;
      final message = 'Deleted $successCount of ${files.length} files...';
      onProgress?.call(progress, message);
    }

    return _DeletionResult(
      successCount: successCount,
      failCount: failCount,
    );
  }

  /// Delete batch of files in isolate
  static _DeletionResult _deleteBatchInIsolate(_BatchDeletionData data) {
    int successCount = 0;
    int failCount = 0;

    for (final path in data.filePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
          successCount++;
        }
      } catch (e) {
        failCount++;
        // Silent in release mode - Logger not available in isolate
        if (kDebugMode) {
          debugPrint('[CleanupViewModel] Failed to delete $path: $e');
        }
      }
    }

    return _DeletionResult(
      successCount: successCount,
      failCount: failCount,
    );
  }

  /// Clear cache with progress reporting
  Future<void> clearCache({
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      Logger.info('Starting cache cleanup...');

      // Get cache directory
      final cacheDir = await getTemporaryDirectory();

      if (await cacheDir.exists()) {
        // Run cache cleanup in isolate for better performance
        final result = await IsolateHelper.compute<_DeletionResult, String>(
          computation: _clearCacheInIsolate,
          parameter: cacheDir.path,
        );

        Logger.success(
          'Cache cleared. Deleted ${result.successCount} items',
        );
        
        onProgress?.call(1.0, 'Cache cleanup completed');
      } else {
        Logger.info('Cache directory does not exist');
        onProgress?.call(1.0, 'No cache to clean');
      }
    } catch (e) {
      Logger.error('Failed to clear cache', e);
      rethrow;
    }
  }

  /// Clear cache in isolate
  static _DeletionResult _clearCacheInIsolate(String cachePath) {
    int successCount = 0;
    int failCount = 0;

    final cacheDir = Directory(cachePath);
    if (cacheDir.existsSync()) {
      final entities = cacheDir.listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        try {
          if (entity is File) {
            entity.deleteSync();
            successCount++;
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
            successCount++;
          }
        } catch (e) {
          failCount++;
          // Silent in release mode
          if (kDebugMode) {
            debugPrint('[CleanupViewModel] Failed to delete cache entity: ${entity.path}');
          }
        }
      }
    }

    return _DeletionResult(
      successCount: successCount,
      failCount: failCount,
    );
  }

  /// Clean thumbnails with progress reporting
  Future<void> cleanThumbnails({
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      Logger.info('Starting thumbnail cleanup...');

      // Common thumbnail directories on Android
      final thumbnailPaths = <String>[];
      
      // Add standard paths
      thumbnailPaths.addAll([
        '/storage/emulated/0/.thumbnails',
        '/storage/emulated/0/DCIM/.thumbnails',
        '/storage/emulated/0/Android/data/.thumbnails',
      ]);

      // Get external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalThumbnails =
            '${externalDir.parent.parent.parent.parent.path}/.thumbnails';
        thumbnailPaths.add(externalThumbnails);
      }

      // Clean thumbnails in isolate
      final result = await IsolateHelper.compute<_DeletionResult, List<String>>(
        computation: _cleanThumbnailsInIsolate,
        parameter: thumbnailPaths,
      );

      Logger.success(
        'Thumbnails cleaned. Deleted ${result.successCount} files',
      );
      
      onProgress?.call(1.0, 'Thumbnail cleanup completed');
    } catch (e) {
      Logger.error('Failed to clean thumbnails', e);
      rethrow;
    }
  }

  /// Clean thumbnails in isolate
  static _DeletionResult _cleanThumbnailsInIsolate(List<String> paths) {
    int successCount = 0;
    int failCount = 0;

    for (final path in paths) {
      final thumbDir = Directory(path);
      if (thumbDir.existsSync()) {
        try {
          final files = thumbDir.listSync(
            recursive: true,
            followLinks: false,
          );
          for (final file in files) {
            if (file is File && _isThumbnailFile(file.path)) {
              try {
                file.deleteSync();
                successCount++;
              } catch (e) {
                failCount++;
                // Silent in release mode
                if (kDebugMode) {
                  debugPrint('[CleanupViewModel] Failed to delete thumbnail: ${file.path}');
                }
              }
            }
          }
        } catch (e) {
          // Silent in release mode
          if (kDebugMode) {
            debugPrint('[CleanupViewModel] Failed to access thumbnail directory: $path');
          }
        }
      }
    }

    return _DeletionResult(
      successCount: successCount,
      failCount: failCount,
    );
  }

  static bool _isThumbnailFile(String path) {
    final lowercasePath = path.toLowerCase();
    // Common thumbnail file patterns
    return lowercasePath.contains('.thumbnail') ||
        lowercasePath.contains('.thumb') ||
        lowercasePath.contains('thumbnail') ||
        lowercasePath.endsWith('.jpg') && lowercasePath.contains('thumb') ||
        lowercasePath.endsWith('.png') && lowercasePath.contains('thumb');
  }

  void dispose() {
    _progressController?.close();
    _currentCancellationToken?.cancel();
  }
}

/// Data for batch deletion in isolate
class _BatchDeletionData {
  final List<String> filePaths;

  _BatchDeletionData({required this.filePaths});
}

/// Result of deletion operation
class _DeletionResult {
  final int successCount;
  final int failCount;

  _DeletionResult({
    required this.successCount,
    required this.failCount,
  });
}
