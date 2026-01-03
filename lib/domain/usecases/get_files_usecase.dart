import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class GetFilesUsecase {
  final FileRepository repository;

  GetFilesUsecase(this.repository);

  Future<List<FileItem>> excute(FileCategory category) async {
    switch (category) {
      case FileCategory.all:
        return await repository.getAllFiles();
      case FileCategory.large:
        return await repository.getLargeFiles();
      case FileCategory.duplicates:
        return await repository.getDuplicateFiles();
      case FileCategory.old:
        return await repository.getOldFiles();
      default:
        // For other categories (images, videos, etc.), filter by file extension
        final allFiles = await repository.getAllFiles();
        return allFiles.where((file) => file.category == category).toList();
    }
  }
}
