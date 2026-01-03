import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../cubits/onboarding/onboarding_state.dart';
import '../../widgets/onboarding/onboarding_page_widget.dart';
import '../../widgets/onboarding/page_indicator_widget.dart';
import '../../widgets/onboarding/parallax_page_view.dart';
import '../../widgets/common/custom_button.dart';

/// Onboarding Screen - Responsible for BlocProvider only
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: const OnboardingView(),
    );
  }
}

/// Onboarding View - Responsible for UI
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  OnboardingViewState createState() => OnboardingViewState();
}

class OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Multi-layer Gradient Background
          _buildMagicalBackground(colorScheme, isDark),

          // Main Content
          SafeArea(
            child: BlocConsumer<OnboardingCubit, OnboardingState>(
              listener: (context, state) {
                if (state is OnboardingCompleted) {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.dashboard);
                }
              },
              builder: (context, state) {
                if (state is OnboardingLoading) {
                  return _buildMagicalLoading(colorScheme);
                }

                if (state is OnboardingPageState) {
                  return Column(
                    children: [
                      // Enhanced Skip Button
                      _buildMagicalSkipButton(colorScheme, isDark),

                      // PageView with Enhanced Parallax
                      Expanded(
                        child: ParallaxPageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            HapticFeedback.selectionClick();
                            context.read<OnboardingCubit>().changePage(index);
                          },
                          children: [
                            _buildEnhancedPageWidget(
                              icon: Icons.flash_on_rounded,
                              iconColor: colorScheme.primary,
                              title: 'One-Tap Optimize',
                              description:
                                  'Clean up duplicates, large files, and\nsystem cache with a single tap.',
                              pageIndex: 0,
                              currentPage: state.currentPage,
                            ),
                            _buildEnhancedPageWidget(
                              icon: Icons.pie_chart_rounded,
                              iconColor: colorScheme.secondary,
                              title: 'Smart Categories',
                              description:
                                  'Visualize your storage usage with\nbeautiful, interactive charts and\nbreakdowns.',
                              pageIndex: 1,
                              currentPage: state.currentPage,
                            ),
                            _buildEnhancedPageWidget(
                              icon: Icons.phone_android_rounded,
                              iconColor: colorScheme.tertiary,
                              title: 'Deep Analysis',
                              description:
                                  'Scan your device to find hidden clutter\nand reclaim valuable space instantly.',
                              pageIndex: 2,
                              currentPage: state.currentPage,
                            ),
                          ],
                        ),
                      ),

                      // Enhanced Bottom Section
                      _buildMagicalBottomSection(
                        state.currentPage,
                        colorScheme,
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalBackground(ColorScheme colorScheme, bool isDark) {
    return Stack(
      children: [
        // Primary Gradient Layer
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.5, -0.5),
              radius: 2.0,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: isDark ? .15 : .25),
                colorScheme.surface,
                colorScheme.secondaryContainer.withValues(alpha: isDark ? .08 : .15),
                colorScheme.tertiaryContainer.withValues(alpha: isDark ? .05 : .1),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Floating Orbs
        ..._buildFloatingOrbs(colorScheme, isDark),

        // Enhanced Geometric Patterns
        CustomPaint(
          size: Size.infinite,
          painter: MagicalBackgroundPatternPainter(
            primaryColor: colorScheme.primary.withValues(alpha: .05),
            secondaryColor: colorScheme.secondary.withValues(alpha: .03),
            tertiaryColor: colorScheme.tertiary.withValues(alpha: .02),
          ),
        ),

        // Noise Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0),
                colorScheme.surfaceContainerHighest.withValues(alpha: .02),
                colorScheme.surface.withValues(alpha: 0),
              ],
            ),
          ),
        ),

        // Soft Blur Layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: colorScheme.surface.withValues(alpha: .01),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingOrbs(ColorScheme colorScheme, bool isDark) {
    return [
      Positioned(
        top: 100,
        right: 50,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.primary.withValues(alpha: .15),
                colorScheme.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 200,
        left: 30,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.secondary.withValues(alpha: .12),
                colorScheme.secondary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        right: 100,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.tertiary.withValues(alpha: .1),
                colorScheme.tertiary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMagicalLoading(ColorScheme colorScheme) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: .2),
              colorScheme.primaryContainer.withValues(alpha: 0),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalSkipButton(ColorScheme colorScheme, bool isDark) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: .15),
                blurRadius: 20,
                offset: const Offset(0, 5),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 15,
                sigmaY: 15,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<OnboardingCubit>().completeOnboarding();
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: isDark ? .2 : .3),
                          colorScheme.surfaceContainer
                              .withValues(alpha: isDark ? .15 : .25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: .15),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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

  Widget _buildEnhancedPageWidget({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required int pageIndex,
    required int currentPage,
  }) {
    final isActive = pageIndex == currentPage;
    return Transform.scale(
      scale: isActive ? 1.0 : 0.95,
      child: OnboardingPageWidget(
        icon: icon,
        iconColor: iconColor,
        title: title,
        description: description,
      ),
    );
  }

  Widget _buildMagicalBottomSection(
    int currentPage,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withValues(alpha: 0),
            colorScheme.surface.withValues(alpha: .5),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Enhanced Page Indicators
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: .2),
                  colorScheme.surfaceContainer.withValues(alpha: .1),
                ],
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: .05),
                width: 1,
              ),
            ),
            child: PageIndicatorWidget(
              currentPage: currentPage,
              pageCount: 3,
            ),
          ),

          const SizedBox(height: 40),

          // Enhanced Button with Glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: CustomButton(
              text: currentPage == 2 ? 'Get Started' : 'Next',
              icon: currentPage == 2
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                if (currentPage == 2) {
                  context.read<OnboardingCubit>().completeOnboarding();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Background Pattern Painter with magical effects
class MagicalBackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  MagicalBackgroundPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw hexagonal patterns
    _drawHexagonalPattern(canvas, size, primaryColor);

    // Draw circular patterns
    _drawCircularPatterns(canvas, size, secondaryColor);

    // Draw wave patterns
    _drawWavePatterns(canvas, size, tertiaryColor);
  }

  void _drawHexagonalPattern(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 80.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing * 1.5) {
      for (double y = -spacing; y < size.height + spacing; y += spacing * 1.5) {
        final path = Path();
        const radius = spacing / 2.5;

        // Create hexagon path
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * math.pi / 180;
          final pointX = x + radius * math.cos(angle);
          final pointY = y + radius * math.sin(angle);

          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();

        // Add gradient effect
        final gradient = RadialGradient(
          center: Alignment(x / size.width, y / size.height),
          radius: 0.5,
          colors: [
            color.withValues(alpha: color.a * 2),
            color,
          ],
        );

        paint.shader = gradient.createShader(
          Rect.fromCenter(center: Offset(x, y), width: spacing, height: spacing),
        );

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawCircularPatterns(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw concentric circles
    for (double i = 0; i < 10; i++) {
      final radius = size.width * 0.1 * (i + 1);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        radius,
        paint,
      );
    }

    // Draw offset circles
    for (double i = 0; i < 8; i++) {
      final radius = size.width * 0.08 * (i + 1);
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.7),
        radius,
        paint,
      );
    }
  }

  void _drawWavePatterns(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw multiple wave layers
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final waveHeight = 30.0 + (layer * 10);
      final waveFrequency = 0.02 - (layer * 0.005);
      final yOffset = size.height * 0.6 + (layer * 50);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 5) {
        final y = yOffset + math.sin(x * waveFrequency) * waveHeight;
        path.lineTo(x, y);
      }

      paint.color = color.withValues(alpha: color.a / (layer + 1));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(MagicalBackgroundPatternPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.tertiaryColor != tertiaryColor;
}
