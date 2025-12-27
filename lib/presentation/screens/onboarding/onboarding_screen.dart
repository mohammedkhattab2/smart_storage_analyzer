import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../cubits/onboarding/onboarding_state.dart';
import '../../widgets/onboarding/onboarding_page_widget.dart';
import '../../widgets/onboarding/page_indicator_widget.dart';
import '../../widgets/onboarding/parallax_page_view.dart';
import '../../widgets/common/custom_button.dart';

/// Onboarding Screen - مسؤول عن الـ BlocProvider فقط
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: OnboardingView(),
    );
  }
}

/// Onboarding View - مسؤول عن الـ UI
class OnboardingView extends StatefulWidget {
  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated Background Pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        -1 + 2 * _backgroundAnimation.value,
                        -1 + 2 * _backgroundAnimation.value,
                      ),
                      end: Alignment(
                        1 - 2 * _backgroundAnimation.value,
                        1 - 2 * _backgroundAnimation.value,
                      ),
                      colors: [
                        AppColors.background,
                        AppColors.cardBackground.withOpacity(0.5),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Geometric Patterns
          CustomPaint(
            size: Size.infinite,
            painter: BackgroundPatternPainter(),
          ),

          // Main Content
          SafeArea(
            child: BlocConsumer<OnboardingCubit, OnboardingState>(
              listener: (context, state) {
                if (state is OnboardingCompleted) {
                  context.go(AppRoutes.dashboard);
                }
              },
              builder: (context, state) {
                if (state is OnboardingLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (state is OnboardingPageState) {
                  return Column(
                    children: [
                      // Skip Button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextButton(
                            onPressed: () {
                              context.read<OnboardingCubit>().completeOnboarding();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PageView للصفحات with Parallax Effect
                      Expanded(
                        child: ParallaxPageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            context.read<OnboardingCubit>().changePage(index);
                          },
                          children: [
                            OnboardingPageWidget(
                              icon: Icons.flash_on,
                              iconColor: Color(0xFF4CAF50),
                              title: 'One-Tap Optimize',
                              description:
                                  'Clean up duplicates, large files, and\nsystem cache with a single tap.',
                            ),
                            OnboardingPageWidget(
                              icon: Icons.pie_chart_outline,
                              iconColor: Color(0xFF9C27B0),
                              title: 'Smart Categories',
                              description:
                                  'Visualize your storage usage with\nbeautiful, interactive charts and\nbreakdowns.',
                            ),
                            OnboardingPageWidget(
                              icon: Icons.phone_android,
                              iconColor: Color(0xFF2196F3),
                              title: 'Deep Analysis',
                              description:
                                  'Scan your device to find hidden clutter\nand reclaim valuable space instantly.',
                            ),
                          ],
                        ),
                      ),

                      // Bottom Section
                      Container(
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background.withOpacity(0.0),
                              AppColors.background,
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

                            // Button with Animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: CustomButton(
                                      text: state.currentPage == 2
                                          ? 'Get Started'
                                          : 'Next',
                                      icon: state.currentPage == 2
                                          ? Icons.rocket_launch
                                          : Icons.arrow_forward,
                                      onPressed: () {
                                        if (state.currentPage == 2) {
                                          context
                                              .read<OnboardingCubit>()
                                              .completeOnboarding();
                                        } else {
                                          _pageController.nextPage(
                                            duration:
                                                const Duration(milliseconds: 500),
                                            curve: Curves.easeInOutCubic,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
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

          // Floating Particles Effect
          ...List.generate(5, (index) {
            return FloatingParticle(
              delay: Duration(seconds: index),
              duration: Duration(seconds: 15 + index * 2),
            );
          }),
        ],
      ),
    );
  }
}

// Background Pattern Painter
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Floating Particle Widget
class FloatingParticle extends StatefulWidget {
  final Duration delay;
  final Duration duration;

  const FloatingParticle({
    Key? key,
    required this.delay,
    required this.duration,
  }) : super(key: key);

  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startX;
  late double _startY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    // Random starting position
    final random = math.Random(widget.delay.inMilliseconds);
    _startX = random.nextDouble();
    _startY = random.nextDouble();

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        final x = _startX * size.width;
        final y = (_startY - progress * 2) * size.height;

        if (y < -100) {
          // Reset position when particle goes off screen
          _startY = 1.0 + progress * 2;
        }

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
