import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
    required double sizeInBytes,
    required int filesCount,
  }) : super(
          id: id,
          name: name,
          icon: icon,
          color: color,
          sizeInBytes: sizeInBytes,
          fileCount: filesCount,
        );

  static List<CategoryModel> getDefaultCategories() {
    return [
      CategoryModel(
        id: 'images',
        name: 'Images',
        icon: AppIcons.images,
        color: AppColors.imageColor,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'videos',
        name: 'Videos',
        icon: AppIcons.videos,
        color: AppColors.videosColor,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'audio',
        name: 'Audio',
        icon: AppIcons.audio,
        color: AppColors.audioColor,
        sizeInBytes: 104857600, // 0.1 GB من الصورة
        filesCount: 8,
      ),
      CategoryModel(
        id: 'documents',
        name: 'Documents',
        icon: AppIcons.documents,
        color: AppColors.documentsColor,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'apps',
        name: 'Apps',
        icon: AppIcons.apps,
        color: AppColors.appsColor,
        sizeInBytes: 0.0,
        filesCount: 0,
      ),
      CategoryModel(
        id: 'others',
        name: 'Others',
        icon: AppIcons.others,
        color: AppColors.othersColor,
        sizeInBytes: 214748364800, // 0.2 GB من الصورة
        filesCount: 7,
      ),
    ];
  }
}