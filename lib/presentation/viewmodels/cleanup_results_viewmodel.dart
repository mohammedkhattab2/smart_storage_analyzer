import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:path_provider/path_provider.dart';

class CleanupResultsViewModel {
  final _permissionService = PermissionService();
  
  Future<bool> deleteFiles(List<FileItem> files, {BuildContext? context}) async {
    try {
      Logger.info('Deleting ${files.length} files...');
      
      // Check if we have storage permission
      final hasPermission = await _permissionService.requestStoragePermission(context: context);
      if (!hasPermission) {
        Logger.error('Storage permission denied');
        return false;
      }

      int successCount = 0;
      int failCount = 0;

      for (final file in files) {
        try {
          final fileToDelete = File(file.path);
          if (await fileToDelete.exists()) {
            await fileToDelete.delete();
            successCount++;
            Logger.info('Deleted: ${file.path}');
          } else {
            Logger.warning('File not found: ${file.path}');
          }
        } catch (e) {
          failCount++;
          Logger.error('Failed to delete ${file.path}: $e');
        }
      }
      
      Logger.success('Successfully deleted $successCount files, failed: $failCount');
      return failCount == 0;
    } catch (e) {
      Logger.error('Failed to delete files', e);
      return false;
    }
  }

  Future<void> clearCache() async {
    try {
      Logger.info('Clearing cache...');
      
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      
      if (await cacheDir.exists()) {
        // List all files and subdirectories in cache
        final entities = cacheDir.listSync(recursive: true, followLinks: false);
        
        int deletedCount = 0;
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
              deletedCount++;
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
              deletedCount++;
            }
          } catch (e) {
            Logger.warning('Failed to delete cache entity: ${entity.path}');
          }
        }
        
        Logger.success('Cache cleared successfully. Deleted $deletedCount items');
      } else {
        Logger.info('Cache directory does not exist');
      }
    } catch (e) {
      Logger.error('Failed to clear cache', e);
      rethrow;
    }
  }

  Future<void> cleanThumbnails() async {
    try {
      Logger.info('Cleaning thumbnails...');
      
      // Common thumbnail directories on Android
      final thumbnailPaths = [
        '/storage/emulated/0/.thumbnails',
        '/storage/emulated/0/DCIM/.thumbnails',
        '/storage/emulated/0/Android/data/.thumbnails',
      ];
      
      // Get external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalThumbnails = '${externalDir.parent.parent.parent.parent.path}/.thumbnails';
        thumbnailPaths.add(externalThumbnails);
      }
      
      int totalDeleted = 0;
      for (final path in thumbnailPaths) {
        final thumbDir = Directory(path);
        if (await thumbDir.exists()) {
          try {
            final files = thumbDir.listSync(recursive: true, followLinks: false);
            for (final file in files) {
              if (file is File && _isThumbnailFile(file.path)) {
                try {
                  await file.delete();
                  totalDeleted++;
                } catch (e) {
                  Logger.warning('Failed to delete thumbnail: ${file.path}');
                }
              }
            }
          } catch (e) {
            Logger.warning('Failed to access thumbnail directory: $path');
          }
        }
      }
      
      Logger.success('Thumbnails cleaned successfully. Deleted $totalDeleted files');
    } catch (e) {
      Logger.error('Failed to clean thumbnails', e);
      rethrow;
    }
  }
  
  bool _isThumbnailFile(String path) {
    final lowercasePath = path.toLowerCase();
    // Common thumbnail file patterns
    return lowercasePath.contains('.thumbnail') ||
           lowercasePath.contains('.thumb') ||
           lowercasePath.contains('thumbnail') ||
           lowercasePath.endsWith('.jpg') && lowercasePath.contains('thumb') ||
           lowercasePath.endsWith('.png') && lowercasePath.contains('thumb');
  }
}