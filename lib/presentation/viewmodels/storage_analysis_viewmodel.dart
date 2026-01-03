import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';



class StorageAnalysisViewModel {
  
  Future<StorageAnalysisResults> performDeepAnalysis() async {
    try {
      Logger.info("Starting deep storage analysis...");
      
      // Check permission first
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      final startTime = DateTime.now();
      
      // Initialize collections
      final cacheFiles = <FileItem>[];
      final tempFiles = <FileItem>[];
      final largeOldFiles = <FileItem>[];
      final duplicateFiles = <FileItem>[];
      final thumbnails = <FileItem>[];
      final categoryFiles = <FileCategory, List<FileItem>>{};
      
      int totalFilesScanned = 0;
      int totalSpaceUsed = 0;
      
      // Scan common directories
      await _scanCacheDirectories(cacheFiles);
      await _scanTempDirectories(tempFiles);
      await _scanForLargeOldFiles(largeOldFiles);
      await _scanForThumbnails(thumbnails);
      
      // Scan user storage
      final directories = await _getStorageDirectories();
      for (final dir in directories) {
        if (await dir.exists()) {
          await _scanDirectory(
            dir, 
            categoryFiles,
            totalFilesScanned,
            totalSpaceUsed,
            largeOldFiles,
          );
        }
      }
      
      // Find duplicates from scanned files
      _findDuplicates(categoryFiles, duplicateFiles);
      
      // Count total files
      totalFilesScanned = cacheFiles.length + 
                         tempFiles.length + 
                         largeOldFiles.length +
                         thumbnails.length;
      
      for (final files in categoryFiles.values) {
        totalFilesScanned += files.length;
      }
      
      // Calculate total space
      final deviceInfo = await _getDeviceStorageInfo();
      
      // Generate detailed categories
      final detailedCategories = _generateDetailedCategories(categoryFiles);
      
      // Calculate cleanup potential
      final totalCleanupPotential = 
        cacheFiles.fold(0, (sum, file) => sum + file.sizeInBytes) +
        tempFiles.fold(0, (sum, file) => sum + file.sizeInBytes) +
        duplicateFiles.fold(0, (sum, file) => sum + file.sizeInBytes) +
        largeOldFiles.fold(0, (sum, file) => sum + file.sizeInBytes) +
        thumbnails.fold(0, (sum, file) => sum + file.sizeInBytes);
      
      Logger.success("Storage analysis completed");
      
      return StorageAnalysisResults(
        totalFilesScanned: totalFilesScanned,
        totalSpaceUsed: deviceInfo['used']!,
        totalSpaceAvailable: deviceInfo['total']!,
        cacheFiles: cacheFiles,
        temporaryFiles: tempFiles,
        largeOldFiles: largeOldFiles,
        duplicateFiles: duplicateFiles,
        thumbnails: thumbnails,
        detailedCategories: detailedCategories,
        totalCleanupPotential: totalCleanupPotential.toInt(),
        analysisDate: DateTime.now(),
        analysisDuration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      Logger.error('Failed to perform storage analysis', e);
      rethrow;
    }
  }
  
  Future<void> _scanCacheDirectories(List<FileItem> cacheFiles) async {
    try {
      // Get cache directories
      final tempDir = await getTemporaryDirectory();
      
      // Additional cache paths
      final cachePaths = [
        tempDir.path,
        '/storage/emulated/0/Android/data',
      ];
      
      for (final path in cachePaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await _scanForCacheFiles(dir, cacheFiles);
        }
      }
    } catch (e) {
      Logger.warning('Error scanning cache directories: $e');
    }
  }
  
