import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class FileManagerHeader extends StatefulWidget {
  final bool showSelectionActions;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;

  const FileManagerHeader({
    super.key,
    this.showSelectionActions = false,
    this.onSelectAll,
    this.onClearSelection,
  });

  @override
  State<FileManagerHeader> createState() => _FileManagerHeaderState();
}

class _FileManagerHeaderState extends State<FileManagerHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSize.paddingLarge + 4,
        AppSize.paddingMedium,
        AppSize.paddingLarge + 4,
        AppSize.paddingLarge,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background decoration
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: .08),
                    colorScheme.primary.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              colorScheme.onSurface,
                              colorScheme.onSurface.withValues(alpha: .8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            AppStrings.fileManager,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              height: 1.1,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Indicator dot
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer.withValues(
                                  alpha: .4,
                                ),
                                colorScheme.primaryContainer.withValues(
                                  alpha: .2,
                                ),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widget.showSelectionActions
                              ? Icons.check_circle_rounded
                              : Icons.folder_rounded,
                          size: 16,
                          color: widget.showSelectionActions
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: .7,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.showSelectionActions
                              ? 'Managing your files'
                              : 'Organize and clean up storage',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.showSelectionActions)
                Row(
                  children: [
                    // Cancel button with iOS-style design
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onClearSelection?.call();
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: isDark ? .3 : .5),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: .2,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Select All button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: .5),
                            colorScheme.primaryContainer.withValues(alpha: .3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: .15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onSelectAll?.call();
                          },
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.select_all_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
