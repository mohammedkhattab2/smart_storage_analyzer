import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

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
}
