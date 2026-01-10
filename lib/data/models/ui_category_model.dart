import 'package:smart_storage_analyzer/domain/entities/category.dart';

/// UI-specific category model that includes icon code and color value
/// This keeps UI concerns out of the domain layer
class UICategoryModel {
  final Category category;
  final int iconCode;
  final int colorValue;
  
  const UICategoryModel({
    required this.category,
    required this.iconCode,
    required this.colorValue,
  });
  
  /// Convert from domain category with UI mappings
  factory UICategoryModel.fromCategory(
    Category category, {
    required int iconCode,
    required int colorValue,
  }) {
    return UICategoryModel(
      category: category,
      iconCode: iconCode,
      colorValue: colorValue,
    );
  }
}