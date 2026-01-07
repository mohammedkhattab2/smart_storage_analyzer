import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class FileTabsWidget extends StatefulWidget {
  final FileCategory currentCategory;
  final Function(FileCategory) onTabChanged;

  const FileTabsWidget({
    super.key,
    required this.currentCategory,
    required this.onTabChanged,
  });

  @override
  State<FileTabsWidget> createState() => _FileTabsWidgetState();
}

class _FileTabsWidgetState extends State<FileTabsWidget> {
  late ScrollController _scrollController;

  final List<
    ({
      String label,
      FileCategory category,
      IconData icon,
      Color Function(ColorScheme) getColor,
    })
  >
  _tabs = [
    (
      label: 'All Files',
      category: FileCategory.all,
      icon: Icons.folder_rounded,
      getColor: (cs) => cs.primary,
    ),
    (
      label: 'Large',
      category: FileCategory.large,
      icon: Icons.sd_storage_rounded,
      getColor: (cs) => cs.error,
    ),
    (
      label: 'Duplicates',
      category: FileCategory.duplicates,
      icon: Icons.file_copy_rounded,
      getColor: (cs) => cs.secondary,
    ),
    (
      label: 'Old',
      category: FileCategory.old,
      icon: Icons.history_rounded,
      getColor: (cs) => cs.tertiary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(
        AppSize.paddingSmall,
        0,
        AppSize.paddingSmall,
        AppSize.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(
          alpha: isDark ? 0.3 : 0.5,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              child: Row(
                children: [
                  for (int i = 0; i < _tabs.length; i++) ...[
                    _buildTab(
                      context,
                      _tabs[i].label,
                      _tabs[i].category,
                      _tabs[i].icon,
                      _tabs[i].getColor(colorScheme),
                    ),
                    if (i < _tabs.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    FileCategory category,
    IconData icon,
    Color tabColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isSelected = widget.currentCategory == category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTabChanged(category);
          // Scroll to ensure selected tab is visible
          _ensureTabVisible(context);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 24 : 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      tabColor,
                      tabColor.withValues(
                        red: tabColor.r * 0.85,
                        green: tabColor.g * 0.85,
                        blue: tabColor.b * 0.85,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tabColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: _buildTabContent(
            context,
            label,
            category,
            icon,
            isSelected,
            colorScheme,
            textTheme,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    String label,
    FileCategory category,
    IconData icon,
    bool isSelected,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isSelected
              ? Colors.white
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelLarge!.copyWith(
            color: isSelected
                ? Colors.white
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: isSelected ? 0.3 : 0.1,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _ensureTabVisible(BuildContext context) {
    // Add logic to scroll to selected tab if needed
    // This would require calculating positions based on tab widths
  }
}
