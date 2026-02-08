import 'package:flutter/material.dart';
import 'dart:math' as math;

class MagicalSplashScreen extends StatefulWidget {
  const MagicalSplashScreen({super.key});

  @override
  State<MagicalSplashScreen> createState() => _MagicalSplashScreenState();
}

class _MagicalSplashScreenState extends State<MagicalSplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowAnimation;
  late Animation<double> _gradientAnimation;
  
  // Particles
  final List<Particle> particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }
  
  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));
    
    _logoRotation = Tween<double>(
      begin: -math.pi / 4,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));
    
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Gradient animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_gradientController);
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Start animations
    _logoController.forward();
  }
  
  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      particles.add(Particle(
        position: Offset(
          random.nextDouble() * 400 - 200,
          random.nextDouble() * 400 - 200,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 2,
          (random.nextDouble() - 0.5) * 2,
        ),
        size: random.nextDouble() * 4 + 1,
        opacity: random.nextDouble() * 0.5 + 0.5,
        color: random.nextBool() 
          ? const Color(0xFF90CAF9) // Light blue
          : const Color(0xFF64B5F6), // Medium blue
      ));
    }
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F1419), // Dark background
      child: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.cos(_gradientAnimation.value) * 0.5,
                      math.sin(_gradientAnimation.value) * 0.5,
                    ),
                    radius: 1.5,
                    colors: const [
                      Color(0xFF1565C0), // Deep blue
                      Color(0xFF0D47A1), // Darker blue
                      Color(0xFF0F1419), // Background
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Particle effects
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Logo with effects
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _pulseController,
              ]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    _logoScale.value * _glowAnimation.value,
                    _logoScale.value * _glowAnimation.value,
                    _logoScale.value * _glowAnimation.value,
                  )..rotateZ(_logoRotation.value),
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          // Outer glow
                          BoxShadow(
                            color: const Color(0xFF90CAF9).withValues(alpha: 0.6 * _glowAnimation.value),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 20 * _glowAnimation.value,
                          ),
                          // Inner glow
                          BoxShadow(
                            color: const Color(0xFF64B5F6).withValues(alpha: 0.8),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Stack(
                          children: [
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF90CAF9).withValues(alpha: 0.3),
                                    const Color(0xFF1565C0).withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                            // App image
                            Image.asset(
                              'assets/app_image_icon.png',
                              fit: BoxFit.cover,
                            ),
                            // Shimmer effect
                            ShimmerOverlay(
                              animation: _logoController,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // App name with fade in
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _logoController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                  )).value,
                  child: Column(
                    children: [
                      Text(
                        'Smart Storage Analyzer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF90CAF9).withValues(alpha: 0.8),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Loading indicator
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF90CAF9).withValues(alpha: _glowAnimation.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class
class Particle {
  Offset position;
  final Offset velocity;
  final double size;
  final double opacity;
  final Color color;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  
  ParticlePainter({
    required this.particles,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (final particle in particles) {
      // Update particle position
      particle.position += particle.velocity;
      
      // Wrap around screen
      if (particle.position.dx > 200) particle.position = Offset(-200, particle.position.dy);
      if (particle.position.dx < -200) particle.position = Offset(200, particle.position.dy);
      if (particle.position.dy > 200) particle.position = Offset(particle.position.dx, -200);
      if (particle.position.dy < -200) particle.position = Offset(particle.position.dx, 200);
      
      // Draw particle
      paint.color = particle.color.withValues(alpha: particle.opacity * 0.6);
      canvas.drawCircle(
        center + particle.position,
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Shimmer effect overlay
class ShimmerOverlay extends StatelessWidget {
  final Animation<double> animation;
  
  const ShimmerOverlay({
    super.key,
    required this.animation,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Color(0x40FFFFFF),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(animation.value * 2 * math.pi),
            ).createShader(bounds);
          },
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }
}