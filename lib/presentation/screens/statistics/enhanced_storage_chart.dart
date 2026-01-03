import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class EnhancedStorageChart extends StatefulWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;

  const EnhancedStorageChart({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  State<EnhancedStorageChart> createState() => _EnhancedStorageChartState();
}

class _EnhancedStorageChartState extends State<EnhancedStorageChart> 
    with SingleTickerProviderStateMixin {
  int? touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuart,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: isSmallScreen ? 320 : 380,
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: _buildContainerDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Expanded(
                    child: widget.dataPoints.isEmpty
                        ? _buildEmptyState(context)
                        : _buildChart(context, isSmallScreen),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues( alpha: .08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: colorScheme.outline.withValues(alpha: .1),
        width: 1,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Storage Usage',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getPeriodDescription(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getPeriodLabel(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: .3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha:  0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Storage data will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha:  0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return LineChart(
      LineChartData(
        // Grid configuration
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateYInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues (alpha:  0.1),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        
        // Titles configuration
        titlesData: FlTitlesData(
          show: true,
          
          // Bottom titles (X-axis)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dataPoints.length || index != value) {
                  return const SizedBox.shrink();
                }
                return _buildBottomTitle(index, theme, isSmallScreen);
              },
            ),
          ),
          
          // Left titles (Y-axis)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isSmallScreen ? 50 : 60,
              interval: _calculateYInterval(),
              getTitlesWidget: (value, meta) => _buildLeftTitle(
                value, 
                theme,
                isSmallScreen,
              ),
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
        minY: _calculateMinY(),
        maxY: _calculateMaxY(),
        
        // Line configuration
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            
            // Dots configuration
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isTouch = index == touchedIndex;
                return FlDotCirclePainter(
                  radius: isTouch ? 6 : 4,
                  color: colorScheme.surface,
                  strokeWidth: isTouch ? 3 : 2,
                  strokeColor: colorScheme.primary,
                );
              },
            ),
            
            // Area under line
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha:  0.1),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha:  0.2),
                  colorScheme.primary.withValues(alpha:  0.0),
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
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (mounted) {
              setState(() {
                if (response?.lineBarSpots != null && 
                    response!.lineBarSpots!.isNotEmpty &&
                    event is! FlPanEndEvent &&
                    event is! FlLongPressEnd) {
                  touchedIndex = response.lineBarSpots!.first.spotIndex;
                } else {
                  touchedIndex = null;
                }
              });
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final point = widget.dataPoints[spot.spotIndex];
                final gb = point.usedSpace / (1024 * 1024 * 1024);
                final date = _formatTooltipDate(point.date);
                return LineTooltipItem(
                  '${gb.toStringAsFixed(1)} GB\n$date',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        
        borderData: FlBorderData(show: false),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildBottomTitle(int index, ThemeData theme, bool isSmallScreen) {
    final label = _getXAxisLabel(index);
    final total = widget.dataPoints.length;
    
    // Smart label display based on total points and period
    bool shouldShow = true;
    
    if (widget.period.contains('Week') && total > 4) {
      // For weekly: show every other day
      shouldShow = index % 2 == 0;
    } else if (widget.period.contains('Month')) {
      // For monthly: always show all 4 weeks
      shouldShow = true;
    } else if (widget.period.contains('Year')) {
      // For yearly: show every 2 or 3 months
      if (total > 6) {
        shouldShow = index == 0 || index == total - 1 || index % 2 == 1;
      } else {
        shouldShow = true;
      }
    }
    
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 50,
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildLeftTitle(double value, ThemeData theme, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '${value.toInt()} GB',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 11 : 12,
        ),
      ),
    );
  }

  String _getXAxisLabel(int index) {
    final date = widget.dataPoints[index].date;
    
    if (widget.period.contains('Week')) {
      // Weekly: Day abbreviations
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else if (widget.period.contains('Month')) {
      // Monthly: Week labels
      return 'Week ${index + 1}';
    } else if (widget.period.contains('Year')) {
      // Annual: Month abbreviations
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    }
    
    return '';
  }


  String _getPeriodLabel() {
    if (widget.period.contains('Week')) return 'Weekly';
    if (widget.period.contains('Month')) return 'Monthly';
    if (widget.period.contains('Year')) return 'Annual';
    return 'Overview';
  }

  String _getPeriodDescription() {
    if (widget.period.contains('Week')) {
      return 'Storage usage by day (Mon-Sun)';
    } else if (widget.period.contains('Month')) {
      return 'Storage usage by week (Week 1-4)';
    } else if (widget.period.contains('Year')) {
      return 'Storage usage by month (Jan-Dec)';
    }
    return 'Storage usage over time';
  }

  String _formatTooltipDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (widget.period.contains('Week')) {
      return '${date.day} ${months[date.month - 1]}';
    } else if (widget.period.contains('Month')) {
      return '${date.day} ${months[date.month - 1]}';
    } else {
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  List<FlSpot> _generateSpots() {
    return widget.dataPoints.asMap().entries.map((entry) {
      final gb = entry.value.usedSpace / (1024 * 1024 * 1024);
      final animatedY = gb * _animation.value;
      return FlSpot(entry.key.toDouble(), animatedY);
    }).toList();
  }

  double _calculateMinY() {
    if (widget.dataPoints.isEmpty) return 0;
    
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    return (min * 0.8).clamp(0, double.infinity);
  }

  double _calculateMaxY() {
    if (widget.dataPoints.isEmpty) return 100;
    
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    return (max * 1.2).clamp(10, double.infinity);
  }

  double _calculateYInterval() {
    final range = _calculateMaxY() - _calculateMinY();
    
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 50;
    
    return 100;
  }

}