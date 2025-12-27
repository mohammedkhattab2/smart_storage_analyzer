import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/custom_button.dart';

class ErrorT extends StatelessWidget {
  final String message;
  final VoidCallback onRetry; 
  const ErrorT({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
            size: 64,
            color: AppColors.error,
            ),
            SizedBox( height: AppSize.paddingLarge),
            Text(
               message,
               textAlign: TextAlign.center,
               style: TextStyle(
                fontSize: AppSize.fontLarge,
                color: AppColors.textPrimary,
               ),
            ),
            SizedBox( height: AppSize.paddingLarge),
            CustomButton(
              text: "Retry", 
              icon:  Icons.refresh,
              onPressed: onRetry
              )
          ],
        ),
        ),
    );
  }
}
