import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSize.paddingMedium,
          vertical: AppSize.paddingSmall / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 
                _isHovered ? 0.08 : 0,
              ),
              blurRadius: _isHovered ? 8 : 0,
              offset: Offset(0, _isHovered ? 4 : 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _isHovered ? 5 : 0,
              sigmaY: _isHovered ? 5 : 0,
            ),
            child: Material(
              color: _isHovered
                  ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
                  : colorScheme.surface.withValues(alpha: 
                      isDark ? 0.6 : 0.9,
                    ),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: widget.onTap != null
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onTap!();
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                splashColor: colorScheme.primary.withValues(alpha: 0.08),
                highlightColor: colorScheme.primary.withValues(alpha: 0.04),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSize.paddingLarge,
                    vertical: AppSize.paddingLarge,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isHovered
                          ? colorScheme.outline.withValues(alpha: 0.15)
                          : colorScheme.outline.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _isHovered ? 44 : 40,
                        height: _isHovered ? 44 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _isHovered
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.surfaceContainerHighest,
                              _isHovered
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : Color.fromARGB(
                                      (colorScheme.surfaceContainerHighest.a * 255).round().clamp(0, 255),
                                      (colorScheme.surfaceContainerHighest.r * 255 * 0.95).round().clamp(0, 255),
                                      (colorScheme.surfaceContainerHighest.g * 255 * 0.95).round().clamp(0, 255),
                                      (colorScheme.surfaceContainerHighest.b * 255 * 0.95).round().clamp(0, 255),
                                    ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isHovered
                                ? colorScheme.primary.withValues(alpha: 0.2)
                                : colorScheme.outline.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: _isHovered
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: _isHovered ? 22 : 20,
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingMedium + 4),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: textTheme.bodyLarge!.copyWith(
                            color: _isHovered
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.9),
                            fontWeight: _isHovered
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: _isHovered ? 0.3 : 0.1,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (widget.trailing != null)
                        Transform.translate(
                          offset: Offset(_isHovered ? 10 : 0, 0),
                          child: widget.trailing!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
