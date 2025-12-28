import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSize.paddingLarge),
      child: Column(
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: AppSize.paddingLarge),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            ),
          ),
          SizedBox(height: AppSize.paddingLarge),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSize.paddingMedium,
              mainAxisSpacing: AppSize.paddingMedium,
              childAspectRatio: 1.1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSize.radiusMedium),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
