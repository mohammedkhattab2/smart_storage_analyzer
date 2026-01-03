import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';

class PremiumCard extends StatefulWidget {
  final bool isPremium;
  final VoidCallback? onTap;

  const PremiumCard({super.key, required this.isPremium, this.onTap});

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gradientColors = colorScheme.premiumGradient;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingLarge,
        vertical: AppSize.paddingSmall,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onTap != null) {
            HapticFeedback.mediumImpact();
            widget.onTap!();
          }
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: Transform.scale(
            scale: _isPressed ? 0.96 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(
                      alpha: _isHovered ? .4 : .25,
                    ),
                    blurRadius: _isHovered ? 24 : 16,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: gradientColors.last.withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(-4, 4),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                      ),
                    ),

                    // Glassmorphic overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: .1),
                              Colors.white.withValues(alpha: .05),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(24),
                        splashColor: Colors.white.withValues(alpha: .2),
                        highlightColor: Colors.white.withValues(alpha: .1),
                        child: Padding(
                          padding: EdgeInsets.all(
                            _isHovered
                                ? AppSize.paddingLarge + 2
                                : AppSize.paddingLarge,
                          ),
                          child: Row(
                            children: [
                              // Star icon container
                              Container(
                                padding: EdgeInsets.all(
                                  _isHovered
                                      ? AppSize.paddingMedium
                                      : AppSize.paddingSmall + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: .3,
                                    ),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: .2,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: _isHovered ? 0.5 : 0,
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: _isHovered ? 26 : 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSize.paddingLarge),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.goPremium,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: _isHovered ? 22 : 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ) ??
                                      const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppSize.paddingXSmall,
                                    ),
                                    Text(
                                      AppStrings.unlockPremium,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: _isHovered ? 15 : 14,
                                        color: Colors.white.withValues(
                                          alpha: .9,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ) ??
                                      TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(
                                          alpha: .9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow
                              Transform(
                                transform: Matrix4.identity()
                                  ..setTranslationRaw(
                                    _isHovered ? 12 : 0,
                                    0,
                                    0,
                                  ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: .15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: _isHovered ? 20 : 18,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
