import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class FileManagerViewmodel {
  final GetFilesUsecase getFilesUsecase;
  final DeleteFilesUsecase deleteFilesUsecase;
  List<FileItem> _allFiles = [];
  final Set<String> _selectedFileIds = {};
  FileCategory _currentCategory = FileCategory.all;

  FileManagerViewmodel({
    required this.getFilesUsecase,
    required this.deleteFilesUsecase,
  });

  Future<List<FileItem>> getFiles(FileCategory category) async {
    try {
      _currentCategory = category;
      _allFiles = await getFilesUsecase.excute(category);
      return _allFiles;
    } catch (e) {
      print('Error in ViewModel getting files: $e');
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

  Future<void> deleteSelectedFiles() async {
    if (_selectedFileIds.isEmpty) return;
    try {
      await deleteFilesUsecase.excute(_selectedFileIds.toList());
      _allFiles.removeWhere((file) => _selectedFileIds.contains(file.id));
      _selectedFileIds.clear();
    } catch (e) {
      print('Error deleting files: $e');
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
}
