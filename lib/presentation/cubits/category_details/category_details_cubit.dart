import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/category_viewmodel.dart';

class CategoryDetailsCubit extends Cubit<CategoryDetailsState> {
  final CategoryViewModel _categoryViewModel;
  Category? _currentCategory;
  
  CategoryDetailsCubit({
    required FileRepository fileRepository,
    required DeleteFilesUseCase deleteFilesUseCase,
  })  : _categoryViewModel = CategoryViewModel(
          fileRepository: fileRepository,
          deleteFilesUseCase: deleteFilesUseCase,
        ),
        super(CategoryDetailsInitial()) {
    // Listen to ViewModel changes
    _categoryViewModel.addListener(_onViewModelChanged);
  }

  // Expose loading state
  bool get isLoadingMore => _categoryViewModel.isLoadingMore;

  void _onViewModelChanged() {
    // Update state based on ViewModel state
    if (_categoryViewModel.isLoading) {
      emit(CategoryDetailsLoading());
    } else if (_categoryViewModel.errorMessage.isNotEmpty) {
      emit(CategoryDetailsError(_categoryViewModel.errorMessage));
    } else {
      emit(
        CategoryDetailsLoaded(
          files: _categoryViewModel.files,
          categoryName: _currentCategory?.name ?? '',
          totalSize: _categoryViewModel.totalSize,
          isSelectionMode: _categoryViewModel.isSelectionMode,
          selectedFileIds: _categoryViewModel.selectedFileIds,
        ),
      );
    }
  }

  Future<void> loadCategoryFiles(Category category, {bool forceReload = false}) async {
    _currentCategory = category;
    await _categoryViewModel.loadCategoryFiles(category, forceReload: forceReload);
  }

  Future<void> refresh(Category category) async {
    _currentCategory = category;
    await _categoryViewModel.refresh();
  }

  Future<void> deleteFile(FileItem file) async {
    await _categoryViewModel.deleteFile(file);
  }

  // Selection mode methods
  void toggleSelectionMode() {
    _categoryViewModel.toggleSelectionMode();
  }

  void selectFile(String fileId) {
    _categoryViewModel.toggleFileSelection(fileId);
  }

  void selectAllFiles() {
    _categoryViewModel.selectAllFiles();
  }

  void clearSelection() {
    _categoryViewModel.clearSelection();
  }

  void toggleAllFiles() {
    _categoryViewModel.toggleAllFiles();
  }

  // Action methods for selected files
  Future<void> deleteSelectedFiles() async {
    await _categoryViewModel.deleteSelectedFiles();
  }

  List<FileItem> getSelectedFiles() {
    return _categoryViewModel.selectedFiles;
  }

  // Load more files when scrolling
  Future<void> loadMoreFiles() async {
    await _categoryViewModel.loadMoreFiles();
  }

  @override
  Future<void> close() {
    _categoryViewModel.removeListener(_onViewModelChanged);
    _categoryViewModel.dispose();
    return super.close();
  }
}
