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

    // حساب X-axis indices الذكية
    List<int> getSmartXLabels() {
      final total = dataPoints.length;
      if (total <= 7) return List.generate(total, (i) => i);

      int count = total <= 30 ? 7 : 10;
      double step = (total - 1) / (count - 1);
      return List.generate(count, (i) => (i * step).round());
    }

    final smartXLabels = getSmartXLabels();

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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getYInterval(),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colorScheme.outline.withValues(alpha:  0.1),
                          strokeWidth: 1,
                        ),
                      ),

                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (!smartXLabels.contains(index)) return const SizedBox.shrink();

                              String label = '';
                              if (period.contains('Week')) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final dayIndex = dataPoints[index].date.weekday - 1;
                                if (dayIndex >= 0 && dayIndex < days.length) label = days[dayIndex];
                              } else if (period.contains('Month')) {
                                label = 'Week ${index + 1}';
                              } else if (period.contains('Year')) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                final monthIndex = dataPoints[index].date.month - 1;
                                if (monthIndex >= 0 && monthIndex < months.length) label = months[monthIndex];
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    label,
                                    style: theme.textTheme.labelSmall?.copyWith(
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
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
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),

                      minX: 0,
                      maxX: (dataPoints.length - 1).toDouble(),
                      minY: _getMinY(),
                      maxY: _getMaxY(),

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
    if (period.contains('Week')) return 'Daily breakdown (Mon-Sun)';
    if (period.contains('Month')) return 'Weekly breakdown (Week 1-4)';
    if (period.contains('Year')) return 'Monthly breakdown (Jan-Dec)';
    return 'Storage usage over time';
  }

  double _getMinY() {
    if (dataPoints.isEmpty) return 0;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min * 0.7).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (dataPoints.isEmpty) return 100;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.3).clamp(10, double.infinity);
  }

  double _getYInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }
}
