import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/data/models/ui_category_model.dart';

/// Maps domain Category entities to UI models with icon and color data
/// This keeps UI concerns out of the domain layer
class CategoryUIMapper {
  static final Map<String, IconData> _categoryIcons = {
    'images': AppIcons.images,
    'videos': AppIcons.videos,
    'audio': AppIcons.audio,
    'documents': AppIcons.documents,
    'apps': AppIcons.apps,
    'others': AppIcons.others,
  };

  static final Map<String, Color> _categoryColors = {
    'images': AppColorSchemes.imageCategoryLight,
    'videos': AppColorSchemes.videoCategoryLight,
    'audio': AppColorSchemes.audioCategoryLight,
    'documents': AppColorSchemes.documentCategoryLight,
    'apps': AppColorSchemes.appsCategoryLight,
    'others': AppColorSchemes.othersCategoryLight,
  };

  /// Convert domain Category to UI model with icon and color
  static UICategoryModel toUIModel(Category category) {
    final icon = _categoryIcons[category.id] ?? Icons.folder;
    final color = _categoryColors[category.id] ?? Colors.grey;
    
    return UICategoryModel(
      category: category,
      iconCode: icon.codePoint,
      colorValue: color.toARGB32(),
    );
  }
  
  /// Convert list of domain categories to UI models
  static List<UICategoryModel> toUIModels(List<Category> categories) {
    return categories.map((category) => toUIModel(category)).toList();
  }
  
  /// Get icon for category ID
  static IconData getIcon(String categoryId) {
    return _categoryIcons[categoryId] ?? Icons.folder;
  }
  
  /// Get color for category ID
  static Color getColor(String categoryId) {
    return _categoryColors[categoryId] ?? Colors.grey;
  }
}