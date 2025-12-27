import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class DetailsSection extends StatelessWidget {
  const DetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.details,
        style: TextStyle(
          fontSize: AppSize.fontLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        ),
        TextButton(
          onPressed: (){
            // todo : navigate to detailed view
          }, 
          child: Text(AppStrings.viewAll,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppSize.fontMedium,
          ),
          ),
          )
      ],
    );
  }
}