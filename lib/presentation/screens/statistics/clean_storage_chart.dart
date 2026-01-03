import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class CleanStorageChart extends StatelessWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;

  const CleanStorageChart({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha:  0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  Text(
                    _getPeriodDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha:   0.3),
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
          const SizedBox(height: 16),
          
          // Chart
          Expanded(
            child: dataPoints.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha:  0.5),
                      ),
                    ),
                  )
                : LineChart(
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
                        
                        // X-axis
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              
                              // Strict validation - only show for exact integer indices
                              if (value != index.toDouble() || index < 0 || index >= dataPoints.length) {
                                return const SizedBox(height: 1, width: 1);
                              }
                              
                              // Get label based on period type
                              String label = '';
                              
                              if (period.contains('Week')) {
                                // Weekly: Show day abbreviations
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final dayIndex = dataPoints[index].date.weekday - 1;
                                if (dayIndex >= 0 && dayIndex < days.length) {
                                  label = days[dayIndex];
                                }
                              } else if (period.contains('Month')) {
                                // Monthly: Show week numbers
                                label = 'Week ${index + 1}';
                              } else if (period.contains('Year')) {
                                // Annual: Show month abbreviations
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                final monthIndex = dataPoints[index].date.month - 1;
                                if (monthIndex >= 0 && monthIndex < months.length) {
                                  label = months[monthIndex];
                                }
                              }
                              
                              // For yearly view, only show selected months to avoid crowding
                              if (period.contains('Year') && dataPoints.length > 6) {
                                // Show every other month for 7-12 months
                                if (index % 2 != 0 && index != dataPoints.length - 1) {
                                  return const SizedBox(height: 1, width: 1);
                                }
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Y-axis
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: _getYInterval(),
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()} GB',
                                  style: theme.textTheme.labelSmall?.copyWith(
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
                      
                      // Chart bounds
                      minX: 0,
                      maxX: (dataPoints.length - 1).toDouble(),
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                      
                      // Line data
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints.asMap().entries.map((entry) {
                            final gb = entry.value.usedSpace / (1024 * 1024 * 1024);
                            return FlSpot(entry.key.toDouble(), gb);
                          }).toList(),
                          isCurved: true,
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
                      
                      // Touch configuration
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => colorScheme.inverseSurface,
                          tooltipBorderRadius: BorderRadius.circular(8),
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final point = dataPoints[spot.spotIndex];
                              final gb = point.usedSpace / (1024 * 1024 * 1024);
                              return LineTooltipItem(
                                '${gb.toStringAsFixed(1)} GB',
                                TextStyle(
                                  color: colorScheme.onInverseSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  String _getPeriodDescription() {
    if (period.contains('Week')) {
      return 'Daily breakdown (Mon-Sun)';
    } else if (period.contains('Month')) {
      return 'Weekly breakdown (Week 1-4)';
    } else if (period.contains('Year')) {
      return 'Monthly breakdown (Jan-Dec)';
    }
    return 'Storage usage over time';
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