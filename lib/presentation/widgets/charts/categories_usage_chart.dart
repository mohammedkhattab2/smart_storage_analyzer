import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';

/// Magical categories usage chart with stunning visual effects
class CategoriesUsageChart extends StatefulWidget {
  final List<Category> categories;
  final double totalUsedSpace;

  const CategoriesUsageChart({
    super.key,
    required this.categories,
    required this.totalUsedSpace,
  });

  @override
  State<CategoriesUsageChart> createState() => _CategoriesUsageChartState();
}

class _CategoriesUsageChartState extends State<CategoriesUsageChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatController;
  late AnimationController _sparkleController;
  late Animation<double> _chartAnimation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _chartAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(BuildContext context, String categoryName) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (categoryName.toLowerCase()) {
      case 'images':
      case 'image':
        return colorScheme.imageCategory;
      case 'videos':
      case 'video':
        return colorScheme.videoCategory;
      case 'audio':
      case 'music':
        return colorScheme.audioCategory;
      case 'documents':
      case 'document':
        return colorScheme.documentCategory;
      case 'apps':
      case 'applications':
        return colorScheme.appsCategory;
      case 'others':
      case 'other':
      default:
        return colorScheme.othersCategory;
    }
  }

  List<Color> _getCategoryGradient(BuildContext context, String categoryName) {
    final baseColor = _getCategoryColor(context, categoryName);
    return [
      baseColor,
      baseColor.withValues(alpha: 0.8),
      baseColor.withValues(alpha: 0.6),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort categories by size
    final sortedCategories = List<Category>.from(widget.categories)
      ..sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));

    // Take top 5 categories for better visualization
    final displayCategories = sortedCategories.take(5).toList();

    if (displayCategories.isEmpty) {
      return _buildEmptyState(context);
    }

    // Calculate percentages
    final categoryPercentages = displayCategories.map((cat) {
      return widget.totalUsedSpace > 0
          ? (cat.sizeInBytes / widget.totalUsedSpace * 100)
          : 0.0;
    }).toList();

    return Container(
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.8 + (_floatController.value * 0.4),
                      -0.8 + (_floatController.value * 0.4),
                    ),
                    radius: 1.5,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.secondary.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Main content with glass morphism
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withValues(alpha: isDark ? 0.9 : 0.95),
                  colorScheme.surface.withValues(alpha: isDark ? 0.85 : 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                width: 1,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  children: [
                    // Magical header
                    _buildMagicalHeader(context),

                    const SizedBox(height: 32),

                    // Animated chart
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _chartAnimation,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Floating sparkles
                              ..._buildSparkles(),

                              // Main chart
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: constraints.maxHeight,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: List.generate(
                                        displayCategories.length,
                                        (index) {
                                          final category =
                                              displayCategories[index];
                                          final percentage =
                                              categoryPercentages[index];
                                          final gradientColors =
                                              _getCategoryGradient(
                                                context,
                                                category.name,
                                              );

                                          return _buildMagicalBar(
                                            context,
                                            category: category,
                                            percentage: percentage,
                                            maxHeight:
                                                constraints.maxHeight - 60,
                                            index: index,
                                            gradientColors: gradientColors,
                                            isActive: _touchedIndex == index,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category legend with magical effects
                    _buildMagicalLegend(displayCategories),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.secondary.withValues(alpha: 0.2),
                colorScheme.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: colorScheme.secondary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.donut_large_rounded,
            size: 18,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
          ).createShader(bounds),
          child: Text(
            'Categories Usage',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalBar(
    BuildContext context, {
    required Category category,
    required double percentage,
    required double maxHeight,
    required int index,
    required List<Color> gradientColors,
    required bool isActive,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _touchedIndex = index),
      onTapUp: (_) => setState(() => _touchedIndex = -1),
      onTapCancel: () => setState(() => _touchedIndex = -1),
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final floatOffset =
              math.sin(_floatController.value * math.pi * 2) * 3;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Floating value label
              AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  transform: Matrix4.translationValues(0, floatOffset - 10, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Animated bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (percentage / 100) * maxHeight),
                duration: Duration(milliseconds: 1500 + (index * 200)),
                curve: Curves.elasticOut,
                builder: (context, value, _) {
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Glow effect
                      Container(
                        width: 60,
                        height: value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              gradientColors[0].withValues(alpha: 0.3),
                              gradientColors[0].withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withValues(
                                alpha: isActive ? 0.6 : 0.3,
                              ),
                              blurRadius: isActive ? 30 : 20,
                              spreadRadius: isActive ? 10 : 5,
                            ),
                          ],
                        ),
                      ),

                      // Main bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 56 : 48,
                        height: value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isActive ? 28 : 24),
                            topRight: Radius.circular(isActive ? 28 : 24),
                            bottomLeft: const Radius.circular(8),
                            bottomRight: const Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      // Top orb
                      Positioned(
                        top: 0,
                        child: Container(
                          width: isActive ? 24 : 20,
                          height: isActive ? 24 : 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                gradientColors[0],
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Category icon
              Container(
                padding: EdgeInsets.all(isActive ? 14 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? gradientColors
                        : [
                            gradientColors[0].withValues(alpha: 0.2),
                            gradientColors[1].withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  category.icon,
                  size: isActive ? 26 : 24,
                  color: isActive ? Colors.white : gradientColors[0],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return List.generate(8, (index) {
      return AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, _) {
          final progress = (_sparkleController.value + (index * 0.125)) % 1.0;
          final x = math.Random(index).nextDouble() * 300 - 150;
          final y = 250 - (progress * 300);
          final opacity = 1.0 - progress;

          return Positioned(
            left: x + 150,
            top: y,
            child: Transform.rotate(
              angle: progress * math.pi * 2,
              child: Container(
                width: 4 + (math.Random(index).nextDouble() * 4),
                height: 4 + (math.Random(index).nextDouble() * 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity * 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: opacity * 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMagicalLegend(List<Category> categories) {
    return SizedBox(
      height: 85, // Increased from 80 to fix overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2), // Add padding
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final gradientColors = _getCategoryGradient(context, category.name);
          final isActive = _touchedIndex == index;

          return AnimatedScale(
            scale: isActive ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ), // Reduced from 12
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withValues(alpha: isActive ? 0.2 : 0.1),
                    gradientColors[1].withValues(alpha: isActive ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gradientColors[0].withValues(
                    alpha: isActive ? 0.4 : 0.2,
                  ),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: 18, // Reduced from 20
                    color: gradientColors[0],
                  ),
                  const SizedBox(height: 3), // Reduced from 4
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      fontWeight: FontWeight.w600,
                      color: gradientColors[0],
                    ),
                  ),
                  Text(
                    SizeFormatter.formatBytes(category.sizeInBytes.toInt()),
                    style: TextStyle(
                      fontSize: 9, // Reduced from 10
                      color: gradientColors[0].withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 450,
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
                    colorScheme.secondary.withValues(alpha: 0.1),
                    colorScheme.secondary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Category Data',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category usage will appear here\nonce analysis is complete',
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
}
