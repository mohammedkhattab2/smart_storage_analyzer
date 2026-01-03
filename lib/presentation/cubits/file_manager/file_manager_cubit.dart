import 'package:flutter_bloc/flutter_bloc.dart';
import 'file_manager_state.dart';
import '../../viewmodels/file_manager_viewmodel.dart';
import '../../../domain/value_objects/file_category.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/logger.dart';

class FileManagerCubit extends Cubit<FileManagerState> {
  final FileManagerViewmodel viewModel;
  final PermissionService _permissionService = PermissionService();

  FileManagerCubit({required this.viewModel}) : super(FileManagerInitial());

  /// Load files by category
  Future<void> loadFiles(FileCategory category) async {
    emit(FileManagerLoading());

    try {
      // Check and request storage permission first
      final hasPermission = await _permissionService.hasStoragePermission();

      if (!hasPermission) {
        Logger.warning('No storage permission, requesting...');
        final granted = await _permissionService.requestStoragePermission();

        if (!granted) {
          emit(
            const FileManagerError(
              'Storage permission is required to view files. '
              'Please grant permission in settings.',
            ),
          );
          return;
        }
      }

      // Load files after permission is granted
      final files = await viewModel.getFiles(category);

      emit(
        FileManagerLoaded(
          files: files,
          currentCategory: category,
          selectedFileIds: viewModel.selectedFileIds,
        ),
      );

      Logger.success(
        'Loaded ${files.length} files for category: ${category.name}',
      );
    } catch (e) {
      Logger.error('Failed to load files', e);
      emit(FileManagerError('Failed to load files: ${e.toString()}'));
    }
  }

  /// Change category
  void changeCategory(FileCategory category) {
    viewModel.clearSelection();
    loadFiles(category);
  }

  /// Toggle file selection
  void toggleFileSelection(String fileId) {
    if (state is FileManagerLoaded) {
      final currentState = state as FileManagerLoaded;
      final newSelectedIds = viewModel.toggleFileSelection(fileId);

      emit(currentState.copyWith(selectedFileIds: newSelectedIds));
    }
  }

  /// Select all files
  void selectAll() {
    if (state is FileManagerLoaded) {
      final currentState = state as FileManagerLoaded;
      final newSelectedIds = viewModel.selectAll();

      emit(currentState.copyWith(selectedFileIds: newSelectedIds));
    }
  }

  /// Clear selection
  void clearSelection() {
    if (state is FileManagerLoaded) {
      final currentState = state as FileManagerLoaded;
      viewModel.clearSelection();

      emit(currentState.copyWith(selectedFileIds: {}));
    }
  }

  /// Delete selected files
  Future<void> deleteSelectedFiles() async {
    if (state is FileManagerLoaded) {
      final currentState = state as FileManagerLoaded;

      emit(FileManagerDeleting());

      try {
        await viewModel.deleteSelectedFiles();

        // Reload files
        await loadFiles(currentState.currentCategory);
      } catch (e) {
        emit(FileManagerError('Failed to delete files'));
      }
    }
  }

  /// Refresh files
  Future<void> refresh() async {
    if (state is FileManagerLoaded) {
      final currentState = state as FileManagerLoaded;
      await loadFiles(currentState.currentCategory);
    }
  }
}
