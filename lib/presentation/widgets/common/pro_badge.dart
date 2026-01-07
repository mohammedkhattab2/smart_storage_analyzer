import 'package:flutter/material.dart';

/// Badge widget to indicate Pro features
class ProBadge extends StatelessWidget {
  final String? text;
  final double? size;
  final bool showIcon;

  const ProBadge({super.key, this.text, this.size, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size ?? 8,
        vertical: (size ?? 8) / 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(size ?? 12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: .3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.star_rounded,
              size: size ?? 12,
              color: isDark ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text ?? 'PRO',
            style: TextStyle(
              fontSize: (size ?? 12) * 0.9,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black87 : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini Pro indicator (just icon)
class ProIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const ProIndicator({super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color ?? colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.star_rounded, size: size, color: colorScheme.onPrimary),
    );
  }
}
