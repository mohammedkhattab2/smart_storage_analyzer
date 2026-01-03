
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.sizeInBytes,
    required int filesCount,
  }) : super(
         fileCount: filesCount,
       );
}
