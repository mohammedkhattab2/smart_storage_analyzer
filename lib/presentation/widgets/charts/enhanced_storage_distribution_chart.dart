import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/presentation/mappers/category_ui_mapper.dart';

/// Enhanced storage distribution chart showing all categories and free space
class EnhancedStorageDistributionChart extends StatefulWidget {
  final double totalSpace;
  final double freeSpace;
  final List<Category> categories;

  const EnhancedStorageDistributionChart({
    super.key,
    required this.totalSpace,
    required this.freeSpace,
    required this.categories,
  });

  @override
  State<EnhancedStorageDistributionChart> createState() =>
      _EnhancedStorageDistributionChartState();
}

class _EnhancedStorageDistributionChartState
    extends State<EnhancedStorageDistributionChart>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.elasticOut,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate percentages for all segments
    final List<ChartSegment> segments = [];
    
    // Add category segments
    for (final category in widget.categories) {
      final percentage = widget.totalSpace > 0
          ? (category.sizeInBytes / widget.totalSpace * 100)
          : 0.0;
      segments.add(ChartSegment(
        name: category.name,
        value: category.sizeInBytes.toDouble(),
        percentage: percentage,
        color: _getCategoryColor(context, category.name),
        icon: CategoryUIMapper.getIcon(category.id),
        isCategory: true,
      ));
    }

    // Add free space segment
    final freePercentage = widget.totalSpace > 0
        ? (widget.freeSpace / widget.totalSpace * 100)
        : 0.0;
    segments.add(ChartSegment(
      name: 'Free Space',
      value: widget.freeSpace,
      percentage: freePercentage,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      icon: Icons.storage_rounded,
      isCategory: false,
    ));

    // Sort segments by value (largest first) but keep free space at the end
    segments.sort((a, b) {
      if (a.name == 'Free Space') return 1;
      if (b.name == 'Free Space') return -1;
      return b.value.compareTo(a.value);
    });

    final totalGb = widget.totalSpace / (1024 * 1024 * 1024);
    final usedGb = (widget.totalSpace - widget.freeSpace) / (1024 * 1024 * 1024);
    final usedPercentage = 100 - freePercentage;

    return Container(
      constraints: const BoxConstraints(minHeight: 500, maxHeight: 600),
      margin: const EdgeInsets.symmetric(horizontal: 0), // Full width margins
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated magical background
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.secondary.withValues(alpha: 0.05),
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
                width: 320 + (_pulseController.value * 20),
                height: 320 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
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
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
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
                      // Enhanced header
                      _buildEnhancedHeader(context, totalGb, usedGb),

                      const SizedBox(height: 32),

                      // Main chart - responsive layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 600;
                          
                          if (isSmallScreen) {
                            // Vertical layout for small screens
                            return Column(
                              children: [
                                SizedBox(
                                  height: 260,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Floating particles
                                      ..._buildFloatingParticles(colorScheme),

                                      // Enhanced pie chart
                                      AnimatedBuilder(
                                        animation: _chartAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _chartAnimation.value,
                                            child: PieChart(
                                              PieChartData(
                                                pieTouchData: PieTouchData(
                                                  touchCallback: (FlTouchEvent event,
                                                      pieTouchResponse) {
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
                                                sectionsSpace: 2,
                                                centerSpaceRadius: 70,
                                                sections:
                                                    _buildChartSections(segments),
                                                startDegreeOffset: -90,
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Center content
                                      _buildCenterContent(
                                        context,
                                        usedPercentage,
                                        usedGb,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Legend below chart for small screens
                                _buildDetailedLegend(context, segments),
                              ],
                            );
                          }
                          
                          // Horizontal layout for larger screens
                          return SizedBox(
                            height: 260,
                            child: Row(
                              children: [
                                // Pie chart
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Floating particles
                                      ..._buildFloatingParticles(colorScheme),

                                      // Enhanced pie chart
                                      AnimatedBuilder(
                                        animation: _chartAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _chartAnimation.value,
                                            child: PieChart(
                                              PieChartData(
                                                pieTouchData: PieTouchData(
                                                  touchCallback: (FlTouchEvent event,
                                                      pieTouchResponse) {
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
                                                sectionsSpace: 2,
                                                centerSpaceRadius: 80,
                                                sections:
                                                    _buildChartSections(segments),
                                                startDegreeOffset: -90,
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Center content
                                      _buildCenterContent(
                                        context,
                                        usedPercentage,
                                        usedGb,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Legend with all categories
                                Expanded(
                                  flex: 2,
                                  child: _buildDetailedLegend(context, segments),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Storage summary bar
                      _buildStorageSummaryBar(
                        context,
                        totalGb: totalGb,
                        segments: segments,
                      ),

                      const SizedBox(height: 16),

                      // Quick insights
                      _buildQuickInsights(context, segments),
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

  Widget _buildEnhancedHeader(
    BuildContext context,
    double totalGb,
    double usedGb,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        if (isSmallScreen) {
          // Stack layout for small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ).createShader(bounds),
                child: Text(
                  'Storage Distribution',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete breakdown of your storage',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatGb(usedGb)} / ${_formatGb(totalGb)} GB',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        // Row layout for larger screens
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ).createShader(bounds),
                    child: Text(
                      'Storage Distribution',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete breakdown of your storage usage',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatGb(usedGb)} / ${_formatGb(totalGb)} GB',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildCenterContent(
    BuildContext context,
    double usedPercentage,
    double usedGb,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.surface.withValues(alpha: 0.95),
                colorScheme.surface.withValues(alpha: 0.9),
                colorScheme.primary.withValues(alpha: 0.1),
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
            border: Border.all(
              width: 2,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: 0.4 + (_pulseController.value * 0.2),
                ),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ).createShader(bounds),
                      child: Text(
                        '${value.round()}%',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: -2,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'Used Space',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_formatGb(usedGb)} GB',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildChartSections(List<ChartSegment> segments) {
    bool isTouched(int index) => _touchedIndex == index;

    return segments.asMap().entries.map((entry) {
      final index = entry.key;
      final segment = entry.value;
      final touched = isTouched(index);

      return PieChartSectionData(
        color: segment.color,
        value: segment.percentage,
        title: '',
        radius: touched ? 75 : 65,
        badgeWidget: touched
            ? _buildBadge(segment.percentage, segment.color, segment.icon)
            : null,
        badgePositionPercentageOffset: 0.85,
      );
    }).toList();
  }

  Widget _buildBadge(double percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedLegend(BuildContext context, List<ChartSegment> segments) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) {
          final isActive = segments.indexOf(segment) == _touchedIndex;
          return _buildLegendItem(context, segment, isActive);
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    ChartSegment segment,
    bool isActive,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  segment.color.withValues(alpha: 0.1),
                  segment.color.withValues(alpha: 0.05),
                ]
              : [Colors.transparent, Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1.5,
          color: isActive
              ? segment.color.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  segment.color,
                  segment.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: segment.color.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              segment.icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: segment.isCategory
                        ? colorScheme.onSurface
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  SizeFormatter.formatBytes(segment.value.toInt()),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${segment.percentage.toStringAsFixed(1)}%',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isActive ? segment.color : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSummaryBar(
    BuildContext context, {
    required double totalGb,
    required List<ChartSegment> segments,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Breakdown',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_formatGb(totalGb)} GB Total',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 24,
                  child: Row(
                    children: segments.map((segment) {
                      return Expanded(
                        flex: (segment.percentage * 100 * _chartAnimation.value)
                            .round(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: segment.color,
                            boxShadow: [
                              BoxShadow(
                                color: segment.color.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights(BuildContext context, List<ChartSegment> segments) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Find the largest category
    final categorySegments =
        segments.where((s) => s.name != 'Free Space').toList();
    final largestCategory = categorySegments.isNotEmpty
        ? categorySegments.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Calculate free space percentage
    final freeSpaceSegment =
        segments.firstWhere((s) => s.name == 'Free Space');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.05),
                  colorScheme.primary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Largest Category',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (largestCategory != null)
                        Text(
                          '${largestCategory.name} (${largestCategory.percentage.toStringAsFixed(1)}%)',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.05),
                  colorScheme.secondary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storage_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Space',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${freeSpaceSegment.percentage.toStringAsFixed(1)}% Free',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingParticles(ColorScheme colorScheme) {
    return List.generate(6, (index) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          final progress = (_particleController.value + (index * 0.15)) % 1.0;
          final angle = index * (math.pi * 2 / 6) + (progress * math.pi * 2);
          final radius = 100 + (math.sin(progress * math.pi * 2) * 20);

          return Transform.translate(
            offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
            child: Container(
              width: 6 + (math.sin(progress * math.pi * 2) * 4),
              height: 6 + (math.sin(progress * math.pi * 2) * 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(
                  alpha: 0.6 * (1 - progress),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
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

  String _formatGb(double gb) {
    if (gb <= 0) return "0";
    if ((gb % 1) == 0) {
      return gb.toInt().toString();
    } else {
      return gb.toStringAsFixed(1);
    }
  }
}

class ChartSegment {
  final String name;
  final double value;
  final double percentage;
  final Color color;
  final IconData icon;
  final bool isCategory;

  ChartSegment({
    required this.name,
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.isCategory,
  });
}