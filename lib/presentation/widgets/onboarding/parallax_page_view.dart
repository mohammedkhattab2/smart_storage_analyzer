import 'dart:math' as math;

import 'package:flutter/material.dart';

class ParallaxPageView extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const ParallaxPageView({
    Key? key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
  }) : super(key: key);

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
        final page = widget.children[index];
        final isCurrentPage = index == _currentPage.floor();
        final isNextPage = index == _currentPage.floor() + 1;
        
        double parallaxOffset = 0.0;
        double scaleValue = 1.0;
        double opacityValue = 1.0;
        double rotationValue = 0.0;
        
        if (isCurrentPage) {
          // Current page moving out
          final progress = _currentPage - index;
          parallaxOffset = progress * 100;
          scaleValue = 1 - (progress * 0.1);
          opacityValue = 1 - (progress * 0.3);
          rotationValue = progress * 0.02;
        } else if (isNextPage) {
          // Next page coming in
          final progress = _currentPage - (index - 1);
          parallaxOffset = (1 - progress) * -50;
          scaleValue = 0.9 + (progress * 0.1);
          opacityValue = 0.7 + (progress * 0.3);
          rotationValue = (1 - progress) * -0.02;
        } else if (index < _currentPage) {
          // Previous pages
          parallaxOffset = 100;
          scaleValue = 0.9;
          opacityValue = 0.7;
        } else {
          // Future pages
          parallaxOffset = -50;
          scaleValue = 0.9;
          opacityValue = 0.7;
        }

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(parallaxOffset, 0.0)
            ..scale(scaleValue)
            ..rotateZ(rotationValue),
          child: Opacity(
            opacity: opacityValue.clamp(0.0, 1.0),
            child: page,
          ),
        );
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
    Key? key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
    required this.backgroundColors,
  }) : super(key: key);

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
    return Stack(
      children: [
        // Animated Background
        AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final currentIndex = _currentPage.floor();
            final nextIndex = (currentIndex + 1) % widget.backgroundColors.length;
            final progress = _currentPage - currentIndex;
            
            return Container(
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
                      widget.backgroundColors[currentIndex].withOpacity(0.7),
                      widget.backgroundColors[nextIndex].withOpacity(0.7),
                      progress,
                    )!,
                  ],
                ),
              ),
            );
          },
        ),
        
        // Wave Clipper
        AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: WavePainter(progress: _currentPage % 1),
            );
          },
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
      ..color = Colors.white.withOpacity(0.05)
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
    Key? key,
    required this.controller,
    required this.onPageChanged,
    required this.children,
  }) : super(key: key);

  @override
  State<CubicPageView> createState() => _CubicPageViewState();
}

class _CubicPageViewState extends State<CubicPageView> {
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
        final isCurrentPage = index == _currentPage.floor();
        final isNextPage = index == _currentPage.floor() + 1;
        final progress = _currentPage - _currentPage.floor();
        
        Widget transformedPage = widget.children[index];
        
        if (isCurrentPage) {
          // Apply cubic rotation to current page
          transformedPage = Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-progress * math.pi / 2),
            child: transformedPage,
          );
        } else if (isNextPage) {
          // Apply cubic rotation to next page
          transformedPage = Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi / 2 * (1 - progress)),
            child: transformedPage,
          );
        }
        
        return transformedPage;
      },
    );
  }
}
