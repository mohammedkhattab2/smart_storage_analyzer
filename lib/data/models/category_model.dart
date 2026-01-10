import '../../domain/entities/category.dart';

/// Data model for Category that extends the domain entity
/// This model is used for data layer operations
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.sizeInBytes,
    required int filesCount,
  }) : super(
    fileCount: filesCount,
  );
  
  /// Factory constructor for creating from domain entity
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      sizeInBytes: entity.sizeInBytes,
      filesCount: entity.fileCount,
    );
  }
}
