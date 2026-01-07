import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';

class EmptyFilesWidget extends StatelessWidget {
  final FileCategory category;
  const EmptyFilesWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final emptyInfo = _getEmptyInfo(category);
    final categoryColor = _getCategoryColor(category, colorScheme);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container with glassmorphism
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          categoryColor.withValues(alpha: .15),
                          categoryColor.withValues(alpha: .05),
                          Colors.transparent,
                        ],
                        radius: 1.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Glassmorphic circle
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.surface.withValues(
                                alpha: isDark ? .1 : .3,
                              ),
                              colorScheme.surface.withValues(
                                alpha: isDark ? .05 : .1,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: .1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          emptyInfo.icon,
                          size: 56,
                          color: categoryColor.withValues(alpha: .8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge * 1.5),

            // Title
            Text(
              emptyInfo.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingMedium),

            // Message
            Text(
              emptyInfo.message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
                height: 1.6,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge * 2),

            // Tip container with glassmorphism
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSize.paddingLarge,
                    vertical: AppSize.paddingMedium + 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondaryContainer.withValues(
                          alpha: isDark ? .15 : .25,
                        ),
                        colorScheme.tertiaryContainer.withValues(
                          alpha: isDark ? .1 : .2,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: .15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: .15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingMedium),
                      Text(
                        'Try another category or scan storage',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(FileCategory category, ColorScheme colorScheme) {
    // Using theme colors extensions from AppColorSchemes
    switch (category) {
      case FileCategory.large:
        return colorScheme.error;
      case FileCategory.duplicates:
        return colorScheme.secondary;
      case FileCategory.old:
        return colorScheme.tertiary;
      case FileCategory.images:
        return colorScheme.primary;
      case FileCategory.videos:
        return colorScheme.secondary;
      case FileCategory.audio:
        return colorScheme.tertiary;
      case FileCategory.documents:
        return colorScheme.primary;
      case FileCategory.apps:
        return colorScheme.secondary;
      case FileCategory.all:
      case FileCategory.others:
        return colorScheme.primary;
    }
  }

  ({String title, String message, IconData icon}) _getEmptyInfo(
    FileCategory category,
  ) {
    switch (category) {
      case FileCategory.all:
        return (
          title: 'No Files Found',
          message:
              'Your storage is clean and organized!\nGreat job maintaining your device.',
          icon: Icons.folder_special_rounded,
        );
      case FileCategory.large:
        return (
          title: 'No Large Files',
          message:
              'No files exceeding the size threshold.\nYour storage is well optimized!',
          icon: Icons.sd_storage_rounded,
        );
      case FileCategory.duplicates:
        return (
          title: 'No Duplicates',
          message:
              'No duplicate files detected.\nYour files are unique and organized.',
          icon: Icons.file_copy_rounded,
        );
      case FileCategory.old:
        return (
          title: 'No Old Files',
          message:
              'No outdated files found.\nYour storage contains recent content only.',
          icon: Icons.history_rounded,
        );
      case FileCategory.images:
        return (
          title: 'No Images',
          message: 'No image files found in storage.\nStart capturing moments!',
          icon: Icons.photo_library_rounded,
        );
      case FileCategory.videos:
        return (
          title: 'No Videos',
          message:
              'No video files found in storage.\nRecord your favorite memories!',
          icon: Icons.video_library_rounded,
        );
      case FileCategory.audio:
        return (
          title: 'No Audio Files',
          message:
              'No audio files found in storage.\nAdd some music to your device!',
          icon: Icons.audio_file_rounded,
        );
      case FileCategory.documents:
        return (
          title: 'No Documents',
          message:
              'No document files found in storage.\nKeep your important files here.',
          icon: Icons.description_rounded,
        );
      case FileCategory.apps:
        return (
          title: 'No App Files',
          message: 'No installable app files found.\nYour apps are up to date!',
          icon: Icons.apps_rounded,
        );
      case FileCategory.others:
        return (
          title: 'No Other Files',
          message:
              'No miscellaneous files found.\nYour storage is well-categorized!',
          icon: Icons.folder_rounded,
        );
    }
  }
}
