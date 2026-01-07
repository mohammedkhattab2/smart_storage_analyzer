import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class FileManagerViewModel {
  final GetFilesUseCase getFilesUsecase;
  final DeleteFilesUseCase deleteFilesUsecase;
  List<FileItem> _allFiles = [];
  final Set<String> _selectedFileIds = {};
  FileCategory _currentCategory = FileCategory.all;

  FileManagerViewModel({
    required this.getFilesUsecase,
    required this.deleteFilesUsecase,
  });

  Future<List<FileItem>> getFiles(FileCategory category) async {
    try {
      _currentCategory = category;
      _allFiles = await getFilesUsecase.excute(category);
      return _allFiles;
    } catch (e) {
      Logger.error('Error in ViewModel getting files', e);
      rethrow;
    }
  }

  // toggle file selection
  Set<String> toggleFileSelection(String fileId) {
    if (_selectedFileIds.contains(fileId)) {
      _selectedFileIds.remove(fileId);
    } else {
      _selectedFileIds.add(fileId);
    }
    return Set.from(_selectedFileIds);
  }

  Set<String> clearSelection() {
    _selectedFileIds.clear();
    return Set.from(_selectedFileIds);
  }

  // Select all files
  Set<String> selectAll() {
    _selectedFileIds.clear();
    _selectedFileIds.addAll(_allFiles.map((file) => file.id));
    return Set.from(_selectedFileIds);
  }

  // Toggle select all - if all are selected, deselect all; otherwise select all
  Set<String> toggleSelectAll() {
    if (_selectedFileIds.length == _allFiles.length && _allFiles.isNotEmpty) {
      // All files are selected, so deselect all
      _selectedFileIds.clear();
    } else {
      // Not all files are selected, so select all
      _selectedFileIds.clear();
      _selectedFileIds.addAll(_allFiles.map((file) => file.id));
    }
    return Set.from(_selectedFileIds);
  }

  Future<void> deleteSelectedFiles() async {
    if (_selectedFileIds.isEmpty) return;
    try {
      await deleteFilesUsecase.execute(_selectedFileIds.toList());
      _allFiles.removeWhere((file) => _selectedFileIds.contains(file.id));
      _selectedFileIds.clear();
    } catch (e) {
      Logger.error('Error deleting files', e);
      rethrow;
    }
  }

  /// get selected files info
  Map<String, dynamic> getSelectionInfo() {
    final selectedFiles = _allFiles
        .where((file) => _selectedFileIds.contains(file.id))
        .toList();
    final totalSize = selectedFiles.fold<int>(
      0,
      (sum, file) => sum + file.sizeInBytes,
    );
    return {'count': _selectedFileIds.length, 'size': totalSize};
  }

  FileCategory get currentCategory => _currentCategory;
  Set<String> get selectedFileIds => Set.from(_selectedFileIds);

  /// Clear all data to free memory
  void clearData() {
    _allFiles.clear();
    _selectedFileIds.clear();
  }

  /// Dispose resources
  void dispose() {
    clearData();
  }
}
