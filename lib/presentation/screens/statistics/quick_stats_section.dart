import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';

class QuickStatsSection extends StatelessWidget {
  final double freeSpace;
  final double totalSpace;

  const QuickStatsSection({
    Key? key,
    required this.freeSpace,
    required this.totalSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickStats,
          style: TextStyle(
            fontSize: AppSize.fontLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSize.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppStrings.freeSpace,
                value: SizeFormatter.formateBytes(freeSpace.toInt()),
                color: AppColors.success,
              ),
            ),
            SizedBox(width: AppSize.paddingMedium),
            Expanded(
              child: _buildStatCard(
                title: AppStrings.totalSpace,
                value: SizeFormatter.formateBytes(totalSpace.toInt()),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    final parts = value.split(' ');
    final number = parts[0];
    final unit = parts.length > 1 ? parts[1] : '';

    return Container(
      padding: EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: AppSize.fontSmall,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: AppSize.paddingSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: AppSize.fontXXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: AppSize.fontMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}