import 'dart:async';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

/// Service for lazy loading and paginating file lists
class PaginatedFileLoader {
  final FileRepository _fileRepository;
  static const int defaultPageSize = 50;
  
  // Cache for loaded files per category
  final Map<FileCategory, List<FileItem>> _fileCache = {};
  final Map<FileCategory, bool> _hasMoreData = {};
  final Map<FileCategory, int> _currentPage = {};
  final Map<FileCategory, bool> _isLoading = {};
  
  PaginatedFileLoader(this._fileRepository);
  
  /// Load initial page of files
  Future<PaginatedFileResult> loadInitialFiles({
    required FileCategory category,
    int pageSize = defaultPageSize,
  }) async {
    Logger.info('Loading initial files for category: $category');
    
    // Reset state for this category
    _fileCache[category] = [];
    _currentPage[category] = 0;
    _hasMoreData[category] = true;
    
    return loadMoreFiles(category: category, pageSize: pageSize);
  }
  
  /// Load more files (pagination)
  Future<PaginatedFileResult> loadMoreFiles({
    required FileCategory category,
    int pageSize = defaultPageSize,
  }) async {
    // Prevent multiple simultaneous loads
    if (_isLoading[category] == true) {
      Logger.warning('Already loading files for category: $category');
      return PaginatedFileResult(
        files: _fileCache[category] ?? [],
        hasMore: _hasMoreData[category] ?? true,
        isLoading: true,
        totalCount: _fileCache[category]?.length ?? 0,
      );
    }
    
    _isLoading[category] = true;
    
    try {
      final currentPage = _currentPage[category] ?? 0;
      Logger.debug('Loading page $currentPage for category: $category');
      
      // Load files from repository
      final newFiles = await _fileRepository.getFilesByCategoryPaginated(
        category: category,
        page: currentPage,
        pageSize: pageSize,
      );
      
      // Add to cache
      _fileCache[category] = [...(_fileCache[category] ?? []), ...newFiles];
      
      // Update pagination state
      _currentPage[category] = currentPage + 1;
      _hasMoreData[category] = newFiles.length == pageSize;
      
      // Get total count
      final totalCount = await _fileRepository.getFilesCount(category);
      
      Logger.info(
        'Loaded ${newFiles.length} files for $category. '
        'Total cached: ${_fileCache[category]?.length}',
      );
      
      return PaginatedFileResult(
        files: _fileCache[category] ?? [],
        hasMore: _hasMoreData[category] ?? false,
        isLoading: false,
        totalCount: totalCount,
        newItemsCount: newFiles.length,
      );
    } catch (e) {
      Logger.error('Failed to load files for category $category', e);
      return PaginatedFileResult(
        files: _fileCache[category] ?? [],
        hasMore: false,
        isLoading: false,
        totalCount: _fileCache[category]?.length ?? 0,
        error: e.toString(),
      );
    } finally {
      _isLoading[category] = false;
    }
  }
  
  /// Get cached files for a category
  List<FileItem> getCachedFiles(FileCategory category) {
    return _fileCache[category] ?? [];
  }
  
  /// Clear cache for a specific category
  void clearCategoryCache(FileCategory category) {
    _fileCache.remove(category);
    _hasMoreData.remove(category);
    _currentPage.remove(category);
    _isLoading.remove(category);
  }
  
  /// Clear all cached data
  void clearAllCache() {
    _fileCache.clear();
    _hasMoreData.clear();
    _currentPage.clear();
    _isLoading.clear();
  }
  
  /// Refresh files for a category
  Future<PaginatedFileResult> refreshFiles({
    required FileCategory category,
    int pageSize = defaultPageSize,
  }) async {
    clearCategoryCache(category);
    return loadInitialFiles(category: category, pageSize: pageSize);
  }
  
  /// Check if more data is available for a category
  bool hasMoreData(FileCategory category) {
    return _hasMoreData[category] ?? true;
  }
  
  /// Check if currently loading for a category
  bool isLoading(FileCategory category) {
    return _isLoading[category] ?? false;
  }
  
  /// Get current page for a category
  int getCurrentPage(FileCategory category) {
    return _currentPage[category] ?? 0;
  }
}

/// Result class for paginated file loading
class PaginatedFileResult {
  final List<FileItem> files;
  final bool hasMore;
  final bool isLoading;
  final int totalCount;
  final int? newItemsCount;
  final String? error;
  
  PaginatedFileResult({
    required this.files,
    required this.hasMore,
    required this.isLoading,
    required this.totalCount,
    this.newItemsCount,
    this.error,
  });
  
  bool get hasError => error != null;
  bool get isEmpty => files.isEmpty && !isLoading;
  
  PaginatedFileResult copyWith({
    List<FileItem>? files,
    bool? hasMore,
    bool? isLoading,
    int? totalCount,
    int? newItemsCount,
    String? error,
  }) {
    return PaginatedFileResult(
      files: files ?? this.files,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      totalCount: totalCount ?? this.totalCount,
      newItemsCount: newItemsCount ?? this.newItemsCount,
      error: error ?? this.error,
    );
  }
}

/// Batch file operations helper
class BatchFileOperations {
  final FileRepository _fileRepository;
  
  BatchFileOperations(this._fileRepository);
  
  /// Delete files in batches to prevent memory issues
  Future<BatchOperationResult> deleteFilesInBatches({
    required List<String> fileIds,
    int batchSize = 50,
    void Function(int processed, int total)? onProgress,
  }) async {
    final totalFiles = fileIds.length;
    int processedCount = 0;
    int successCount = 0;
    final errors = <String>[];
    
    Logger.info('Starting batch deletion of $totalFiles files');
    
    // Process in batches
    for (int i = 0; i < totalFiles; i += batchSize) {
      final end = (i + batchSize > totalFiles) ? totalFiles : i + batchSize;
      final batch = fileIds.sublist(i, end);
      
      try {
        await _fileRepository.deleteFiles(batch);
        successCount += batch.length;
      } catch (e) {
        Logger.error('Failed to delete batch starting at index $i', e);
        errors.add('Failed to delete ${batch.length} files: ${e.toString()}');
      }
      
      processedCount = end;
      onProgress?.call(processedCount, totalFiles);
      
      // Small delay between batches to prevent overwhelming the system
      if (end < totalFiles) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    Logger.info(
      'Batch deletion completed. Success: $successCount, Failed: ${errors.length}',
    );
    
    return BatchOperationResult(
      totalCount: totalFiles,
      successCount: successCount,
      failedCount: totalFiles - successCount,
      errors: errors,
    );
  }
}

/// Result class for batch operations
class BatchOperationResult {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> errors;
  
  BatchOperationResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get isComplete => successCount == totalCount;
  double get successRate => totalCount > 0 ? successCount / totalCount : 0.0;
}