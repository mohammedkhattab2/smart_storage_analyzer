import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class GetStorageInfoUsecase {
  final StorageRepository repository;

  GetStorageInfoUsecase(this.repository);

  Future<StorageInfo> excute() async {
    return await repository.getStorageInfo();
  }
}
