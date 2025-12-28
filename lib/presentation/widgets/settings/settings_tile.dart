import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

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
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSize.radiusMedium),
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
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSize.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.onPrimaryContainer,
                      size: AppSize.iconSmall + 4,
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: AppSize.fontLarge,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
