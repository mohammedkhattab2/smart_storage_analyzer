import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class SignOutButton extends StatefulWidget {
  final VoidCallback? onTap;
  const SignOutButton({super.key, this.onTap});

  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTap() {
    HapticFeedback.heavyImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Transform.scale(
          scale: _isPressed ? 0.92 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingMedium,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.error.withValues(
                    alpha: _isHovered ? .15 : 0,
                  ),
                  blurRadius: _isHovered ? 20 : 0,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _isHovered ? 10 : 0,
                  sigmaY: _isHovered ? 10 : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: colorScheme.error.withValues(alpha: .15),
                    highlightColor: colorScheme.error.withValues(alpha: .08),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.error.withValues(
                              alpha: _isHovered ? .12 : .08,
                            ),
                            colorScheme.errorContainer.withValues(
                              alpha: _isHovered ? .08 : .05,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.error.withValues(
                            alpha: _isHovered ? .25 : .15,
                          ),
                          width: _isHovered ? 1.5 : 1,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSize.paddingLarge,
                        vertical: _isHovered
                            ? AppSize.paddingLarge
                            : AppSize.paddingLarge - 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon container
                          Transform.rotate(
                            angle: _isHovered ? -0.2 : 0,
                            child: Container(
                              padding: EdgeInsets.all(_isHovered ? 10 : 8),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    colorScheme.errorContainer.withValues(
                                      alpha: _isHovered ? .8 : .6,
                                    ),
                                    colorScheme.error.withValues(
                                      alpha: _isHovered ? .2 : .15,
                                    ),
                                  ],
                                  radius: 1.5,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.error.withValues(
                                    alpha: .2,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.error.withValues(
                                            alpha: .2,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: -2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: colorScheme.error,
                                size: _isHovered ? 22 : 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _isHovered
                                ? AppSize.paddingMedium + 4
                                : AppSize.paddingMedium,
                          ),
                          // Text
                          Text(
                            AppStrings.signOut,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: _isHovered ? 18 : 16,
                              color: colorScheme.error,
                              fontWeight: _isHovered
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: _isHovered ? 0.5 : 0.3,
                            ),
                          ),
                          // Arrow indicator on hover
                          if (_isHovered)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSize.paddingSmall,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: colorScheme.error,
                                size: 18,
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
