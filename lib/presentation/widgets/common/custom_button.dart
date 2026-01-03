import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isPrimary;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.isLoading = false,
    this.isPrimary = true,
    this.width,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      HapticFeedback.mediumImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final buttonColor =
        widget.backgroundColor ??
        (widget.isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHighest);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: Transform.scale(
        scale: _isPressed ? 0.94 : 1.0,
        child: Container(
          width: widget.width,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isPrimary && !widget.isLoading
                ? [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: .3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: buttonColor.withValues(alpha: .15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -8,
                      ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.isPrimary ? 10 : 0,
                sigmaY: widget.isPrimary ? 10 : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: (widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary)
                      .withValues(alpha: .15),
                  highlightColor: (widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary)
                      .withValues(alpha: .08),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: widget.isPrimary
                          ? LinearGradient(
                              colors: [
                                buttonColor,
                                buttonColor.withValues(
                                  red: buttonColor.r * 0.85,
                                  green: buttonColor.g * 0.85,
                                  blue: buttonColor.b * 0.85,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isPrimary ? null : buttonColor,
                      border: Border.all(
                        color: widget.isPrimary
                            ? colorScheme.onPrimary.withValues(alpha: .1)
                            : colorScheme.outline.withValues(alpha: .2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                                strokeWidth: 2.5,
                                strokeCap: StrokeCap.round,
                              ),
                            )
                          : _buildContent(context, colorScheme),
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

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final textColor = widget.isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: _isHovered ? 17 : 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: _isHovered ? 0.8 : 0.5,
              ) ??
              TextStyle(
                fontSize: _isHovered ? 17 : 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
        ),
        if (widget.icon != null) ...[
          const SizedBox(width: 8),
          Icon(
            widget.icon,
            color: textColor,
            size: _isHovered ? 22 : 20,
          ),
        ],
      ],
    );
  }
}

// Alternative Outlined Button Style without animations
class CustomOutlinedButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? borderColor;
  final bool isLoading;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  State<CustomOutlinedButton> createState() => _CustomOutlinedButtonState();
}

class _CustomOutlinedButtonState extends State<CustomOutlinedButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = widget.borderColor ?? colorScheme.primary;
    final isDark = colorScheme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Transform.scale(
          scale: _isPressed ? 0.96 : 1.0,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: .15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _isHovered ? 5 : 0,
                  sigmaY: _isHovered ? 5 : 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _isHovered
                        ? LinearGradient(
                            colors: [
                              borderColor.withValues(alpha: .08),
                              borderColor.withValues(alpha: .05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: !_isHovered
                        ? colorScheme.surface.withValues(alpha: isDark ? .6 : .8)
                        : null,
                    border: Border.all(
                      color: borderColor.withValues(alpha: .5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: borderColor,
                              strokeWidth: 2,
                              strokeCap: StrokeCap.round,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.text,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontSize: _isHovered ? 17 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: borderColor,
                                      letterSpacing: _isHovered ? 0.8 : 0.5,
                                    ) ??
                                    TextStyle(
                                      fontSize: _isHovered ? 17 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: borderColor,
                                    ),
                              ),
                              if (widget.icon != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  widget.icon,
                                  color: borderColor,
                                  size: _isHovered ? 22 : 20,
                                ),
                              ],
                            ],
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
