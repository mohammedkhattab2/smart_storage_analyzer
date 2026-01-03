import 'package:flutter/material.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicatorWidget({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return SizedBox(
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          final isPreviousPage = index < currentPage;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isActive ? 32 : 10,
            height: isActive ? 12 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isActive
                  ? null
                  : isPreviousPage
                  ? colorScheme.primary.withValues(alpha: .4)
                  : colorScheme.onSurfaceVariant.withValues(alpha: .3),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: .5),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: isActive
                  ? Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: isDark ? 0.2 : 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

// Alternative Modern Page Indicator with Progress Bar
class ModernPageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const ModernPageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: colorScheme.onSurfaceVariant.withValues(alpha: isDark ? .2 : .3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progressWidth = constraints.maxWidth / pageCount;
          return Stack(
            children: [
              Positioned(
                left: currentPage * progressWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: progressWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: .5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Dots with Scale Animation
class AnimatedDotsIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const AnimatedDotsIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 14 : 8,
          height: isActive ? 14 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: .4),
            border: isActive
                ? Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .4),
                    width: 2,
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: .6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
