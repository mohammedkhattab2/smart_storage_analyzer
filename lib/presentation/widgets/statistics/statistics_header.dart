import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class StatisticsHeader extends StatelessWidget {
  const StatisticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.usageStatistics,
            style: TextStyle(
              fontSize: AppSize.fontXXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary, 
            ),
          ),
          Text(
            AppStrings.trackConsumption,
            style: TextStyle(
              fontSize: AppSize.fontMedium,
              color: AppColors.textSecondary,
            ),
          )
        ],
      ),
      );
  }
}