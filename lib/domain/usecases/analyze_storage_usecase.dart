import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class AnalyzeStorageUsecase {
  final StorageRepository repository;

  AnalyzeStorageUsecase(this.repository);

  Future <void> excute() async {
     await repository.analyzeStorage();
  }
}
