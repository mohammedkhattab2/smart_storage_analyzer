import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';

class DeleteFilesUsecase {
  final FileRepository repository;

  DeleteFilesUsecase(this.repository);

  Future<void> excute(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await repository.deleteFiles(fileIds);
  }
}
