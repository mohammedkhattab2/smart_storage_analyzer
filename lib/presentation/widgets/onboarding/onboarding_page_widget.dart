import 'package:flutter/material.dart';
import 'dart:ui';

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
          // Icon Container with iOS-style glassmorphism
          Container(
            width: isSmallScreen ? 120 : 160,
            height: isSmallScreen ? 120 : 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: .2),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withValues(alpha: isDark ? .15 : .25),
                        iconColor.withValues(alpha: isDark ? .05 : .15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: .2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect
                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              iconColor.withValues(alpha: .3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Icon
                      Icon(
                        icon,
                        size: isSmallScreen ? 60 : 80,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 40 : 60),

          // Title with Gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                colorScheme.onSurface,
                colorScheme.onSurface.withValues(alpha: .9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: isSmallScreen ? 26 : 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: isSmallScreen ? 15 : 18,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
