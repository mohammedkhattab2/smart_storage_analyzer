import 'package:smart_storage_analyzer/domain/entities/category.dart';

class AllCategoriesViewModel {
  AllCategoriesViewModel();

  // Add any category-specific business logic here
  List<Category> sortCategoriesBySize(List<Category> categories) {
    return List<Category>.from(categories)
      ..sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
  }

  double calculateCategoryPercentage(Category category, int totalStorage) {
    if (totalStorage == 0) return 0.0;
    return (category.sizeInBytes / totalStorage) * 100;
  }
}
