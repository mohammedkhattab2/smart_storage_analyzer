import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/file_item_model.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

/// Optimized file scanner service that runs heavy operations in isolates
class FileScannerService {
  static const _channel = MethodChannel(ChannelConstants.mainChannel);
  
  /// Scan files by category using isolates for better performance
  static Future<List<FileItem>> scanFilesByCategory(
    String category, {
    void Function(double progress, String message)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    Logger.info('Starting optimized file scan for category: $category');
    
    // Check for cancellation
    if (cancellationToken?.isCancelled == true) {
      Logger.info('File scan cancelled before start');
      return [];
    }
    
    try {
      // First, get file data from native channel in main isolate
      // Use timeout to prevent ANR
      final List<dynamic> nativeFiles = await _channel
          .invokeMethod('getFilesByCategory', {
            'category': category,
            'limit': 10000, // Limit to prevent memory issues
          })
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              Logger.warning('Native file scan timeout for category: $category');
              return [];
            },
          );
      
      Logger.info('Got ${nativeFiles.length} files from native scanner');
      
      // Check for cancellation after native call
      if (cancellationToken?.isCancelled == true) {
        Logger.info('File scan cancelled after native call');
        return [];
      }
      
      // Process files in isolate to avoid blocking UI
      // Use batch processing for large file sets
      if (nativeFiles.length > 1000) {
        return await _processLargeFileSetInIsolate(
          nativeFiles,
          category,
          onProgress,
          cancellationToken,
        );
      }
      
      return IsolateHelper.runWithProgress<List<FileItem>, _FileScanParams>(
        computation: _processFilesInIsolate,
        parameter: _FileScanParams(
          nativeFiles: nativeFiles,
          category: category,
        ),
        onProgress: onProgress,
      );
    } catch (e) {
      Logger.error('Error scanning files for category $category', e);
      return [];
    }
  }
  
  /// Process large file sets with memory-efficient approach
  static Future<List<FileItem>> _processLargeFileSetInIsolate(
    List<dynamic> nativeFiles,
    String category,
    void Function(double progress, String message)? onProgress,
    CancellationToken? cancellationToken,
  ) async {
    Logger.info('Processing large file set: ${nativeFiles.length} files');
    
    // Process in smaller chunks to avoid memory pressure
    const chunkSize = 500;
    final allFiles = <FileItem>[];
    final totalChunks = (nativeFiles.length / chunkSize).ceil();
    
    for (int i = 0; i < totalChunks; i++) {
      if (cancellationToken?.isCancelled == true) {
        Logger.info('Large file set processing cancelled at chunk $i');
        break;
      }
      
      final start = i * chunkSize;
      final end = (start + chunkSize > nativeFiles.length)
          ? nativeFiles.length
          : start + chunkSize;
      final chunk = nativeFiles.sublist(start, end);
      
      // Process chunk in isolate
      final chunkFiles = await IsolateHelper.runWithProgress<List<FileItem>, _FileScanParams>(
        computation: _processFilesInIsolate,
        parameter: _FileScanParams(
          nativeFiles: chunk,
          category: category,
        ),
        onProgress: (chunkProgress, message) {
          final overallProgress = (i + chunkProgress) / totalChunks;
          onProgress?.call(overallProgress, message);
        },
      );
      
      allFiles.addAll(chunkFiles);
    }
    
    // Final sort by size (largest first)
    allFiles.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
    
    return allFiles;
  }
  
  /// Process files in isolate with batching and optimizations
  static Future<List<FileItem>> _processFilesInIsolate(
    _FileScanParams params,
  ) async {
    final files = <FileItem>[];
    const batchSize = 100;
    
    // Process files in batches to report progress
    final totalBatches = (params.nativeFiles.length / batchSize).ceil();
    
    // Pre-allocate list for better performance with large datasets
    if (params.nativeFiles.length > 1000) {
      files.length = params.nativeFiles.length;
      int fileIndex = 0;
      
      for (int i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize > params.nativeFiles.length)
            ? params.nativeFiles.length
            : start + batchSize;
        
        final batch = params.nativeFiles.sublist(start, end);
        
        // Process batch
        for (final fileData in batch) {
          try {
            final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
            
            // Skip files with invalid data early
            if (data['path'] == null || data['path'].isEmpty) continue;
            
            files[fileIndex++] = FileItemModel(
              id: data['id'] ?? data['path'].hashCode.toString(),
              name: data['name'] ?? 'Unknown',
              path: data['path'],
              sizeInBytes: (data['size'] as num?)?.toInt() ?? 0,
              lastModified: data['lastModified'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(data['lastModified'] as int)
                  : DateTime.now(),
              extension: data['extension'] ?? '',
              category: FileCategoryExtension.fromExtension(
                data['extension'] ?? '',
              ),
            );
          } catch (e) {
            // Skip invalid files
            continue;
          }
        }
        
        // Report progress
        final progress = (i + 1) / totalBatches;
        reportProgress(
          progress,
          'Processing files: ${(progress * 100).toInt()}%',
        );
      }
      
      // Trim the list to actual size
      files.length = fileIndex;
    } else {
      // For smaller datasets, use normal processing
      for (int i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize > params.nativeFiles.length)
            ? params.nativeFiles.length
            : start + batchSize;
        
        final batch = params.nativeFiles.sublist(start, end);
        
        // Process batch
        for (final fileData in batch) {
          try {
            final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
            
            // Skip files with invalid data early
            if (data['path'] == null || data['path'].isEmpty) continue;
            
            files.add(FileItemModel(
              id: data['id'] ?? data['path'].hashCode.toString(),
              name: data['name'] ?? 'Unknown',
              path: data['path'],
              sizeInBytes: (data['size'] as num?)?.toInt() ?? 0,
              lastModified: data['lastModified'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(data['lastModified'] as int)
                  : DateTime.now(),
              extension: data['extension'] ?? '',
              category: FileCategoryExtension.fromExtension(
                data['extension'] ?? '',
              ),
            ));
          } catch (e) {
            // Skip invalid files
            continue;
          }
        }
        
        // Report progress
        final progress = (i + 1) / totalBatches;
        reportProgress(
          progress,
          'Processing files: ${(progress * 100).toInt()}%',
        );
      }
    }
    
    // Only sort if we have files
    if (files.isNotEmpty && files.length < 10000) {
      // Sort by size (largest first) in isolate to avoid UI blocking
      // For very large lists, consider partial sorting or skip sorting
      files.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
    }
    
    return files;
  }
  
  /// Perform deep storage analysis with progress and cancellation
  static Future<StorageAnalysisData> performDeepAnalysis({
    void Function(double progress, String message)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    Logger.info('Starting deep storage analysis with isolates');
    
    // Check for cancellation
    if (cancellationToken?.isCancelled == true) {
      Logger.info('Deep analysis cancelled before start');
      throw Exception('Analysis cancelled');
    }
    
    try {
      onProgress?.call(0.05, 'Initializing storage analysis...');
      
      // Get analysis data from native in main thread with timeout
      // Only scan for cache, temp files and thumbnails
      final Map<dynamic, dynamic> nativeResult = await _channel
          .invokeMethod('analyzeStorage', {
            'quickScan': true, // Quick scan for cache/temp only
            'includeSystemFiles': false, // Skip system files
            'skipDuplicates': true, // Don't analyze duplicate files
            'skipLargeFiles': true, // Don't analyze large old files
            'cacheOnly': true, // Focus on cache, temp, and thumbnails
          })
          .timeout(
            const Duration(minutes: 2), // Shorter timeout for quick scan
            onTimeout: () {
              Logger.error('Deep analysis timeout');
              throw Exception('Storage analysis timed out');
            },
          );
      
      // Check for cancellation after native call
      if (cancellationToken?.isCancelled == true) {
        Logger.info('Deep analysis cancelled after native call');
        throw Exception('Analysis cancelled');
      }
      
      onProgress?.call(0.5, 'Processing analysis results...');
      
      // Process the results in isolate
      return await IsolateHelper.runWithProgress<StorageAnalysisData, Map<dynamic, dynamic>>(
        computation: _processAnalysisResults,
        parameter: nativeResult,
        onProgress: (progress, message) {
          // Scale progress from 0.5 to 1.0
          onProgress?.call(0.5 + (progress * 0.5), message);
        },
      );
    } catch (e) {
      Logger.error('Deep storage analysis failed', e);
      // Return minimal data on error
      return StorageAnalysisData(
        totalFilesScanned: 0,
        totalSpaceUsed: 0,
        totalSpaceAvailable: 0,
        cacheFiles: [],
        temporaryFiles: [],
        largeOldFiles: [],
        duplicateFiles: [],
        thumbnails: [],
        totalCleanupPotential: 0,
      );
    }
  }
  
  /// Process analysis results in isolate with memory optimization
  static Future<StorageAnalysisData> _processAnalysisResults(
    Map<dynamic, dynamic> nativeResult,
  ) async {
    try {
      reportProgress(0.1, 'Processing cache files...');
      final cacheFiles = _convertFileListOptimized(
        nativeResult['cacheFiles'] as List<dynamic>? ?? [],
        maxFiles: 500, // Limit to prevent memory issues
      );
      
      reportProgress(0.3, 'Processing temporary files...');
      final tempFiles = _convertFileListOptimized(
        nativeResult['temporaryFiles'] as List<dynamic>? ?? [],
        maxFiles: 500,
      );
      
      reportProgress(0.5, 'Skipping large files scan...');
      final largeFiles = <FileItem>[]; // Skip large files
      
      reportProgress(0.7, 'Skipping duplicate files scan...');
      final duplicateFiles = <FileItem>[]; // Skip duplicate files - don't analyze them
      
      reportProgress(0.8, 'Processing thumbnails...');
      final thumbnails = _convertFileListOptimized(
        nativeResult['thumbnails'] as List<dynamic>? ?? [],
        maxFiles: 1000, // Thumbnails are small
      );
      
      reportProgress(1.0, 'Analysis complete');
      
      return StorageAnalysisData(
        totalFilesScanned: (nativeResult['totalFilesScanned'] as num?)?.toInt() ?? 0,
        totalSpaceUsed: (nativeResult['totalSpaceUsed'] as num?)?.toInt() ?? 0,
        totalSpaceAvailable: (nativeResult['totalSpaceAvailable'] as num?)?.toInt() ?? 0,
        cacheFiles: cacheFiles,
        temporaryFiles: tempFiles,
        largeOldFiles: largeFiles,
        duplicateFiles: duplicateFiles,
        thumbnails: thumbnails,
        totalCleanupPotential: (nativeResult['totalCleanupPotential'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      // Return empty data on error
      return StorageAnalysisData(
        totalFilesScanned: 0,
        totalSpaceUsed: 0,
        totalSpaceAvailable: 0,
        cacheFiles: [],
        temporaryFiles: [],
        largeOldFiles: [],
        duplicateFiles: [],
        thumbnails: [],
        totalCleanupPotential: 0,
      );
    }
  }
  
  /// Convert file list with optimization and limits
  static List<FileItem> _convertFileListOptimized(
    List<dynamic> nativeFiles, {
    int maxFiles = 1000,
  }) {
    final files = <FileItem>[];
    
    // Limit files to prevent memory issues
    final limit = nativeFiles.length > maxFiles ? maxFiles : nativeFiles.length;
    
    for (int i = 0; i < limit; i++) {
      try {
        final fileData = nativeFiles[i];
        final Map<String, dynamic> data = Map<String, dynamic>.from(fileData);
        
        // Skip invalid files early
        if (data['path'] == null || data['path'].isEmpty) continue;
        
        files.add(FileItemModel(
          id: data['id'] ?? data['path'].hashCode.toString(),
          name: data['name'] ?? 'Unknown',
          path: data['path'],
          sizeInBytes: (data['size'] as num?)?.toInt() ?? 0,
          lastModified: data['lastModified'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['lastModified'] as num).toInt(),
                )
              : DateTime.now(),
          extension: data['extension'] ?? '',
          category: FileCategoryExtension.fromExtension(data['extension'] ?? ''),
        ));
      } catch (e) {
        // Skip invalid files
        continue;
      }
    }
    
    return files;
  }
  
  /// Scan files with pagination support
  static Future<PaginatedFileResult> scanFilesWithPagination({
    required String category,
    required int page,
    required int pageSize,
    void Function(double progress, String message)? onProgress,
  }) async {
    Logger.info('Scanning files with pagination: page=$page, pageSize=$pageSize');
    
    // Get all files for category (could be optimized with native pagination)
    final allFiles = await scanFilesByCategory(
      category,
      onProgress: onProgress,
    );
    
    // Calculate pagination
    final startIndex = page * pageSize;
    final endIndex = (page + 1) * pageSize;
    
    if (startIndex >= allFiles.length) {
      return PaginatedFileResult(
        files: [],
        totalCount: allFiles.length,
        hasMore: false,
      );
    }
    
    final paginatedFiles = allFiles.sublist(
      startIndex,
      endIndex > allFiles.length ? allFiles.length : endIndex,
    );
    
    return PaginatedFileResult(
      files: paginatedFiles,
      totalCount: allFiles.length,
      hasMore: endIndex < allFiles.length,
    );
  }
}

/// Parameters for file scanning
class _FileScanParams {
  final List<dynamic> nativeFiles;
  final String category;
  
  _FileScanParams({
    required this.nativeFiles,
    required this.category,
  });
}

/// Storage analysis data
class StorageAnalysisData {
  final int totalFilesScanned;
  final int totalSpaceUsed;
  final int totalSpaceAvailable;
  final List<FileItem> cacheFiles;
  final List<FileItem> temporaryFiles;
  final List<FileItem> largeOldFiles;
  final List<FileItem> duplicateFiles;
  final List<FileItem> thumbnails;
  final int totalCleanupPotential;
  
  StorageAnalysisData({
    required this.totalFilesScanned,
    required this.totalSpaceUsed,
    required this.totalSpaceAvailable,
    required this.cacheFiles,
    required this.temporaryFiles,
    required this.largeOldFiles,
    required this.duplicateFiles,
    required this.thumbnails,
    required this.totalCleanupPotential,
  });
}

/// Paginated file result
class PaginatedFileResult {
  final List<FileItem> files;
  final int totalCount;
  final bool hasMore;
  
  PaginatedFileResult({
    required this.files,
    required this.totalCount,
    required this.hasMore,
  });
}

/// File scanner batch processor for large operations
class FileScannerBatchProcessor extends BatchProcessor<List<FileItem>> {
  final String rootPath;
  final Set<String> extensions;
  final int maxDepth;
  
  FileScannerBatchProcessor({
    required this.rootPath,
    required this.extensions,
    this.maxDepth = 3,
  });
  
  @override
  Future<List<FileItem>> process(bool Function() isCancelled) async {
    final files = <FileItem>[];
    await _scanDirectory(
      Directory(rootPath),
      files,
      extensions,
      0,
      maxDepth,
      isCancelled,
    );
    return files;
  }
  
  Future<void> _scanDirectory(
    Directory dir,
    List<FileItem> files,
    Set<String> extensions,
    int depth,
    int maxDepth,
    bool Function() isCancelled,
  ) async {
    if (depth > maxDepth || isCancelled()) return;
    
    try {
      final entities = await dir.list().toList();
      
      for (final entity in entities) {
        if (isCancelled()) return;
        
        if (entity is File) {
          final extension = _getExtension(entity.path);
          if (extensions.isEmpty || extensions.contains(extension)) {
            final stat = await entity.stat();
            files.add(FileItemModel(
              id: entity.path.hashCode.toString(),
              name: entity.path.split('/').last,
              path: entity.path,
              sizeInBytes: stat.size,
              lastModified: stat.modified,
              extension: extension,
              category: FileCategoryExtension.fromExtension(extension),
            ));
          }
        } else if (entity is Directory && !entity.path.contains('/.')) {
          await _scanDirectory(
            entity,
            files,
            extensions,
            depth + 1,
            maxDepth,
            isCancelled,
          );
        }
      }
    } catch (e) {
      // Skip directories with permission errors
    }
  }
  
  String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    return lastDot > 0 ? path.substring(lastDot) : '';
  }
}