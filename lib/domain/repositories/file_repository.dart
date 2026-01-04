import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

abstract class FileRepository {
  Future<List<FileItem>> getAllFiles();
  Future<List<FileItem>> getLargeFiles();
  Future<List<FileItem>> getDuplicateFiles();
  Future<List<FileItem>> getOldFiles();
  Future<List<FileItem>> getImageFiles();
  Future<List<FileItem>> getVideoFiles();
  Future<List<FileItem>> getAudioFiles();
  Future<List<FileItem>> getDocumentFiles();
  Future<List<FileItem>> getAppFiles();
  Future<List<FileItem>> getOtherFiles();
  Future<List<FileItem>> getFilesByCategory(FileCategory category);
  Future<List<FileItem>> getFilesByCategoryPaginated({
    required FileCategory category,
    required int page,
    required int pageSize,
  });
  Future<int> getFilesCount(FileCategory category);
  Future<void> deleteFiles(List<String> fileIds);
}
