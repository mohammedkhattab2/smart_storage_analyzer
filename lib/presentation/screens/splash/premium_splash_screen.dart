import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class PremiumSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const PremiumSplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  
  // Master controller for orchestration
  late AnimationController _masterController;
  
  // Individual animation controllers
  late AnimationController _iconController;
  late AnimationController _breathingController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _rippleController;
  
  // Animations
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _iconOpacity;
  late Animation<double> _iconGlow;
  late Animation<double> _breathing;
  late Animation<double> _shimmerProgress;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _progressValue;
  late Animation<double> _rippleAnimation;
  
  // Visual effects
  final List<FloatingOrb> _orbs = [];
  final List<SparkleParticle> _sparkles = [];
  final List<MagicalRing> _rings = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateVisualEffects();
    _startAnimationSequence();
  }
  
  void _initializeAnimations() {
    // Master controller (controls overall duration)
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Icon entrance animation with magic
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    
    _iconScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));
    
    _iconRotation = Tween<double>(
      begin: math.pi * 0.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuint),
    ));
    
    _iconOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
    
    _iconGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));
    
    // Breathing pulse effect
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathing = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _shimmerProgress = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(_shimmerController);
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Ripple effect
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _textSlide = Tween<double>(
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuint),
    ));
    
    // Progress animation
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
    ));
    
    // Listen for completion
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }
  
  void _generateVisualEffects() {
    final random = math.Random();
    
    // Generate floating orbs with gradient colors
    for (int i = 0; i < 15; i++) {
      _orbs.add(FloatingOrb(
        initialPosition: Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        ),
        size: random.nextDouble() * 80 + 30,
        speed: random.nextDouble() * 0.3 + 0.1,
        color: _getOrbColor(i),
      ));
    }
    
    // Generate sparkle particles
    for (int i = 0; i < 40; i++) {
      _sparkles.add(SparkleParticle(
        angle: random.nextDouble() * 2 * math.pi,
        distance: random.nextDouble() * 200 + 80,
        size: random.nextDouble() * 4 + 1,
        delay: random.nextDouble(),
        duration: random.nextDouble() * 3 + 1,
      ));
    }
    
    // Generate magical rings
    for (int i = 0; i < 3; i++) {
      _rings.add(MagicalRing(
        radius: 100.0 + i * 50,
        opacity: 0.3 - i * 0.1,
        rotationSpeed: (i + 1) * 0.5,
      ));
    }
  }
  
  Color _getOrbColor(int index) {
    final colors = [
      const Color(0xFF64B5F6).withValues(alpha: 0.12),
      const Color(0xFF90CAF9).withValues(alpha:  0.10),
      const Color(0xFF42A5F5).withValues(alpha:  0.08),
      const Color(0xFF2196F3).withValues(alpha:  0.06),
      const Color(0xFF1E88E5).withValues(alpha:  0.08),
    ];
    return colors[index % colors.length];
  }
  
  void _startAnimationSequence() async {
    // Start background animations immediately
    _particleController.forward();
    
    // Icon entrance with delay
    await Future.delayed(const Duration(milliseconds: 200));
    _iconController.forward();
    _rippleController.forward();
    
    // Start breathing after icon appears
    await Future.delayed(const Duration(milliseconds: 600));
    _breathingController.forward();
    
    // Text and progress
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Start master timeline
    _masterController.forward();
  }
  
  @override
  void dispose() {
    _masterController.dispose();
    _iconController.dispose();
    _breathingController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _rippleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Set system UI for edge-to-edge display
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        // Transparent navigation bar for edge-to-edge
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.5),
            radius: 2.0,
            colors: [
              Color(0xFF141922), // Slightly lighter center
              Color(0xFF0F1419), // Deep dark blue
              Color(0xFF0A0E17), // Darker edge
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated gradient mesh background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GradientMeshPainter(
                    progress: _particleController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Floating orbs background
            ...List.generate(_orbs.length, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final orb = _orbs[index];
                  final progress = _particleController.value;
                  final offset = orb.calculatePosition(progress);
                  
                  return Positioned(
                    left: MediaQuery.of(context).size.width * (0.5 + offset.dx * 0.5),
                    top: MediaQuery.of(context).size.height * (0.5 + offset.dy * 0.5),
                    child: Transform.translate(
                      offset: Offset(-orb.size / 2, -orb.size / 2),
                      child: Container(
                        width: orb.size,
                        height: orb.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              orb.color,
                              orb.color.withValues(alpha:  0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Magical rings
            Center(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: _rings.map((ring) {
                      final rotation = _particleController.value * ring.rotationSpeed * 2 * math.pi;
                      return Transform.rotate(
                        angle: rotation,
                        child: Container(
                          width: ring.radius * 2,
                          height: ring.radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF64B5F6).withValues(alpha:  ring.opacity * 0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            
            // Ripple effect
            Center(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Container(
                    width: 400 * _rippleAnimation.value,
                    height: 400 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF64B5F6).withValues( 
                          alpha: (1 - _rippleAnimation.value) * 0.3,
                        ),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with magical effects
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _iconController,
                      _breathingController,
                      _shimmerController,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconScale.value * _breathing.value,
                        child: Transform.rotate(
                          angle: _iconRotation.value,
                          child: Opacity(
                            opacity: _iconOpacity.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow effect
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF64B5F6).withValues(alpha:  0.4 * _iconGlow.value),
                                        blurRadius: 60,
                                        spreadRadius: 20,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF42A5F5).withValues(alpha:  0.3 * _iconGlow.value),
                                        blurRadius: 120,
                                        spreadRadius: 40,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Sparkle particles around icon
                                ..._sparkles.map((sparkle) {
                                  final progress = (_masterController.value - sparkle.delay).clamp(0.0, 1.0);
                                  if (progress == 0) return const SizedBox.shrink();
                                  
                                  final sparkleOpacity = math.sin(progress * math.pi);
                                  final distance = sparkle.distance * (0.5 + 0.5 * math.sin(progress * 2 * math.pi));
                                  final x = math.cos(sparkle.angle) * distance;
                                  final y = math.sin(sparkle.angle) * distance;
                                  
                                  return Transform.translate(
                                    offset: Offset(x, y),
                                    child: Container(
                                      width: sparkle.size * (1 + sparkleOpacity * 0.5),
                                      height: sparkle.size * (1 + sparkleOpacity * 0.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha:  sparkleOpacity * 0.9),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF90CAF9).withValues(alpha:  sparkleOpacity),
                                            blurRadius: sparkle.size * 3,
                                            spreadRadius: sparkle.size,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                
                                // Icon container with glass morphism
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF1565C0).withValues(alpha:  0.15),
                                        const Color(0xFF0D47A1).withValues(alpha:  0.05),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF64B5F6).withValues(alpha:  0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withValues(alpha:  0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(38),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Stack(
                                        children: [
                                          // App icon - using the correct file
                                          Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Image.asset(
                                              'assets/app_image_icon.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          
                                          // Animated shimmer overlay
                                          Positioned.fill(
                                            child: ShaderMask(
                                              shaderCallback: (bounds) {
                                                return LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: const [
                                                    Colors.transparent,
                                                    Color(0x15FFFFFF),
                                                    Color(0x30FFFFFF),
                                                    Color(0x15FFFFFF),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                                                  transform: GradientRotation(
                                                    _shimmerProgress.value * math.pi,
                                                  ),
                                                ).createShader(bounds);
                                              },
                                              child: Container(
                                                color: Colors.white,
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
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // App name and loading
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              // App name with gradient
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFFBBDEFB),
                                      Color(0xFF90CAF9),
                                      Color(0xFF64B5F6),
                                      Color(0xFF42A5F5),
                                    ],
                                    stops: [0.0, 0.3, 0.6, 1.0],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Smart Storage',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ANALYZER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 10,
                                  color: const Color(0xFF90CAF9).withValues(alpha:  0.6),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 50),
                              
                              // Premium loading indicator with gradient
                              Container(
                                width: 220,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.white.withValues(alpha:  0.08),
                                ),
                                child: AnimatedBuilder(
                                  animation: _masterController,
                                  builder: (context, child) {
                                    return Stack(
                                      children: [
                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progressValue.value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF1E88E5),
                                                  Color(0xFF42A5F5),
                                                  Color(0xFF64B5F6),
                                                  Color(0xFF90CAF9),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF64B5F6).withValues(alpha:  0.6),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Progress glow at the end
                                        if (_progressValue.value > 0)
                                          Positioned(
                                            left: 220 * _progressValue.value - 10,
                                            top: -8,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF90CAF9).withValues(alpha:  0.8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF90CAF9).withValues(alpha:  0.6),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Loading text
                              Text(
                                'Initializing...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64B5F6).withValues(alpha:  0.6),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data classes
class FloatingOrb {
  final Offset initialPosition;
  final double size;
  final double speed;
  final Color color;
  
  FloatingOrb({
    required this.initialPosition,
    required this.size,
    required this.speed,
    required this.color,
  });
  
  Offset calculatePosition(double progress) {
    final t = progress * speed * 2 * math.pi;
    final x = initialPosition.dx + math.sin(t) * 0.3;
    final y = initialPosition.dy + math.cos(t * 0.7) * 0.3;
    return Offset(x, y);
  }
}

class SparkleParticle {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final double duration;
  
  SparkleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.duration,
  });
}

class MagicalRing {
  final double radius;
  final double opacity;
  final double rotationSpeed;
  
  MagicalRing({
    required this.radius,
    required this.opacity,
    required this.rotationSpeed,
  });
}

// Custom gradient mesh painter
class GradientMeshPainter extends CustomPainter {
  final double progress;
  
  GradientMeshPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    
    // Create animated gradient mesh
    final time = progress * 2 * math.pi;
    
    // Draw multiple gradient circles
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        size.width * (0.5 + 0.3 * math.cos(time + i * 2)),
        size.height * (0.5 + 0.3 * math.sin(time * 0.7 + i * 2)),
      );
      
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF1565C0).withValues(alpha:  0.05),
          const Color(0xFF0D47A1).withValues(alpha:  0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: offset,
        radius: size.width * 0.5,
      ));
      
      canvas.drawCircle(offset, size.width * 0.5, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}