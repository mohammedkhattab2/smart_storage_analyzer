import 'package:smart_storage_analyzer/domain/entities/file_item.dart';

abstract class FileRepository {
  Future<List<FileItem>> getAllFiles();
  Future<List<FileItem>> getLargeFiles();
  Future<List<FileItem>> getDuplicateFiles();
  Future<List<FileItem>> getOldFiles();
  Future<void> deleteFiles(List<String> fileIds);
}
