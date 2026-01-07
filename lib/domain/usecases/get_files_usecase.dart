import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class GetFilesUseCase {
  final FileRepository repository;

  GetFilesUseCase(this.repository);

  Future<List<FileItem>> excute(FileCategory category) async {
    // Now all categories are handled directly by the repository
    // which calls the native Android implementation with proper category filtering
    return await repository.getFilesByCategory(category);
  }
}
