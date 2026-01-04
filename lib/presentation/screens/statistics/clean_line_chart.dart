import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class CleanLineChart extends StatelessWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;

  const CleanLineChart({
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
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: dataPoints.isEmpty
          ? _buildEmptyState(theme, colorScheme)
          : _buildChart(theme, colorScheme),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Text(
        'No data available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme, ColorScheme colorScheme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getYInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
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
              getTitlesWidget: (value, meta) => _buildXAxisLabel(value, theme, colorScheme),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _getYInterval(),
              getTitlesWidget: (value, meta) => _buildYAxisLabel(value, theme),
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
            spots: _generateSpots(),
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final point = dataPoints[spot.spotIndex];
                final gb = point.usedSpace / (1024 * 1024 * 1024);
                final date = _formatTooltipDate(point.date);
                return LineTooltipItem(
                  '$date\n${gb.toStringAsFixed(2)} GB',
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
    );
  }

  Widget _buildXAxisLabel(double value, ThemeData theme, ColorScheme colorScheme) {
    final index = value.toInt();
    
    // Determine which indices should have labels
    final labelIndices = _getLabelIndices();
    if (!labelIndices.contains(index)) {
      return const SizedBox.shrink();
    }

    String label = _getXLabel(index);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RotatedBox(
        quarterTurns: period.contains('Year') ? 1 : 0, // Rotate only for yearly view
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
  }

  Widget _buildYAxisLabel(double value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '${value.toInt()} GB',
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 11,
        ),
      ),
    );
  }

  List<int> _getLabelIndices() {
    final List<int> indices = [];
    
    if (period.contains('Week')) {
      // For weekly view, show exactly 7 labels distributed evenly
      final step = dataPoints.length > 7 ? dataPoints.length / 7 : 1;
      for (int i = 0; i < 7 && i * step < dataPoints.length; i++) {
        indices.add((i * step).round());
      }
    } else if (period.contains('Month')) {
      // For monthly view, show exactly 4 labels distributed evenly
      final step = dataPoints.length / 4;
      for (int i = 0; i < 4; i++) {
        final index = (i * step).round();
        if (index < dataPoints.length) indices.add(index);
      }
    } else if (period.contains('Year')) {
      // For yearly view, show one label per unique month
      final Map<int, int> monthIndices = {};
      for (int i = 0; i < dataPoints.length; i++) {
        final month = dataPoints[i].date.month;
        if (!monthIndices.containsKey(month)) {
          monthIndices[month] = i;
        }
      }
      indices.addAll(monthIndices.values);
      indices.sort();
    }
    
    return indices;
  }

  String _getXLabel(int index) {
    if (index >= dataPoints.length) return '';
    
    if (period.contains('Week')) {
      const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayIndex = dataPoints[index].date.weekday - 1;
      return dayIndex >= 0 && dayIndex < weekDays.length ? weekDays[dayIndex] : '';
    } else if (period.contains('Month')) {
      // Calculate which week this index represents
      final weekNumber = ((index / (dataPoints.length / 4)) + 1).floor();
      return 'Week ${weekNumber.clamp(1, 4)}';
    } else if (period.contains('Year')) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthIndex = dataPoints[index].date.month - 1;
      return monthIndex >= 0 && monthIndex < months.length ? months[monthIndex] : '';
    }
    
    return '';
  }

  String _formatTooltipDate(DateTime date) {
    if (period.contains('Week')) {
      const weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekDays[date.weekday - 1];
    } else if (period.contains('Month')) {
      return '${date.day}/${date.month}';
    } else if (period.contains('Year')) {
      const months = ['January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
      return months[date.month - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  List<FlSpot> _generateSpots() {
    return dataPoints.asMap().entries.map((entry) {
      final gb = entry.value.usedSpace / (1024 * 1024 * 1024);
      return FlSpot(entry.key.toDouble(), gb);
    }).toList();
  }

  double _getMinY() {
    if (dataPoints.isEmpty) return 0;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    // Start at 80% of minimum or 0, whichever is higher
    return (min * 0.8).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (dataPoints.isEmpty) return 100;
    final values = dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    // Add 20% padding to the maximum
    return (max * 1.2).clamp(10, double.infinity);
  }

  double _getYInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }
}