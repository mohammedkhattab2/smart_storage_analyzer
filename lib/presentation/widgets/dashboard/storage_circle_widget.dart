import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';

class StorageCircleWidget extends StatelessWidget {
  final StorageInfo storageInfo;
  const StorageCircleWidget({super.key, required this.storageInfo});

  /// Converts bytes to gigabytes with exactly 1 decimal place maximum
  double _bytesToGB(double bytes) {
    if (bytes <= 0) return 0;

    // Convert bytes to GB
    final gb = bytes / (1024 * 1024 * 1024);

    // Round to 1 decimal place maximum
    return (gb * 10).roundToDouble() / 10;
  }

  /// Formats GB value to display cleanly (no unnecessary decimals)
  String _formatGB(double gb) {
    if (gb <= 0) return "0";

    // Check if it's effectively a whole number
    if ((gb % 1) == 0) {
      // Show as integer: 5.0 → "5"
      return gb.toInt().toString();
    } else {
      // Show with 1 decimal: 5.5 → "5.5"
      return gb.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Use the storage info from Native Bridge (passed via DashboardCubit)
    final totalBytes = storageInfo.totalSpace;
    final usedBytes = storageInfo.usedSpace;

    // Convert storage values to GB
    final usedGB = _bytesToGB(usedBytes);
    final totalGB = _bytesToGB(totalBytes);

    // Calculate percentage based on actual values
    // Ensure percentage is between 0 and 1
    final percentage = totalGB > 0 ? (usedGB / totalGB).clamp(0.0, 1.0) : 0.0;
    final percentageInt = (percentage * 100).round();
    final isHighUsage = percentage > 0.8;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSize.paddingSmall),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glow effect for high usage
          if (isHighUsage)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: .3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          // Main card with backdrop blur effect
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSize.paddingXLarge,
                  horizontal: AppSize.paddingLarge,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            colorScheme.surfaceContainer.withValues(alpha: .8),
                            colorScheme.surfaceContainer.withValues(alpha: .6),
                          ]
                        : [
                            colorScheme.surfaceContainer.withValues(alpha: .95),
                            colorScheme.surfaceContainerHighest.withValues(
                              alpha: .85,
                            ),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: .2)
                        : colorScheme.outlineVariant.withValues(alpha: .08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: isDark ? .15 : .06,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: .05),
                        blurRadius: 30,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main circular progress
                    GestureDetector(
                      onTap: () => HapticFeedback.lightImpact(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Subtle background circle
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: .3),
                            ),
                          ),
                          // Progress indicator
                          CircularPercentIndicator(
                            radius: 95,
                            lineWidth: 12,
                            animation: false,
                            percent: percentage,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Percentage display
                                Text(
                                  '$percentageInt%',
                                  style: textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isHighUsage
                                        ? colorScheme.error
                                        : colorScheme.onSurface,
                                    letterSpacing: -1,
                                    fontSize: 36,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // GB display
                                Text(
                                  '${_formatGB(usedGB)} GB',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: isHighUsage
                                ? colorScheme.error
                                : colorScheme.primary,
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: .25),
                            backgroundWidth: 12,
                            animateFromLastPercent: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSize.paddingXLarge + 8),
                    // Storage details with iOS-style capsule
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSize.paddingXLarge + 8,
                        vertical: AppSize.paddingMedium,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHigh.withValues(
                                alpha: .6,
                              )
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: .8,
                              ),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: .1,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: .04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: .7,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatGB(usedGB)} GB',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            ' / ${_formatGB(totalGB)} GB',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
