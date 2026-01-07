import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/optimized_file_manager_viewmodel.dart';

// States
abstract class OptimizedFileManagerState {}

class FileManagerInitial extends OptimizedFileManagerState {}

class FileManagerLoading extends OptimizedFileManagerState {
  final FileCategory category;
  FileManagerLoading(this.category);
}

class FileManagerLoaded extends OptimizedFileManagerState {
  final List<FileItem> files;
  final FileCategory currentCategory;
  final Set<String> selectedFileIds;
  final bool hasMoreData;
  final int totalCount;
  final bool isLoadingMore;
  final String? errorMessage;

  FileManagerLoaded({
    required this.files,
    required this.currentCategory,
    required this.selectedFileIds,
    required this.hasMoreData,
    required this.totalCount,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  int get selectedCount => selectedFileIds.length;
  List<FileItem> get selectedFiles => 
      files.where((file) => selectedFileIds.contains(file.id)).toList();
  
  int get selectedTotalSize => selectedFiles.fold<int>(
    0, 
    (sum, file) => sum + file.sizeInBytes,
  );

  FileManagerLoaded copyWith({
    List<FileItem>? files,
    FileCategory? currentCategory,
    Set<String>? selectedFileIds,
    bool? hasMoreData,
    int? totalCount,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return FileManagerLoaded(
      files: files ?? this.files,
      currentCategory: currentCategory ?? this.currentCategory,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FileManagerDeleting extends OptimizedFileManagerState {
  final double progress;
  final String message;

  FileManagerDeleting({
    required this.progress,
    required this.message,
  });
}

class FileManagerError extends OptimizedFileManagerState {
  final String message;
  final FileCategory? lastCategory;

  FileManagerError({
    required this.message,
    this.lastCategory,
  });
}

// Cubit
class OptimizedFileManagerCubit extends Cubit<OptimizedFileManagerState> {
  final OptimizedFileManagerViewModel _viewModel;
  
  OptimizedFileManagerCubit(this._viewModel) : super(FileManagerInitial()) {
    // Listen to viewmodel changes
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    // Update state based on viewmodel state
    if (_viewModel.isLoading && state is! FileManagerLoading) {
      emit(FileManagerLoading(_viewModel.currentCategory));
    } else if (_viewModel.isDeletingFiles) {
      emit(FileManagerDeleting(
        progress: _viewModel.deleteProgress,
        message: 'Deleting ${(_viewModel.deleteProgress * 100).toInt()}%',
      ));
    } else if (_viewModel.errorMessage.isNotEmpty && state is! FileManagerError) {
      emit(FileManagerError(
        message: _viewModel.errorMessage,
        lastCategory: _viewModel.currentCategory,
      ));
    } else if (!_viewModel.isLoading && 
               !_viewModel.isDeletingFiles && 
               _viewModel.errorMessage.isEmpty) {
      emit(FileManagerLoaded(
        files: _viewModel.files,
        currentCategory: _viewModel.currentCategory,
        selectedFileIds: _viewModel.selectedFileIds,
        hasMoreData: _viewModel.hasMoreData,
        totalCount: _viewModel.totalFileCount,
        isLoadingMore: _viewModel.isLoadingMore,
      ));
    }
  }

  /// Load files for a category
  Future<void> loadFiles(FileCategory category) async {
    try {
      Logger.info('Loading files for category: $category');
      await _viewModel.loadFiles(category);
    } catch (e) {
      Logger.error('Error loading files', e);
      emit(FileManagerError(
        message: 'Failed to load files: ${e.toString()}',
        lastCategory: category,
      ));
    }
  }

  /// Load more files (pagination)
  Future<void> loadMoreFiles() async {
    final currentState = state;
    if (currentState is FileManagerLoaded && 
        currentState.hasMoreData && 
        !currentState.isLoadingMore) {
      try {
        await _viewModel.loadMoreFiles();
      } catch (e) {
        Logger.error('Error loading more files', e);
      }
    }
  }

  /// Change category
  Future<void> changeCategory(FileCategory category) async {
    final currentState = state;
    if (currentState is FileManagerLoaded && 
        currentState.currentCategory != category) {
      await loadFiles(category);
    }
  }

  /// Toggle file selection
  void toggleFileSelection(String fileId) {
    _viewModel.toggleFileSelection(fileId);
  }

  /// Clear selection
  void clearSelection() {
    _viewModel.clearSelection();
  }

  /// Select all files
  void selectAll() {
    _viewModel.selectAll();
  }

  /// Toggle select all
  void toggleSelectAll() {
    _viewModel.toggleSelectAll();
  }

  /// Delete selected files
  Future<void> deleteSelectedFiles() async {
    try {
      await _viewModel.deleteSelectedFiles();
      
      // After successful deletion, emit updated state
      if (state is FileManagerLoaded) {
        emit(FileManagerLoaded(
          files: _viewModel.files,
          currentCategory: _viewModel.currentCategory,
          selectedFileIds: _viewModel.selectedFileIds,
          hasMoreData: _viewModel.hasMoreData,
          totalCount: _viewModel.totalFileCount,
        ));
      }
    } catch (e) {
      Logger.error('Error deleting files', e);
      emit(FileManagerError(
        message: 'Failed to delete files: ${e.toString()}',
        lastCategory: _viewModel.currentCategory,
      ));
    }
  }

  /// Refresh current category
  Future<void> refresh() async {
    await _viewModel.refresh();
  }

  /// Clear cache
  void clearCache() {
    _viewModel.clearCache();
  }

  @override
  Future<void> close() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    return super.close();
  }
}