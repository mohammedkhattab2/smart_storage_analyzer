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

/// Onboarding Screen - Ù…Ø³Ø¤ÙˆÙ„ Ø¹Ù† Ø§Ù„Ù€ BlocProvider ÙÙ‚Ø·
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: OnboardingView(),
    );
  }
}

/// Onboarding View - Ù…Ø³Ø¤ÙˆÙ„ Ø¹Ù† Ø§Ù„Ù€ UI
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
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
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: isDark ? .1 : .2),
                    colorScheme.surface,
                    colorScheme.secondaryContainer.withValues(alpha: isDark ? .05 : .1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Geometric Patterns with Theme Colors
          CustomPaint(
            size: Size.infinite,
            painter: BackgroundPatternPainter(
              color: colorScheme.outline.withValues(alpha: .05),
            ),
          ),

          // iOS-style Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                color: colorScheme.surface.withValues(alpha: .01),
              ),
            ),
          ),

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
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (state is OnboardingPageState) {
                  return Column(
                    children: [
                      // Skip Button with iOS-style glassmorphism
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context
                                        .read<OnboardingCubit>()
                                        .completeOnboarding();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainer
                                          .withValues(alpha: isDark ? .3 : .5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colorScheme.outline
                                            .withValues(alpha: .1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Skip',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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

                      // PageView Ù„Ù„ØµÙØ­Ø§Øª with Parallax Effect
                      Expanded(
                        child: ParallaxPageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            HapticFeedback.selectionClick();
                            context.read<OnboardingCubit>().changePage(index);
                          },
                          children: [
                            OnboardingPageWidget(
                              icon: Icons.flash_on_rounded,
                              iconColor: colorScheme.primary,
                              title: 'One-Tap Optimize',
                              description:
                                  'Clean up duplicates, large files, and\nsystem cache with a single tap.',
                            ),
                            OnboardingPageWidget(
                              icon: Icons.pie_chart_rounded,
                              iconColor: colorScheme.secondary,
                              title: 'Smart Categories',
                              description:
                                  'Visualize your storage usage with\nbeautiful, interactive charts and\nbreakdowns.',
                            ),
                            OnboardingPageWidget(
                              icon: Icons.phone_android_rounded,
                              iconColor: colorScheme.tertiary,
                              title: 'Deep Analysis',
                              description:
                                  'Scan your device to find hidden clutter\nand reclaim valuable space instantly.',
                            ),
                          ],
                        ),
                      ),

                      // Bottom Section with gradient fade
                      Container(
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0),
                              colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Page Indicators
                            PageIndicatorWidget(
                              currentPage: state.currentPage,
                              pageCount: 3,
                            ),

                            const SizedBox(height: 40),

                            // Button
                            CustomButton(
                              text: state.currentPage == 2
                                  ? 'Get Started'
                                  : 'Next',
                              icon: state.currentPage == 2
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (state.currentPage == 2) {
                                  context
                                      .read<OnboardingCubit>()
                                      .completeOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    curve: Curves.easeInOutCubic,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
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
}

// Background Pattern Painter
class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw geometric patterns
    final spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Hexagonal pattern
        final path = Path();
        final centerX = x + spacing / 2;
        final centerY = y + spacing / 2;
        final radius = spacing / 3;

        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * 3.14159 / 180;
          final pointX = centerX + radius * math.cos(angle);
          final pointY = centerY + radius * math.sin(angle);

          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

