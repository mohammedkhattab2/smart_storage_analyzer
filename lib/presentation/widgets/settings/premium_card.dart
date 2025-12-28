import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';

class PremiumCard extends StatelessWidget {
  final bool isPremium;
  final VoidCallback? onTap;
  const PremiumCard({super.key, required this.isPremium, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = colorScheme.premiumGradient;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingMedium,
        vertical: AppSize.paddingSmall,
      ),
      child: Material(
        elevation: 3,
        shadowColor: gradientColors.first.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.radiusLarge),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSize.paddingSmall + 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSize.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: AppSize.iconMedium,
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.goPremium,
                          style: const TextStyle(
                            fontSize: AppSize.fontXLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSize.paddingXSmall),
                        Text(
                          AppStrings.unlockPremium,
                          style: TextStyle(
                            fontSize: AppSize.fontMedium,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: AppSize.iconMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
