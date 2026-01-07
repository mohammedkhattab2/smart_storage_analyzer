import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';

class GetCategoriesUseCase {
  final StorageRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<Category>> excute() async {
    return await repository.getCategories();
  }
}
