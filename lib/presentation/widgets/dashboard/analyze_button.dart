import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class AnalyzeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AnalyzeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed, 
        icon: Icon(AppIcons.analyze,
        size:20
         ),
         label: Text(AppStrings.analyzeClean,
         style: TextStyle(
          fontSize: AppSize.fontMedium,
          fontWeight: FontWeight.w600,
         ),
         ),
         style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.radiusLarge),
          ),
          elevation: 0,
         ),
        ),
    );
  }
}
