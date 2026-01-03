import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class ModernUsageChart extends StatefulWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;

  const ModernUsageChart({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  State<ModernUsageChart> createState() => _ModernUsageChartState();
}

class _ModernUsageChartState extends State<ModernUsageChart> 
    with SingleTickerProviderStateMixin {
  int? touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surface.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header
              _buildModernHeader(theme, colorScheme),
              const SizedBox(height: 24),
              
              // Chart Area
              Expanded(
                child: widget.dataPoints.isEmpty
                    ? _buildEmptyState(theme, colorScheme)
                    : _buildModernChart(theme, colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(ThemeData theme, ColorScheme colorScheme) {
    final IconData periodIcon = _getPeriodIcon();
    final String subtitle = _getPeriodSubtitle();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      periodIcon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Storage Usage',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        fontSize: 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Animated indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Storage data will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChart(ThemeData theme, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return LineChart(
          LineChartData(
            // Grid configuration
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _getHorizontalInterval(),
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            
            // Titles configuration
            titlesData: FlTitlesData(
              show: true,
              // Bottom titles (X-axis)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return _buildBottomLabel(value.toInt(), theme, colorScheme);
                  },
                ),
              ),
              // Left titles (Y-axis)
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 65,
                  interval: _getLeftInterval(),
                  getTitlesWidget: (value, meta) {
                    return _buildLeftLabel(value, theme, colorScheme);
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            
            // Chart bounds
            minX: 0,
            maxX: (widget.dataPoints.length - 1).toDouble(),
            minY: _getMinY(),
            maxY: _getMaxY(),
            
            // Line configuration
            lineBarsData: [
              LineChartBarData(
                spots: _generateAnimatedSpots(),
                isCurved: true,
                curveSmoothness: 0.4,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isSelected = index == touchedIndex;
                    return FlDotCirclePainter(
                      radius: isSelected ? 8 : 6,
                      color: colorScheme.surface,
                      strokeWidth: isSelected ? 4 : 3,
                      strokeColor: colorScheme.primary,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            
            // Touch configuration
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (event, response) {
                setState(() {
                  if (response?.lineBarSpots != null && 
                      response!.lineBarSpots!.isNotEmpty) {
                    touchedIndex = response.lineBarSpots!.first.spotIndex;
                  } else {
                    touchedIndex = null;
                  }
                });
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colorScheme.inverseSurface,
                tooltipBorderRadius: BorderRadius.circular(16),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final point = widget.dataPoints[spot.spotIndex];
                    final gb = point.usedSpace / (1024 * 1024 * 1024);
                    return LineTooltipItem(
                      '${gb.toStringAsFixed(2)} GB\n${_formatDate(point.date)}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            
            borderData: FlBorderData(show: false),
          ),
        );
      },
    );
  }

  Widget _buildBottomLabel(int index, ThemeData theme, ColorScheme colorScheme) {
    if (index < 0 || index >= widget.dataPoints.length) {
      return const SizedBox.shrink();
    }

    String label = _getBottomLabelText(index);
    
    // For yearly view with many months, show selective labels
    if (widget.period.contains('Year')) {
      final totalMonths = widget.dataPoints.length;
      bool showLabel = false;
      
      // Always show first and last month
      if (index == 0 || index == totalMonths - 1) {
        showLabel = true;
      }
      // For 7+ months, show every 3rd month
      else if (totalMonths >= 7) {
        showLabel = index % 3 == 0;
      }
      // For 4-6 months, show every 2nd month
      else if (totalMonths >= 4) {
        showLabel = index % 2 == 0;
      }
      // For less than 4 months, show all
      else {
        showLabel = true;
      }
      
      if (!showLabel) {
        // Show just a dot for unshown labels
        return Container(
          height: 50,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      }
      
      return Container(
        height: 50,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: touchedIndex == index
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: touchedIndex == index
                    ? FontWeight.w700
                    : FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: touchedIndex == index
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }
    
    // For week and month views
    return Container(
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: touchedIndex == index
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          fontWeight: touchedIndex == index
              ? FontWeight.w700
              : FontWeight.w600,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLeftLabel(double value, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 65,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        '${value.toInt()} GB',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getBottomLabelText(int index) {
    final date = widget.dataPoints[index].date;
    
    if (widget.period.contains('Week')) {
      // Weekly Analysis: Show day names
      final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return shortDays[date.weekday - 1];
    } else if (widget.period.contains('Month')) {
      // Monthly Analysis: Show week labels
      return 'Week ${index + 1}';
    } else if (widget.period.contains('Year')) {
      // Annual Analysis: Show month abbreviations
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    }
    
    return '';
  }

  IconData _getPeriodIcon() {
    if (widget.period.contains('Week')) return Icons.view_week_rounded;
    if (widget.period.contains('Month')) return Icons.calendar_view_month_rounded;
    if (widget.period.contains('Year')) return Icons.calendar_today_rounded;
    return Icons.timeline;
  }

  String _getPeriodSubtitle() {
    if (widget.period.contains('Week')) return 'Storage usage by day (Mon-Sun)';
    if (widget.period.contains('Month')) return 'Storage usage by week (Week 1-4)';
    if (widget.period.contains('Year')) return 'Storage usage by month (Jan-Dec)';
    return 'Storage usage over time';
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    if (widget.period.contains('Week')) {
      return '${date.day} ${months[date.month - 1].substring(0, 3)}';
    } else if (widget.period.contains('Month')) {
      return '${date.day} ${months[date.month - 1].substring(0, 3)} ${date.year}';
    } else {
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  List<FlSpot> _generateAnimatedSpots() {
    return widget.dataPoints.asMap().entries.map((entry) {
      final gb = entry.value.usedSpace / (1024 * 1024 * 1024);
      // Apply animation to Y values
      final animatedY = gb * _animation.value;
      return FlSpot(entry.key.toDouble(), animatedY);
    }).toList();
  }

  double _getMinY() {
    if (widget.dataPoints.isEmpty) return 0;
    
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below
    return (min * 0.8).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (widget.dataPoints.isEmpty) return 100;
    
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above
    return (max * 1.2).clamp(10, double.infinity);
  }

  double _getHorizontalInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  double _getLeftInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }
}