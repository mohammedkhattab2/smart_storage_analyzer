import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/custom_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glassmorphism
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle radial glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.error.withValues(alpha: .18),
                          Colors.transparent,
                        ],
                        radius: 0.9,
                      ),
                    ),
                  ),
                  // Glass circle
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.surface.withValues(alpha: isDark ? .08 : .22),
                              colorScheme.surface.withValues(alpha: isDark ? .05 : .12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: .20),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSize.paddingLarge),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: (textTheme.bodyLarge ?? const TextStyle())
                  .copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.w500,
                  ),
            ),

            const SizedBox(height: AppSize.paddingLarge),

            // Tip chip
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSize.paddingMedium,
                    vertical: AppSize.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.errorContainer.withValues(alpha: isDark ? .16 : .24),
                        colorScheme.errorContainer.withValues(alpha: isDark ? .10 : .16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: .20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: AppSize.paddingSmall),
                      Text(
                        'Please try again',
                        style: (textTheme.labelMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        )) ?? TextStyle(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSize.paddingLarge),

            // Retry button
            CustomButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }
}
