import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// A magical storage pie chart with creative visual effects
class StoragePieChart extends StatefulWidget {
  final double usedSpaceGb;
  final double freeSpaceGb;

  const StoragePieChart({
    super.key,
    required this.usedSpaceGb,
    required this.freeSpaceGb,
  });

  @override
  State<StoragePieChart> createState() => _StoragePieChartState();
}

class _StoragePieChartState extends State<StoragePieChart>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _chartAnimation;
  late AnimationController _chartAnimationController;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();

    // Main chart animation
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.elasticOut,
    );

    // Rotation animation for background elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulse animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate total and percentages
    final totalGb = widget.usedSpaceGb + widget.freeSpaceGb;
    final usedPercentage = totalGb > 0
        ? (widget.usedSpaceGb / totalGb * 100)
        : 0.0;
    final freePercentage = totalGb > 0
        ? (widget.freeSpaceGb / totalGb * 100)
        : 0.0;
    final isHighUsage = usedPercentage > 80;

    if (totalGb <= 0) {
      return _buildEmptyState(context);
    }

    // Define magical gradient colors
    final List<Color> magicalGradient = isHighUsage
        ? [
            const Color(0xFFFF6B6B),
            const Color(0xFFEE5A6F),
            const Color(0xFFD83F87),
            const Color(0xFFC44569),
          ]
        : [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
            const Color(0xFF6B8DD6),
            const Color(0xFF8E37D7),
          ];

    return Container(
      constraints: const BoxConstraints(minHeight: 350, maxHeight: 450),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background with magical effects
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        magicalGradient[0].withValues(alpha: 0.1),
                        magicalGradient[1].withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Pulsing glow effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 280 + (_pulseController.value * 20),
                height: 280 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: magicalGradient[0].withValues(
                        alpha: 0.3 * (1 - _pulseController.value),
                      ),
                      blurRadius: 50 + (_pulseController.value * 30),
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main content card with glass effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withValues(alpha: isDark ? 0.9 : 0.95),
                  colorScheme.surface.withValues(alpha: isDark ? 0.8 : 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                width: 1,
                color: LinearGradient(
                  colors: [
                    magicalGradient[0].withValues(alpha: 0.3),
                    magicalGradient[1].withValues(alpha: 0.1),
                  ],
                ).colors.first,
              ),
              boxShadow: [
                BoxShadow(
                  color: magicalGradient[0].withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Magical header
                      _buildMagicalHeader(context, magicalGradient),

                      const SizedBox(height: 24),

                      // Animated Chart Container
                      SizedBox(
                        height: 180,
                        child: AnimatedBuilder(
                          animation: _chartAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Floating particles
                                ..._buildFloatingParticles(magicalGradient),

                                // Main pie chart with magical effects
                                Transform.scale(
                                  scale: _chartAnimation.value,
                                  child: PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback:
                                            (
                                              FlTouchEvent event,
                                              pieTouchResponse,
                                            ) {
                                              setState(() {
                                                if (!event
                                                        .isInterestedForInteractions ||
                                                    pieTouchResponse == null ||
                                                    pieTouchResponse
                                                            .touchedSection ==
                                                        null) {
                                                  _touchedIndex = -1;
                                                  return;
                                                }
                                                _touchedIndex = pieTouchResponse
                                                    .touchedSection!
                                                    .touchedSectionIndex;
                                              });
                                            },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 70,
                                      sections: _buildMagicalChartSections(
                                        context,
                                        usedPercentage:
                                            usedPercentage *
                                            _chartAnimation.value,
                                        freePercentage:
                                            freePercentage *
                                            _chartAnimation.value,
                                        magicalGradient: magicalGradient,
                                      ),
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),

                                // Center magical orb
                                _buildCenterOrb(
                                  context,
                                  usedPercentage,
                                  magicalGradient,
                                  isHighUsage,
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Magical legend
                      _buildMagicalLegend(
                        context,
                        usedPercentage: usedPercentage,
                        freePercentage: freePercentage,
                        magicalGradient: magicalGradient,
                        isHighUsage: isHighUsage,
                      ),

                      const SizedBox(height: 16),

                      // Total capacity with magical progress
                      _buildMagicalProgress(
                        context,
                        totalGb: totalGb,
                        usedPercentage: usedPercentage,
                        magicalGradient: magicalGradient,
                        isHighUsage: isHighUsage,
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalHeader(BuildContext context, List<Color> gradientColors) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withValues(alpha: 0.2),
                gradientColors[1].withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.storage_rounded,
            size: 28,
            color: gradientColors[0],
          ),
        ),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: gradientColors).createShader(bounds),
          child: Text(
            'Storage Overview',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterOrb(
    BuildContext context,
    double usedPercentage,
    List<Color> gradientColors,
    bool isHighUsage,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.surface.withValues(alpha: 0.95),
                colorScheme.surface.withValues(alpha: 0.9),
                gradientColors[0].withValues(alpha: 0.1),
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
            border: Border.all(
              width: 2,
              color: gradientColors[0].withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(
                  alpha: 0.4 + (_pulseController.value * 0.2),
                ),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: usedPercentage),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.elasticOut,
                    builder: (context, value, _) {
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ).createShader(bounds),
                        child: Text(
                          '${value.round()}%',
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: -2,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Used',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles(List<Color> gradientColors) {
    return List.generate(6, (index) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          final progress = (_particleController.value + (index * 0.15)) % 1.0;
          final angle = index * (math.pi * 2 / 6) + (progress * math.pi * 2);
          final radius = 90 + (math.sin(progress * math.pi * 2) * 20);

          return Transform.translate(
            offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
            child: Container(
              width: 6 + (math.sin(progress * math.pi * 2) * 4),
              height: 6 + (math.sin(progress * math.pi * 2) * 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradientColors[index % gradientColors.length].withValues(
                  alpha: 0.6 * (1 - progress),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[index % gradientColors.length]
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  List<PieChartSectionData> _buildMagicalChartSections(
    BuildContext context, {
    required double usedPercentage,
    required double freePercentage,
    required List<Color> magicalGradient,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isTouched(int index) => _touchedIndex == index;

    return [
      PieChartSectionData(
        color: magicalGradient[0],
        value: usedPercentage,
        title: '',
        radius: isTouched(0) ? 70 : 60,
        badgeWidget: isTouched(0)
            ? _buildBadge(usedPercentage, magicalGradient[0])
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
      PieChartSectionData(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        value: freePercentage,
        title: '',
        radius: isTouched(1) ? 70 : 60,
        badgeWidget: isTouched(1)
            ? _buildBadge(freePercentage, colorScheme.surfaceContainerHighest)
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
    ];
  }

  Widget _buildBadge(double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${percentage.round()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMagicalLegend(
    BuildContext context, {
    required double usedPercentage,
    required double freePercentage,
    required List<Color> magicalGradient,
    required bool isHighUsage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildMagicalLegendItem(
            context,
            gradientColors: magicalGradient,
            label: 'Used Space',
            value: '${_formatGb(widget.usedSpaceGb)} GB',
            percentage: usedPercentage,
            isActive: _touchedIndex == 0,
          ),
        ),
        Container(
          height: 50,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.outline.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildMagicalLegendItem(
            context,
            gradientColors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            ],
            label: 'Available',
            value: '${_formatGb(widget.freeSpaceGb)} GB',
            percentage: freePercentage,
            isActive: _touchedIndex == 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalLegendItem(
    BuildContext context, {
    required List<Color> gradientColors,
    required String label,
    required String value,
    required double percentage,
    required bool isActive,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: isActive ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [
                    gradientColors[0].withValues(alpha: 0.1),
                    gradientColors.last.withValues(alpha: 0.05),
                  ]
                : [Colors.transparent, Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1.5,
            color: isActive
                ? gradientColors[0].withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isActive ? gradientColors[0] : colorScheme.onSurface,
                  ),
                ),
                ],
              ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildMagicalProgress(
    BuildContext context, {
    required double totalGb,
    required double usedPercentage,
    required List<Color> magicalGradient,
    required bool isHighUsage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Capacity',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: magicalGradient,
                ).createShader(bounds),
                child: Text(
                  '${_formatGb(totalGb)} GB',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (usedPercentage / 100) * _chartAnimation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: magicalGradient),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: magicalGradient[0].withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storage_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Storage Data',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Storage information will appear here\nonce data is available',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGb(double gb) {
    if (gb <= 0) return "0";
    if ((gb % 1) == 0) {
      return gb.toInt().toString();
    } else {
      return gb.toStringAsFixed(1);
    }
  }
}
