import 'package:flutter/foundation.dart';
import 'package:smart_storage_analyzer/core/services/paginated_file_loader.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

/// Optimized file manager viewmodel with lazy loading and pagination
class OptimizedFileManagerViewModel extends ChangeNotifier {
  final DeleteFilesUseCase _deleteFilesUsecase;
  final FileRepository _fileRepository;
  late final PaginatedFileLoader _paginatedLoader;
  late final BatchFileOperations _batchOperations;

  // State
  List<FileItem> _files = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isDeletingFiles = false;
  String _errorMessage = '';
  FileCategory _currentCategory = FileCategory.all;
  final Set<String> _selectedFileIds = {};
  bool _hasMoreData = true;
  int _totalFileCount = 0;
  double _deleteProgress = 0.0;

  OptimizedFileManagerViewModel({
    required GetFilesUseCase getFilesUsecase,
    required DeleteFilesUseCase deleteFilesUsecase,
    required FileRepository fileRepository,
  })  : _deleteFilesUsecase = deleteFilesUsecase,
        _fileRepository = fileRepository {
    _paginatedLoader = PaginatedFileLoader(_fileRepository);
    _batchOperations = BatchFileOperations(_fileRepository);
  }

  // Getters
  List<FileItem> get files => _files;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isDeletingFiles => _isDeletingFiles;
  String get errorMessage => _errorMessage;
  FileCategory get currentCategory => _currentCategory;
  Set<String> get selectedFileIds => Set.from(_selectedFileIds);
  bool get hasMoreData => _hasMoreData;
  int get totalFileCount => _totalFileCount;
  double get deleteProgress => _deleteProgress;
  bool get hasSelectedFiles => _selectedFileIds.isNotEmpty;
  int get selectedCount => _selectedFileIds.length;
  bool get isAllSelected =>
      _files.isNotEmpty && _selectedFileIds.length == _files.length;

  /// Get selected files
  List<FileItem> get selectedFiles {
    return _files.where((file) => _selectedFileIds.contains(file.id)).toList();
  }

  /// Get selection info
  Map<String, dynamic> getSelectionInfo() {
    final selectedFiles = this.selectedFiles;
    final totalSize = selectedFiles.fold<int>(
      0,
      (sum, file) => sum + file.sizeInBytes,
    );
    return {
      'count': _selectedFileIds.length,
      'size': totalSize,
      'files': selectedFiles,
    };
  }

  /// Load files with pagination
  Future<void> loadFiles(FileCategory category) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    _currentCategory = category;
    _selectedFileIds.clear();
    notifyListeners();

    try {
      final result = await _paginatedLoader.loadInitialFiles(
        category: category,
        pageSize: 50,
      );

      _files = result.files;
      _hasMoreData = result.hasMore;
      _totalFileCount = result.totalCount;

      if (result.hasError) {
        _errorMessage = result.error ?? 'Failed to load files';
      }

      Logger.info(
        'Loaded ${_files.length} files for category: $category. '
        'Total: $_totalFileCount, Has more: $_hasMoreData',
      );
    } catch (e) {
      _errorMessage = 'Failed to load files: ${e.toString()}';
      Logger.error(_errorMessage, e);
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more files (pagination)
  Future<void> loadMoreFiles() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _paginatedLoader.loadMoreFiles(
        category: _currentCategory,
        pageSize: 50,
      );

      _files = result.files;
      _hasMoreData = result.hasMore;
      _totalFileCount = result.totalCount;

      if (result.hasError) {
        _errorMessage = result.error ?? 'Failed to load more files';
      }

      Logger.info(
        'Loaded more files. Total: ${_files.length}, Has more: $_hasMoreData',
      );
    } catch (e) {
      _errorMessage = 'Failed to load more files: ${e.toString()}';
      Logger.error(_errorMessage, e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Toggle file selection
  void toggleFileSelection(String fileId) {
    if (_selectedFileIds.contains(fileId)) {
      _selectedFileIds.remove(fileId);
    } else {
      _selectedFileIds.add(fileId);
    }
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedFileIds.clear();
    notifyListeners();
  }

  /// Select all files
  void selectAll() {
    _selectedFileIds.clear();
    _selectedFileIds.addAll(_files.map((file) => file.id));
    notifyListeners();
  }

  /// Toggle select all
  void toggleSelectAll() {
    if (_selectedFileIds.length == _files.length && _files.isNotEmpty) {
      // All files are selected, so deselect all
      _selectedFileIds.clear();
    } else {
      // Not all files are selected, so select all
      _selectedFileIds.clear();
      _selectedFileIds.addAll(_files.map((file) => file.id));
    }
    notifyListeners();
  }

  /// Delete selected files with batch processing
  Future<void> deleteSelectedFiles() async {
    if (_selectedFileIds.isEmpty || _isDeletingFiles) return;

    _isDeletingFiles = true;
    _deleteProgress = 0.0;
    _errorMessage = '';
    notifyListeners();

    try {
      final fileIds = _selectedFileIds.toList();

      // Use batch operations for large selections
      if (fileIds.length > 100) {
        final result = await _batchOperations.deleteFilesInBatches(
          fileIds: fileIds,
          batchSize: 50,
          onProgress: (processed, total) {
            _deleteProgress = processed / total;
            notifyListeners();
          },
        );

        if (result.hasErrors) {
          _errorMessage = 'Some files failed to delete: ${result.failedCount} failed';
        }

        Logger.info(
          'Batch deletion completed. Success: ${result.successCount}, '
          'Failed: ${result.failedCount}',
        );
      } else {
        // Regular deletion for smaller sets
        await _deleteFilesUsecase.execute(fileIds);
        _deleteProgress = 1.0;
        Logger.info('Deleted ${fileIds.length} files successfully');
      }

      // Remove deleted files from the list
      _files.removeWhere((file) => _selectedFileIds.contains(file.id));
      _selectedFileIds.clear();

      // Update total count
      _totalFileCount = _totalFileCount - fileIds.length;
      if (_totalFileCount < 0) _totalFileCount = 0;
    } catch (e) {
      _errorMessage = 'Failed to delete files: ${e.toString()}';
      Logger.error(_errorMessage, e);
    } finally {
      _isDeletingFiles = false;
      _deleteProgress = 0.0;
      notifyListeners();
    }
  }

  /// Refresh current category
  Future<void> refresh() async {
    _selectedFileIds.clear();
    await _paginatedLoader.refreshFiles(category: _currentCategory);
    await loadFiles(_currentCategory);
  }

  /// Clear all cached data
  void clearCache() {
    _paginatedLoader.clearAllCache();
  }

  /// Get files synchronously (for compatibility)
  Future<List<FileItem>> getFiles(FileCategory category) async {
    await loadFiles(category);
    return _files;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}