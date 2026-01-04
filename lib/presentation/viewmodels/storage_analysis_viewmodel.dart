import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/domain/models/file_item_model.dart';
import 'package:smart_storage_analyzer/data/models/category_model.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';

class StorageAnalysisViewModel {
  final _permissionService = PermissionService();
  static const platform = MethodChannel('com.smartstorage/native');
  
  Future<StorageAnalysisResults> performDeepAnalysis() async {
    try {
      Logger.info("Starting deep storage analysis...");
      
      // Check permission first
      final hasPermission = await _permissionService.hasStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      final startTime = DateTime.now();
      
      if (!Platform.isAndroid) {
        Logger.warning('Storage analysis is only supported on Android');
        return _createEmptyResults(startTime);
      }
      
      // Call native Android analysis
      final Map<dynamic, dynamic> result = await platform.invokeMethod('analyzeStorage');
      
      Logger.info('Got analysis results from native: ${result['totalFilesScanned']} files scanned');
      
      // Convert native results to Dart objects
      final cacheFiles = _convertFileList(result['cacheFiles'] as List<dynamic>);
      final tempFiles = _convertFileList(result['temporaryFiles'] as List<dynamic>);
      final largeOldFiles = _convertFileList(result['largeOldFiles'] as List<dynamic>);
      final duplicateFiles = _convertFileList(result['duplicateFiles'] as List<dynamic>);
      final thumbnails = _convertFileList(result['thumbnails'] as List<dynamic>);
      
      // Generate detailed categories (for now, using predefined categories)
      final detailedCategories = _generateDetailedCategories();
      
      Logger.success("Storage analysis completed");
      
      return StorageAnalysisResults(
        totalFilesScanned: result['totalFilesScanned'] as int,
        totalSpaceUsed: result['totalSpaceUsed'] as int,
        totalSpaceAvailable: result['totalSpaceAvailable'] as int,
        cacheFiles: cacheFiles,
        temporaryFiles: tempFiles,
        largeOldFiles: largeOldFiles,
        duplicateFiles: duplicateFiles,
        thumbnails: thumbnails,
        detailedCategories: detailedCategories,
        totalCleanupPotential: result['totalCleanupPotential'] as int,
        analysisDate: DateTime.now(),
        analysisDuration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      Logger.error('Failed to perform storage analysis', e);
      rethrow;
    }
  }
  
  List<FileItem> _convertFileList(List<dynamic> nativeFiles) {
    return nativeFiles.map((fileData) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
      return FileItemModel(
        id: data['id'] ?? '',
        name: data['name'] ?? 'Unknown',
        path: data['path'] ?? '',
        sizeInBytes: (data['size'] as num?)?.toInt() ?? 0,
        lastModified: data['lastModified'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastModified'] as int)
            : DateTime.now(),
        extension: data['extension'] ?? '',
        category: FileCategoryExtension.fromExtension(data['extension'] ?? ''),
      );
    }).toList();
  }
  
  List<Category> _generateDetailedCategories() {
    // Return empty categories for now - in a real implementation,
    // this would be populated from the analysis results
    return [
      CategoryModel(
        id: 'images',
        name: 'Images',
        icon: AppIcons.images,
        color: AppColorSchemes.imageCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'videos',
        name: 'Videos',
        icon: AppIcons.videos,
        color: AppColorSchemes.videoCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'audio',
        name: 'Audio',
        icon: AppIcons.audio,
        color: AppColorSchemes.audioCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'documents',
        name: 'Documents',
        icon: AppIcons.documents,
        color: AppColorSchemes.documentCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'apps',
        name: 'Apps',
        icon: AppIcons.apps,
        color: AppColorSchemes.appsCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'others',
        name: 'Others',
        icon: AppIcons.others,
        color: AppColorSchemes.othersCategoryLight,
        sizeInBytes: 0,
        filesCount: 0,
      ),
    ];
  }
  
  StorageAnalysisResults _createEmptyResults(DateTime startTime) {
    return StorageAnalysisResults(
      totalFilesScanned: 0,
      totalSpaceUsed: 0,
      totalSpaceAvailable: 0,
      cacheFiles: [],
      temporaryFiles: [],
      largeOldFiles: [],
      duplicateFiles: [],
      thumbnails: [],
      detailedCategories: _generateDetailedCategories(),
      totalCleanupPotential: 0,
      analysisDate: DateTime.now(),
      analysisDuration: DateTime.now().difference(startTime),
    );
  }
}