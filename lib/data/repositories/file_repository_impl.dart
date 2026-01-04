import 'dart:io';

import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/models/file_item_model.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class FileRepositoryImpl implements FileRepository {
  static const platform = MethodChannel('com.smartstorage/native');
  @override
  Future<void> deleteFiles(List<String> fileIds) async {
    if (!Platform.isAndroid) {
      Logger.warning('Delete operation not supported on non-Android platforms');
      return;
    }

    try {
      // Get file paths from fileIds (which are actually paths in our implementation)
      final filePaths = fileIds;

      final int deletedCount = await platform.invokeMethod('deleteFiles', {
        'paths': filePaths,
      });

      Logger.success('Deleted $deletedCount files successfully');
    } catch (e) {
      Logger.error('Failed to delete files', e);
      throw Exception('Failed to delete files: $e');
    }
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

    try {
      // Get files from native Android scanner
      final List<dynamic> result = await platform.invokeMethod(
        'getFilesByCategory',
        {'category': category},
      );

      Logger.info('Got ${result.length} files from native scanner for category: $category');

      // Convert to FileItem objects
      final files = result.map((fileData) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
        return FileItemModel(
          id: data['id'] ?? data['path'].hashCode.toString(),
          name: data['name'] ?? 'Unknown',
          path: data['path'] ?? '',
          sizeInBytes: (data['size'] as num?)?.toInt() ?? 0,
          lastModified: data['lastModified'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['lastModified'] as int)
              : DateTime.now(),
          extension: data['extension'] ?? '',
          category: FileCategoryExtension.fromExtension(
            data['extension'] ?? '',
          ),
        );
      }).toList();

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
    // Get all files for the category
    final allFiles = await getFilesByCategory(category);
    
    // Calculate pagination indices
    final startIndex = page * pageSize;
    final endIndex = (page + 1) * pageSize;
    
    // Return empty list if start index is beyond available files
    if (startIndex >= allFiles.length) {
      return [];
    }
    
    // Return the paginated subset
    return allFiles.sublist(
      startIndex,
      endIndex > allFiles.length ? allFiles.length : endIndex,
    );
  }

  @override
  Future<int> getFilesCount(FileCategory category) async {
    // Get all files for the category to count them
    final files = await getFilesByCategory(category);
    return files.length;
  }

  // Removed all mock file methods - app now only uses real file data
}