  Future<void> _scanForCacheFiles(Directory dir, List<FileItem> cacheFiles) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.contains('/cache/') || 
              path.contains('.cache') ||
              path.endsWith('.tmp')) {
            final stat = await entity.stat();
            cacheFiles.add(FileItem(
              id: 'cache_${cacheFiles.length}',
              name: entity.uri.pathSegments.last,
              path: entity.path,
              sizeInBytes: stat.size,
              lastModified: stat.modified,
              extension: _getFileExtension(entity.path),
              category: FileCategory.others,
            ));
          }
        }
      }
    } catch (e) {
      Logger.warning('Error scanning directory ${dir.path}: $e');
    }
  }
  
  Future<void> _scanTempDirectories(List<FileItem> tempFiles) async {
    try {
      final tempDir = await getTemporaryDirectory();
      
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          tempFiles.add(FileItem(
            id: 'temp_${tempFiles.length}',
            name: entity.uri.pathSegments.last,
            path: entity.path,
            sizeInBytes: stat.size,
            lastModified: stat.modified,
            extension: _getFileExtension(entity.path),
            category: FileCategory.others,
          ));
        }
      }
    } catch (e) {
      Logger.warning('Error scanning temp directories: $e');
    }
  }
  
  Future<void> _scanForLargeOldFiles(List<FileItem> largeOldFiles) async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      final largeFileThreshold = 100 * 1024 * 1024; // 100MB
      
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        await for (final entity in downloadDir.list(followLinks: false)) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.size >= largeFileThreshold && 
                stat.accessed.isBefore(sixMonthsAgo)) {
              largeOldFiles.add(FileItem(
                id: 'old_${largeOldFiles.length}',
                name: entity.uri.pathSegments.last,
                path: entity.path,
                sizeInBytes: stat.size,
                lastModified: stat.modified,
                extension: _getFileExtension(entity.path),
                category: FileCategoryExtension.fromExtension(_getFileExtension(entity.path)),
              ));
            }
          }
        }
      }
    } catch (e) {
      Logger.warning('Error scanning for large old files: $e');
    }
  }
  
  Future<void> _scanForThumbnails(List<FileItem> thumbnails) async {
    try {
      final thumbnailPaths = [
        '/storage/emulated/0/.thumbnails',
        '/storage/emulated/0/DCIM/.thumbnails',
      ];
      
      for (final path in thumbnailPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final stat = await entity.stat();
              thumbnails.add(FileItem(
                id: 'thumb_${thumbnails.length}',
                name: entity.uri.pathSegments.last,
                path: entity.path,
                sizeInBytes: stat.size,
                lastModified: stat.modified,
                extension: _getFileExtension(entity.path),
                category: FileCategory.images,
              ));
            }
          }
        }
      }
    } catch (e) {
      Logger.warning('Error scanning for thumbnails: $e');
    }
  }
  
  Future<void> _scanDirectory(
    Directory dir,
    Map<FileCategory, List<FileItem>> categoryFiles,
    int totalFilesScanned,
    int totalSpaceUsed,
    List<FileItem> largeOldFiles,
  ) async {
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          final extension = _getFileExtension(entity.path);
          final category = FileCategoryExtension.fromExtension(extension);
          
          final fileItem = FileItem(
            id: '${category.name}_${categoryFiles[category]?.length ?? 0}',
            name: entity.uri.pathSegments.last,
            path: entity.path,
            sizeInBytes: stat.size,
            lastModified: stat.modified,
            extension: extension,
            category: category,
          );
          
          categoryFiles.putIfAbsent(category, () => []).add(fileItem);
        }
      }
    } catch (e) {
      Logger.warning('Error scanning directory ${dir.path}: $e');
    }
  }
  
  void _findDuplicates(
    Map<FileCategory, List<FileItem>> categoryFiles,
    List<FileItem> duplicateFiles,
  ) {
    // Simple duplicate detection based on name and size
    final fileMap = <String, List<FileItem>>{};
    
    for (final files in categoryFiles.values) {
      for (final file in files) {
        final key = '${file.name}_${file.sizeInBytes}';
        fileMap.putIfAbsent(key, () => []).add(file);
      }
    }
    
    for (final group in fileMap.values) {
      if (group.length > 1) {
        // Keep the first file, mark others as duplicates
        duplicateFiles.addAll(group.skip(1));
      }
    }
  }
  
  List<Category> _generateDetailedCategories(Map<FileCategory, List<FileItem>> categoryFiles) {
    return [
      if (categoryFiles[FileCategory.images] != null)
        Category(
          id: 'images',
          name: 'Images',
          icon: Icons.image,
          color: Colors.purple,
          fileCount: categoryFiles[FileCategory.images]!.length,
          sizeInBytes: categoryFiles[FileCategory.images]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
      if (categoryFiles[FileCategory.videos] != null)
        Category(
          id: 'videos',
          name: 'Videos',
          icon: Icons.video_library,
          color: Colors.pink,
          fileCount: categoryFiles[FileCategory.videos]!.length,
          sizeInBytes: categoryFiles[FileCategory.videos]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
      if (categoryFiles[FileCategory.audio] != null)
        Category(
          id: 'audio',
          name: 'Audio',
          icon: Icons.audiotrack,
          color: Colors.teal,
          fileCount: categoryFiles[FileCategory.audio]!.length,
          sizeInBytes: categoryFiles[FileCategory.audio]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
      if (categoryFiles[FileCategory.documents] != null)
        Category(
          id: 'documents',
          name: 'Documents',
          icon: Icons.description,
          color: Colors.indigo,
          fileCount: categoryFiles[FileCategory.documents]!.length,
          sizeInBytes: categoryFiles[FileCategory.documents]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
      if (categoryFiles[FileCategory.apps] != null)
        Category(
          id: 'apps',
          name: 'Apps',
          icon: Icons.apps,
          color: Colors.blueGrey,
          fileCount: categoryFiles[FileCategory.apps]!.length,
          sizeInBytes: categoryFiles[FileCategory.apps]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
      if (categoryFiles[FileCategory.others] != null)
        Category(
          id: 'others',
          name: 'Others',
          icon: Icons.folder,
          color: Colors.brown,
          fileCount: categoryFiles[FileCategory.others]!.length,
          sizeInBytes: categoryFiles[FileCategory.others]!
              .fold(0.0, (sum, file) => sum + file.sizeInBytes),
        ),
    ];
  }
  
  Future<Map<String, int>> _getDeviceStorageInfo() async {
    try {
      // Get storage info from system
      // This is a simplified version - in production you'd use platform channels
      final dir = Directory('/storage/emulated/0');
      if (Platform.isAndroid && await dir.exists()) {
        // Estimate based on available space
        // In real app, you'd use disk_space_plus or similar
        return {
          'total': 128 * 1024 * 1024 * 1024, // 128GB example
          'used': 50 * 1024 * 1024 * 1024,   // 50GB example
          'free': 78 * 1024 * 1024 * 1024,   // 78GB example
        };
      }
    } catch (e) {
      Logger.warning('Error getting device storage info: $e');
    }
    
    // Default values
    return {
      'total': 128 * 1024 * 1024 * 1024,
      'used': 50 * 1024 * 1024 * 1024,
      'free': 78 * 1024 * 1024 * 1024,
    };
  }
  
  Future<List<Directory>> _getStorageDirectories() async {
    final dirs = <Directory>[];
    
    try {
      // Main storage directories
      final mainPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents', 
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/DCIM',
      ];
      
      for (final path in mainPaths) {
        dirs.add(Directory(path));
      }
      
      // App directories
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        dirs.add(externalDir);
      }
    } catch (e) {
      Logger.warning('Error getting storage directories: $e');
    }
    
    return dirs;
  }
  
  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1 && lastDot < path.length - 1) {
      return path.substring(lastDot).toLowerCase();
    }
    return '';
  }
  
  Future<bool> _checkStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }
    
    // For Android 11+ (API 30+), check manage external storage permission
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) {
        return true;
      }
    }
    
    return false;
  }
}