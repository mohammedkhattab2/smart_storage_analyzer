import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';

class DeleteFilesUseCase {
  final FileRepository repository;

  DeleteFilesUseCase(this.repository);

  Future<void> execute(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await repository.deleteFiles(fileIds);
  }
}
