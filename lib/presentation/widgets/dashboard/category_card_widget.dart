import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/mappers/category_ui_mapper.dart';

class CategoryCardWidget extends StatefulWidget {
  final Category category;
  final VoidCallback? onTap;
  final int index;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.onTap,
    this.index = 0,
  });

  /// Check if this category is a media category that requires SAF scanning
  bool get isMediaCategory {
    final name = category.name.toLowerCase();
    return name == 'images' || name == 'image' ||
           name == 'videos' || name == 'video' ||
           name == 'audio' || name == 'music';
  }

  @override
  State<CategoryCardWidget> createState() => _CategoryCardWidgetState();
}

class _CategoryCardWidgetState extends State<CategoryCardWidget> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _handleHoverEnter(PointerEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _handleHoverExit(PointerEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLargeCategory = widget.category.sizeInBytes > 1000000000; // 1GB
    final categoryColor = CategoryUIMapper.getColor(widget.category.id);
    final categoryIcon = CategoryUIMapper.getIcon(widget.category.id);

    final scale = _isPressed ? 0.88 : (_isHovered ? 1.03 : 1.0);
    final translateY = _isHovered ? -3.0 : 0.0;

    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainer.withValues(alpha: .98),
                    colorScheme.surfaceContainerHighest.withValues(alpha: .95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered
                      ? categoryColor.withValues(alpha: .2)
                      : colorScheme.outlineVariant.withValues(alpha: .08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.transparent
                        : categoryColor.withValues(
                            alpha: _isHovered ? .15 : .08,
                          ),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: Offset(0, _isHovered ? 8 : 4),
                    spreadRadius: _isHovered ? -2 : -4,
                  ),
                  if (!_isPressed)
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: .04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Padding(
                    padding: EdgeInsets.all(
                      AppSize.paddingMedium,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        // Icon with glassmorphic effect
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                categoryColor.withValues(alpha: .2),
                                categoryColor.withValues(alpha: .1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: .2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withValues(alpha: .15),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 24,
                            color: categoryColor,
                          ),
                        ),
                        SizedBox(
                          height: AppSize.paddingSmall,
                        ),
                        // Category name with better typography
                        Text(
                          widget.category.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: _isHovered
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: colorScheme.onSurface,
                            letterSpacing: _isHovered ? 0.2 : 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Size badge with iOS-style pill shape
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isLargeCategory
                                ? colorScheme.errorContainer.withValues(
                                    alpha: .8,
                                  )
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: .7),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isLargeCategory
                                  ? colorScheme.error.withValues(alpha: .2)
                                  : colorScheme.outline.withValues(alpha: .1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            SizeFormatter.formatBytes(
                              widget.category.sizeInBytes.toInt(),
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: isLargeCategory
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // File count or "Tap to scan" for media categories
                        if (widget.isMediaCategory)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 10,
                                  color: categoryColor.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Tap to scan',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: categoryColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            '${widget.category.fileCount} files',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: _isHovered ? 1.0 : .6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
