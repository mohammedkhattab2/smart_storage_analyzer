import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';

class CategoryCardWidget extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  const CategoryCardWidget({super.key , required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          )
        ),
        padding: EdgeInsets.all(AppSize.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon,
            size: AppSize.iconLarge,
            color: category.color,
            ),
            SizedBox(height: AppSize.paddingSmall,),
            Text(category.name,
            style: TextStyle(
              fontSize: AppSize.fontMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            ),
            SizedBox(height: 4),
            Text("${category.fileCount} files",
            style: TextStyle(
              fontSize: AppSize.fontSmall,
              color: AppColors.textSecondary
            ),
            ),
            Text(
              SizeFormatter.formateBytes(category.sizeInBytes.toInt()),
              style: TextStyle(
                fontSize: AppSize.fontSmall,
                color: AppColors.textSecondary
              ),
            )
          ],
        ),
      ),
    );
  }
}
