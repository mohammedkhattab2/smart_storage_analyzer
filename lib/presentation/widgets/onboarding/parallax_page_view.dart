import 'dart:math' as math;

import 'package:flutter/material.dart';

class ParallaxPageView extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const ParallaxPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
  });

  @override
  State<ParallaxPageView> createState() => _ParallaxPageViewState();
}

class _ParallaxPageViewState extends State<ParallaxPageView> {
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    
    widget.controller.addListener(() {
      setState(() {
        _currentPage = widget.controller.page ?? 0.0;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      onPageChanged: widget.onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        // Simply return the page without any animations
        return widget.children[index];
      },
    );
  }
}

class LiquidPageView extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;
  final List<Color> backgroundColors;

  const LiquidPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
    required this.backgroundColors,
  });

  @override
  State<LiquidPageView> createState() => _LiquidPageViewState();
}

class _LiquidPageViewState extends State<LiquidPageView> {
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _currentPage = widget.controller.page ?? 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentPage.floor();
    final nextIndex = (currentIndex + 1) % widget.backgroundColors.length;
    final progress = _currentPage - currentIndex;

    return Stack(
      children: [
        // Static Background with current color
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  widget.backgroundColors[currentIndex],
                  widget.backgroundColors[nextIndex],
                  progress,
                )!,
                Color.lerp(
                  widget.backgroundColors[currentIndex].withValues(alpha: 0.7),
                  widget.backgroundColors[nextIndex].withValues(alpha: 0.7),
                  progress,
                )!,
              ],
            ),
          ),
        ),

        // Static Wave
        CustomPaint(
          size: Size.infinite,
          painter: WavePainter(progress: _currentPage % 1),
        ),

        // Page Content
        PageView.builder(
          controller: widget.controller,
          onPageChanged: widget.onPageChanged,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.children.length,
          itemBuilder: (context, index) {
            return widget.children[index];
          },
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 50.0;
    final waveLength = size.width;

    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x++) {
      final relativeX = x / waveLength;
      final sine = math.sin((relativeX + progress) * 2 * math.pi);
      final y = size.height * 0.5 + (sine * waveHeight);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Cubic Transition PageView
class CubicPageView extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const CubicPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
  });

  @override
  State<CubicPageView> createState() => _CubicPageViewState();
}

class _CubicPageViewState extends State<CubicPageView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      onPageChanged: widget.onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        // Simply return the page without any transformations
        return widget.children[index];
      },
    );
  }
}
