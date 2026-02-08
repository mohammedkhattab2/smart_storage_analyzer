import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_item.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final String currentLocation;
  final Function(String) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.currentLocation,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final selectedIndex = _getSelectedIndex();
    
    // Get the system navigation bar padding (for gesture navigation)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            // Primary shadow with color
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? .15 : .12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            // Ambient shadow
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? .3 : .08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceContainer.withValues(
                      alpha: isDark ? .7 : .85,
                    ),
                    colorScheme.surface.withValues(alpha: isDark ? .6 : .75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outline.withValues(
                    alpha: isDark ? .15 : .1,
                  ),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    left: _getIndicatorPosition(context, selectedIndex),
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: _getIndicatorWidth(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(
                              alpha: isDark ? .5 : .7,
                            ),
                            colorScheme.secondaryContainer.withValues(
                              alpha: isDark ? .4 : .6,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: .1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 2,
                          colors: [
                            colorScheme.primary.withValues(alpha: .02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: BottomNavItem(
                          icon: AppIcons.home,
                          activeIcon: AppIcons.homeActive,
                          label: "Home",
                          isSelected: _isSelected(0),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onItemTapped(AppRoutes.dashboard);
                          },
                        ),
                      ),
                      Expanded(
                        child: BottomNavItem(
                          icon: AppIcons.files,
                          activeIcon: AppIcons.filesActive,
                          label: "Files",
                          isSelected: _isSelected(1),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onItemTapped(AppRoutes.fileManager);
                          },
                        ),
                      ),
                      Expanded(
                        child: BottomNavItem(
                          icon: AppIcons.stats,
                          activeIcon: AppIcons.statsActive,
                          label: 'Stats',
                          isSelected: _isSelected(2),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onItemTapped(AppRoutes.statistics);
                          },
                        ),
                      ),
                      Expanded(
                        child: BottomNavItem(
                          icon: AppIcons.settings,
                          activeIcon: AppIcons.settingsActive,
                          label: 'Settings',
                          isSelected: _isSelected(3),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onItemTapped(AppRoutes.settings);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition(BuildContext context, int index) {
    final screenWidth = MediaQuery.of(context).size.width - 32; // Total padding
    final itemWidth = screenWidth / 4;
    final indicatorWidth = _getIndicatorWidth();
    return (itemWidth * index) + (itemWidth - indicatorWidth) / 2;
  }

  double _getIndicatorWidth() => 52; // Optimized for icon centering

  bool _isSelected(int index) {
    final selectedIndex = _getSelectedIndex();
    return selectedIndex == index;
  }

  int _getSelectedIndex() {
    // Check for the main routes
    if (currentLocation == '/files' || currentLocation.startsWith('/files')) return 1;
    if (currentLocation == '/statistics' || currentLocation.startsWith('/statistics')) return 2;
    if (currentLocation == '/settings' || currentLocation.startsWith('/settings')) return 3;
    
    // Check for dashboard
    if (currentLocation == '/dashboard' || currentLocation.startsWith('/dashboard')) return 0;
    
    // Default to dashboard
    return 0;
  }
}
