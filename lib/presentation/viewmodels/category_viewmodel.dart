import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:smart_storage_analyzer/core/services/paginated_file_loader.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

/// Unified ViewModel for category file operations
/// Ensures categories use the same source of truth as File Manager
class CategoryViewModel extends ChangeNotifier {
  final FileRepository _fileRepository;
  final DeleteFilesUseCase _deleteFilesUseCase;
  late final PaginatedFileLoader _paginatedLoader;
  late final BatchFileOperations _batchOperations;

  // State
  List<FileItem> _files = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  Category? _currentCategory;
  final Set<String> _selectedFileIds = {};
  bool _hasMoreData = true;
  int _totalFileCount = 0;
  double _deleteProgress = 0.0;
  bool _isDeletingFiles = false;

  // Selection mode
  bool _isSelectionMode = false;

  CategoryViewModel({
    required FileRepository fileRepository,
    required DeleteFilesUseCase deleteFilesUseCase,
  })  : _fileRepository = fileRepository,
        _deleteFilesUseCase = deleteFilesUseCase {
    _paginatedLoader = PaginatedFileLoader(_fileRepository);
    _batchOperations = BatchFileOperations(_fileRepository);
  }

  // Getters
  List<FileItem> get files => _files;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _errorMessage;
  Category? get currentCategory => _currentCategory;
  Set<String> get selectedFileIds => Set.from(_selectedFileIds);
  bool get hasMoreData => _hasMoreData;
  int get totalFileCount => _totalFileCount;
  double get deleteProgress => _deleteProgress;
  bool get isDeletingFiles => _isDeletingFiles;
  bool get isSelectionMode => _isSelectionMode;
  bool get hasSelection => _selectedFileIds.isNotEmpty;
  int get selectedCount => _selectedFileIds.length;

  /// Get total size of loaded files
  int get totalSize => _files.fold<int>(0, (sum, file) => sum + file.sizeInBytes);

  /// Get selected files
  List<FileItem> get selectedFiles {
    return _files.where((file) => _selectedFileIds.contains(file.id)).toList();
  }

  /// Get total size of selected files
  int get selectedSize => selectedFiles.fold<int>(
        0,
        (sum, file) => sum + file.sizeInBytes,
      );

  /// Load files for a category using the same source as File Manager
  Future<void> loadCategoryFiles(Category category, {bool forceReload = false}) async {
    if (_isLoading && _currentCategory?.id == category.id && !forceReload) {
      Logger.info('Already loading ${category.name}, skipping duplicate request');
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    _currentCategory = category;
    _selectedFileIds.clear();
    _isSelectionMode = false;
    notifyListeners();

    try {
      // Convert category name to FileCategory enum
      final fileCategory = _mapCategoryToFileCategory(category.name);

      // Use the same PaginatedFileLoader as File Manager
      final result = await _paginatedLoader.loadInitialFiles(
        category: fileCategory,
        pageSize: 100, // Larger page size for categories
      );

      _files = result.files;
      _hasMoreData = result.hasMore;
      _totalFileCount = result.totalCount;

      if (result.hasError) {
        _errorMessage = result.error ?? 'Failed to load files';
      }

      Logger.info(
        'Loaded ${_files.length} files for category: ${category.name}. '
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
    if (_isLoadingMore || !_hasMoreData || _isLoading || _currentCategory == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final fileCategory = _mapCategoryToFileCategory(_currentCategory!.name);
      
      final result = await _paginatedLoader.loadMoreFiles(
        category: fileCategory,
        pageSize: 100,
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

  /// Refresh current category
  Future<void> refresh() async {
    if (_currentCategory == null) return;
    
    _selectedFileIds.clear();
    _isSelectionMode = false;
    final fileCategory = _mapCategoryToFileCategory(_currentCategory!.name);
    await _paginatedLoader.refreshFiles(category: fileCategory);
    await loadCategoryFiles(_currentCategory!, forceReload: true);
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedFileIds.clear();
    }
    Logger.info('Selection mode: $_isSelectionMode');
    notifyListeners();
  }

  /// Select/deselect a file
  void toggleFileSelection(String fileId) {
    if (_selectedFileIds.contains(fileId)) {
      _selectedFileIds.remove(fileId);
    } else {
      _selectedFileIds.add(fileId);
    }

    // Exit selection mode if no files are selected
    if (_selectedFileIds.isEmpty && _isSelectionMode) {
      _isSelectionMode = false;
    }

    notifyListeners();
  }

  /// Select all files
  void selectAllFiles() {
    _selectedFileIds.clear();
    _selectedFileIds.addAll(_files.map((file) => file.id));
    _isSelectionMode = true;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedFileIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// Toggle all files selection
  void toggleAllFiles() {
    if (_selectedFileIds.length == _files.length && _files.isNotEmpty) {
      clearSelection();
    } else {
      selectAllFiles();
    }
  }

  /// Check if a file is selected
  bool isFileSelected(String fileId) => _selectedFileIds.contains(fileId);

  /// Delete a single file
  Future<void> deleteFile(FileItem file) async {
    try {
      Logger.info('Deleting file: ${file.name}');
      
      await _deleteFilesUseCase.execute([file.id]);
      
      // Remove from list
      _files.removeWhere((f) => f.id == file.id);
      _selectedFileIds.remove(file.id);
      _totalFileCount = _totalFileCount > 0 ? _totalFileCount - 1 : 0;
      
      Logger.success('File deleted successfully: ${file.name}');
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to delete file', e);
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Delete selected files
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
        await _deleteFilesUseCase.execute(fileIds);
        _deleteProgress = 1.0;
        Logger.info('Deleted ${fileIds.length} files successfully');
      }

      // Remove deleted files from the list
      _files.removeWhere((file) => _selectedFileIds.contains(file.id));
      
      // Update total count
      _totalFileCount = _totalFileCount - fileIds.length;
      if (_totalFileCount < 0) _totalFileCount = 0;
      
      // Clear selection and exit selection mode
      _selectedFileIds.clear();
      _isSelectionMode = false;
    } catch (e) {
      _errorMessage = 'Failed to delete files: ${e.toString()}';
      Logger.error(_errorMessage, e);
    } finally {
      _isDeletingFiles = false;
      _deleteProgress = 0.0;
      notifyListeners();
    }
  }

  /// Map category name to FileCategory enum
  FileCategory _mapCategoryToFileCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'images':
      case 'image':
        return FileCategory.images;
      case 'videos':
      case 'video':
        return FileCategory.videos;
      case 'audio':
      case 'music':
        return FileCategory.audio;
      case 'documents':
      case 'document':
        return FileCategory.documents;
      case 'apps':
      case 'applications':
        return FileCategory.apps;
      case 'all':
        return FileCategory.all;
      case 'large':
        return FileCategory.large;
      case 'duplicates':
        return FileCategory.duplicates;
      case 'old':
        return FileCategory.old;
      default:
        return FileCategory.others;
    }
  }

  /// Clear cache for current category
  void clearCache() {
    if (_currentCategory != null) {
      final fileCategory = _mapCategoryToFileCategory(_currentCategory!.name);
      _paginatedLoader.clearCategoryCache(fileCategory);
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}