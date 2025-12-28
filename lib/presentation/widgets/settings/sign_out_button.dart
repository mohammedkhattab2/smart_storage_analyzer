import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class SignOutButton extends StatelessWidget {
  final VoidCallback? onTap;
  const SignOutButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSize.paddingXSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSize.radiusMedium),
              border: Border.all(
                color: colorScheme.error.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingMedium,
                vertical: AppSize.paddingMedium + 4,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSize.radiusSmall),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onErrorContainer,
                      size: AppSize.iconSmall + 4,
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: Text(
                      AppStrings.signOut,
                      style: TextStyle(
                        fontSize: AppSize.fontLarge,
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
