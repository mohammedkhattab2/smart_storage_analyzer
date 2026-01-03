import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class SimpleStorageChart extends StatelessWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;

  const SimpleStorageChart({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Ensure we have valid data
    if (dataPoints.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha:  0.5),
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues (alpha:  0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Usage',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha:  0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LineChart(
                LineChartData(
                  // Grid
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getYInterval(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withValues(alpha:  0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  
                  // Titles
                  titlesData: FlTitlesData(
                    show: true,
                    
                    // Bottom titles - X axis
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 1, // Force interval to 1
                        getTitlesWidget: (double value, TitleMeta meta) {
                          // Convert to integer
                          final intValue = value.toInt();
                          
                          // Strict check: only process if value is exactly an integer
                          if ((value - intValue).abs() > 0.01) {
                            return const SizedBox();
                          }
                          
                          // Check bounds
                          if (intValue < 0 || intValue >= dataPoints.length) {
                            return const SizedBox();
                          }
                          
                          // For yearly view with many months, show selective labels
                          if (period.contains('Year') && dataPoints.length > 8) {
                            // Only show every 2nd month and the last month
                            if (intValue % 2 != 0 && intValue != dataPoints.length - 1) {
                              return const SizedBox();
                            }
                          }
                          
                          final label = _getXLabel(intValue);
                          
                          return Container(
                            height: 35,
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Left titles - Y axis
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        interval: _getYInterval(),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()} GB',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          );
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
                  
                  // Bounds - use exact values
                  minX: 0,
                  maxX: (dataPoints.length - 1).toDouble(),
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                  
                  // Line
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        dataPoints.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          dataPoints[index].usedSpace / (1024 * 1024 * 1024),
                        ),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colorScheme.surface,
                            strokeWidth: 2,
                            strokeColor: colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha:  0.1),
                      ),
                    ),
                  ],
                  
                  // Touch
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.inverseSurface,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          final gb = flSpot.y;
                          return LineTooltipItem(
                            '${gb.toStringAsFixed(1)} GB',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDescription() {
    if (period.contains('Week')) {
      return 'Daily storage usage (Mon-Sun)';
    } else if (period.contains('Month')) {
      return 'Weekly storage usage (Week 1-4)';
    } else if (period.contains('Year')) {
      return 'Monthly storage usage (Jan-Dec)';
    }
    return 'Storage usage over time';
  }
  
  String _getXLabel(int index) {
    if (period.contains('Week')) {
      // Weekly: Day abbreviations
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekday = dataPoints[index].date.weekday - 1;
      return weekday >= 0 && weekday < days.length ? days[weekday] : '';
    } else if (period.contains('Month')) {
      // Monthly: Week labels
      return 'Week ${index + 1}';
    } else if (period.contains('Year')) {
      // Annual: Month abbreviations
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = dataPoints[index].date.month - 1;
      return month >= 0 && month < months.length ? months[month] : '';
    }
    return '';
  }
  
  double _getMinY() {
    if (dataPoints.isEmpty) return 0;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min * 0.8).clamp(0, double.infinity);
  }
  
  double _getMaxY() {
    if (dataPoints.isEmpty) return 100;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).clamp(10, double.infinity);
  }
  
  double _getYInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }
}