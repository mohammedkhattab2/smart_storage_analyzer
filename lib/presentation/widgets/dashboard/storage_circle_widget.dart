import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/number_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';

class StorageCircleWidget extends StatelessWidget {
  final StorageInfo storageInfo;
  const StorageCircleWidget({super.key, required this.storageInfo});

  @override
  Widget build(BuildContext context) {
    final percentage = storageInfo.usagePercentage / 100;
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withValues(alpha: 0.8),

          ]
          ),
          borderRadius: BorderRadius.circular(AppSize.radiusLarge)
      ),
      child: Center(
        child: CircularPercentIndicator(
          radius: 100,
          lineWidth: 12,
          animation: true,
          animationDuration: 1000,
          percent: percentage.clamp(0.0, 1.0).toDouble(),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(NumberFormatter.formatLargeNumber(storageInfo.usedSpace.toInt()),
              style: TextStyle(
                fontSize: AppSize.fontLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, 
              ),
              ),
              SizedBox(height: 4,),
              Text("USED",
              style: TextStyle(
                fontSize: AppSize.fontSmall,
                color: AppColors.textSecondary,
                letterSpacing: 1.2  
              ),
              ) ,
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: AppColors.primary,
          backgroundColor: AppColors.cardBackground.withValues(alpha: 0.5),  
        ),
        
      ),
    );
  }
}
