import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_item.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

class BottomNavBar extends StatefulWidget {
  final String currentLocation;
  final Function(String) onItemTapped;
  const BottomNavBar({
    super.key,
    required this.currentLocation,
    required this.onItemTapped,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = _getSelectedIndex();
  }
  
  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      setState(() {
        _selectedIndex = _getSelectedIndex();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            if (brightness == Brightness.light)
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 0),
                spreadRadius: 0,
              ),
          ],
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: _getIndicatorPosition(_selectedIndex),
              top: 8,
              bottom: 8,
              child: Container(
                width: _getIndicatorWidth(),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondaryContainer,
                    width: 1,
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
                      setState(() => _selectedIndex = 0);
                      widget.onItemTapped(AppRoutes.dashboard);
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
                      setState(() => _selectedIndex = 1);
                      widget.onItemTapped(AppRoutes.fileManager);
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
                      setState(() => _selectedIndex = 2);
                      widget.onItemTapped(AppRoutes.statistics);
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
                      setState(() => _selectedIndex = 3);
                      widget.onItemTapped(AppRoutes.settings);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getIndicatorPosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width - 24; // Total padding
    final itemWidth = screenWidth / 4;
    final indicatorWidth = _getIndicatorWidth();
    return (itemWidth * index) + (itemWidth - indicatorWidth) / 2;
  }

  double _getIndicatorWidth() => 56; // Slightly smaller for better icon centering

  bool _isSelected(int index) {
    switch (index) {
      case 0:
        return widget.currentLocation.startsWith(AppRoutes.dashboard);
      case 1:
        return widget.currentLocation.startsWith(AppRoutes.fileManager);
      case 2:
        return widget.currentLocation.startsWith(AppRoutes.statistics);
      case 3:
        return widget.currentLocation.startsWith(AppRoutes.settings);
      default:
        return false;
    }
  }
  
  int _getSelectedIndex() {
    if (widget.currentLocation.startsWith(AppRoutes.dashboard)) return 0;
    if (widget.currentLocation.startsWith(AppRoutes.fileManager)) return 1;
    if (widget.currentLocation.startsWith(AppRoutes.statistics)) return 2;
    if (widget.currentLocation.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }
}
