import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final String category;
  
  const CategoryDetailsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '$category Files\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}