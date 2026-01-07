import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Icon Container with multiple layers
          _buildMagicalIconContainer(
            icon: icon,
            iconColor: iconColor,
            colorScheme: colorScheme,
            isDark: isDark,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 40 : 60),

          // Enhanced Title with Magical Gradient
          _buildMagicalTitle(
            title: title,
            textTheme: textTheme,
            colorScheme: colorScheme,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Enhanced Description
          _buildMagicalDescription(
            description: description,
            textTheme: textTheme,
            colorScheme: colorScheme,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalIconContainer({
    required IconData icon,
    required Color iconColor,
    required ColorScheme colorScheme,
    required bool isDark,
    required bool isSmallScreen,
  }) {
    final containerSize = isSmallScreen ? 140.0 : 180.0;
    final iconSize = isSmallScreen ? 60.0 : 80.0;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow Ring
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  iconColor.withValues(alpha: .15),
                  iconColor.withValues(alpha: .05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Multiple Concentric Rings
          ...List.generate(3, (index) {
            final ringSize = containerSize - (index * 30);
            return Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: .08 - (index * 0.02)),
                  width: 1,
                ),
              ),
            );
          }),

          // Main Icon Container
          Container(
            width: containerSize * 0.7,
            height: containerSize * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: .25),
                  blurRadius: 50,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: iconColor.withValues(alpha: .15),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withValues(alpha: isDark ? .2 : .3),
                        iconColor.withValues(alpha: isDark ? .1 : .2),
                        iconColor.withValues(alpha: isDark ? .05 : .15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner gradient glow
                      Container(
                        width: iconSize * 1.5,
                        height: iconSize * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              iconColor.withValues(alpha: .4),
                              iconColor.withValues(alpha: .1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),

                      // Decorative dots around icon
                      ...List.generate(8, (index) {
                        final angle = (index * 45) * math.pi / 180;
                        final radius = iconSize * 0.8;
                        return Transform.translate(
                          offset: Offset(
                            radius * math.cos(angle),
                            radius * math.sin(angle),
                          ),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor.withValues(alpha: .5),
                              boxShadow: [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: .3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Icon with enhanced shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .1),
                              Colors.transparent,
                            ],
                            radius: 0.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: iconColor,
                          shadows: [
                            Shadow(
                              color: iconColor.withValues(alpha: .5),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Orbiting Particles
          CustomPaint(
            size: Size(containerSize, containerSize),
            painter: _OrbitingParticlesPainter(
              color: iconColor.withValues(alpha: .3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalTitle({
    required String title,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: .05),
            colorScheme.secondaryContainer.withValues(alpha: .03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            colorScheme.onSurface,
            colorScheme.primary,
            colorScheme.onSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontSize: isSmallScreen ? 26 : 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.2,
            shadows: [
              Shadow(
                color: colorScheme.primary.withValues(alpha: .3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalDescription({
    required String description,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required bool isSmallScreen,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: .08),
                  Colors.transparent,
                ],
                radius: 2.0,
              ),
            ),
          ),
          // Text with enhanced styling
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: isSmallScreen ? 15 : 18,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: colorScheme.surface.withValues(alpha: .8),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for orbiting particles effect
class _OrbitingParticlesPainter extends CustomPainter {
  final Color color;

  _OrbitingParticlesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw orbiting particles
    const particleCount = 12;
    const orbitRadius = 65.0;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 360 / particleCount) * math.pi / 180;
      final x = center.dx + orbitRadius * math.cos(angle);
      final y = center.dy + orbitRadius * math.sin(angle);

      final particleSize = 2.0 + (math.sin(angle) * 1.0);

      // Draw particle with glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: .1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), particleSize + 4, glowPaint);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
