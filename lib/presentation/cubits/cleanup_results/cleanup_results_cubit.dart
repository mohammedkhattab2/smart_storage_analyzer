import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/cleanup_results_viewmodel.dart';

part 'cleanup_results_state.dart';

class CleanupResultsCubit extends Cubit<CleanupResultsState> {
  final CleanupResultsViewModel _viewModel;

  CleanupResultsCubit({required CleanupResultsViewModel viewModel})
      : _viewModel = viewModel,
        super(CleanupResultsInitial());

  void initialize(StorageAnalysisResults results) {
    emit(CleanupResultsLoaded(
      results: results,
      selectedCategories: {},
      selectedFiles: {},
    ));
  }

  void toggleCategorySelection(String categoryName) {
    final state = this.state;
    if (state is CleanupResultsLoaded) {
      final selectedCategories = Set<String>.from(state.selectedCategories);
      final selectedFiles = Map<String, Set<String>>.from(state.selectedFiles);
      
      if (selectedCategories.contains(categoryName)) {
        selectedCategories.remove(categoryName);
        selectedFiles.remove(categoryName);
      } else {
        selectedCategories.add(categoryName);
        // Select all files in the category
        final category = state.results.cleanupCategories
            .firstWhere((c) => c.name == categoryName);
        selectedFiles[categoryName] = category.files.map((f) => f.id).toSet();
      }
      
      emit(state.copyWith(
        selectedCategories: selectedCategories,
        selectedFiles: selectedFiles,
      ));
    }
  }

  void toggleFileSelection(String categoryName, String fileId) {
    final state = this.state;
    if (state is CleanupResultsLoaded) {
      final selectedFiles = Map<String, Set<String>>.from(state.selectedFiles);
      final categoryFiles = selectedFiles[categoryName] ?? {};
      
      if (categoryFiles.contains(fileId)) {
        categoryFiles.remove(fileId);
      } else {
        categoryFiles.add(fileId);
      }
      
      if (categoryFiles.isEmpty) {
        selectedFiles.remove(categoryName);
      } else {
        selectedFiles[categoryName] = categoryFiles;
      }
      
      emit(state.copyWith(selectedFiles: selectedFiles));
    }
  }

  void selectAll() {
    final state = this.state;
    if (state is CleanupResultsLoaded) {
      final selectedCategories = <String>{};
      final selectedFiles = <String, Set<String>>{};
      
      for (final category in state.results.cleanupCategories) {
        selectedCategories.add(category.name);
        selectedFiles[category.name] = category.files.map((f) => f.id).toSet();
      }
      
      emit(state.copyWith(
        selectedCategories: selectedCategories,
        selectedFiles: selectedFiles,
      ));
    }
  }

  void deselectAll() {
    final state = this.state;
    if (state is CleanupResultsLoaded) {
      emit(state.copyWith(
        selectedCategories: {},
        selectedFiles: {},
      ));
    }
  }

  Future<void> performCleanup() async {
    final state = this.state;
    if (state is CleanupResultsLoaded) {
      emit(CleanupInProgress(
        message: 'Preparing to clean files...',
        progress: 0.0,
      ));

      try {
        // Collect all selected files
        final filesToDelete = <FileItem>[];
        for (final entry in state.selectedFiles.entries) {
          final categoryName = entry.key;
          final fileIds = entry.value;
          
          final category = state.results.cleanupCategories
              .firstWhere((c) => c.name == categoryName);
          
          filesToDelete.addAll(
            category.files.where((f) => fileIds.contains(f.id)),
          );
        }

        // Perform actual file deletion
        final success = await _viewModel.deleteFiles(filesToDelete);
        
        if (!success) {
          emit(const CleanupError(
            message: 'Some files could not be deleted. Please check permissions.',
          ));
          return;
        }

        // Calculate freed space
        final freedSpace = filesToDelete.fold(
          0,
          (sum, file) => sum + file.sizeInBytes,
        );

        emit(CleanupCompleted(
          filesDeleted: filesToDelete.length,
          spaceFreed: freedSpace,
        ));
      } catch (e) {
        emit(CleanupError(
          message: 'Failed to clean files: ${e.toString()}',
        ));
      }
    }
  }
}