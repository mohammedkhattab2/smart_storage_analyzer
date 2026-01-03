import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      child: Column(
        children: [
          // Main loading container with glassmorphism
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.surfaceContainer.withValues(alpha: isDark ? .3 : .6),
                        colorScheme.surface.withValues(alpha: isDark ? .2 : .4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: .1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: .2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Activity indicator
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingLarge),

          // Shimmer bar
          _buildShimmerContainer(
            height: 56,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: AppSize.paddingLarge),

          // Grid of shimmer items
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSize.paddingMedium,
              mainAxisSpacing: AppSize.paddingMedium,
              childAspectRatio: 1.1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildShimmerContainer(
                colorScheme: colorScheme,
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    double? height,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: isDark ? .3 : .8),
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: .05),
          width: 1,
        ),
      ),
    );
  }
}
