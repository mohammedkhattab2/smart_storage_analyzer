import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class SettingsSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSize.paddingLarge,
          vertical: AppSize.paddingSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: const EdgeInsets.only(
                left: AppSize.paddingMedium,
                bottom: AppSize.paddingSmall + 4,
              ),
              child: Row(
                children: [
                  // Title with gradient effect
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        colors: _isHovered
                            ? [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ]
                            : [
                                colorScheme.onSurfaceVariant,
                                colorScheme.onSurfaceVariant,
                              ],
                      ).createShader(rect);
                    },
                    child: Text(
                      widget.title.toUpperCase(),
                      style: textTheme.labelMedium!.copyWith(
                        color: _isHovered
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  // Line
                  Expanded(
                    child: Container(
                      height: _isHovered ? 2 : 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.outline.withValues(
                              alpha: _isHovered ? .3 : .1,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Section Container with glassmorphism
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: _isHovered ? .08 : 0,
                    ),
                    blurRadius: _isHovered ? 16 : 0,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: isDark || _isHovered ? 10 : 0,
                    sigmaY: isDark || _isHovered ? 10 : 0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainer.withValues(
                            alpha: isDark
                                ? (_isHovered ? .6 : .5)
                                : (_isHovered ? .95 : .9),
                          ),
                          colorScheme.surface.withValues(
                            alpha: isDark
                                ? (_isHovered ? .5 : .4)
                                : (_isHovered ? .9 : .85),
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isHovered
                            ? colorScheme.outline.withValues(alpha: .2)
                            : colorScheme.outline.withValues(alpha: .1),
                        width: _isHovered ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Subtle pattern overlay
                        if (_isHovered)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0.7, -0.6),
                                  radius: 2,
                                  colors: [
                                    colorScheme.primary.withValues(
                                      alpha: .03,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Children with dividers
                        Column(
                          children: [
                            for (int i = 0; i < widget.children.length; i++) ...[
                              widget.children[i],
                              if (i < widget.children.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  indent: AppSize.paddingLarge + 56,
                                  endIndent: AppSize.paddingLarge,
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: .15),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
