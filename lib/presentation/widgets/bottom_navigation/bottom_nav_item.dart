import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.scale(
        scale: _isPressed ? 0.88 : 1.0,
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              SizedBox(
                height: 32,
                width: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect for selected state
                    if (widget.isSelected)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: .15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                    // Icon
                    Icon(
                      widget.isSelected
                          ? widget.activeIcon
                          : widget.icon,
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: .7),
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Label
              Text(
                widget.label,
                style: (widget.isSelected
                        ? textTheme.labelSmall
                        : textTheme.bodySmall)
                    ?.copyWith(
                      fontSize: widget.isSelected ? 11 : 10,
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: .8),
                      fontWeight: widget.isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: widget.isSelected ? 0.5 : 0.3,
                    ) ??
                    TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),

              // Selection indicator dot
              Container(
                height: widget.isSelected ? 4 : 0,
                width: widget.isSelected ? 4 : 0,
                margin: EdgeInsets.only(top: widget.isSelected ? 4 : 0),
                decoration: BoxDecoration(
                  color: widget.isSelected ? colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: .4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
