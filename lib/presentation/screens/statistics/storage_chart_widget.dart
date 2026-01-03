import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class StorageChartWidget extends StatefulWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;
  const StorageChartWidget({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  State<StorageChartWidget> createState() => _StorageChartWidgetState();
}

class _StorageChartWidgetState extends State<StorageChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 340,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Storage Usage Trend',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Track your storage patterns',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.show_chart_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.paddingMedium),

                    // Chart
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => HapticFeedback.lightImpact(),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: _getGridInterval(),
                              verticalInterval: _getBottomTitleInterval(),
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: colorScheme.outlineVariant.withValues(alpha: .2),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: colorScheme.outlineVariant.withValues(alpha: .1),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: _getBottomTitleInterval(),
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < widget.dataPoints.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _getBottomTitle(value.toInt()),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval: _getLeftTitleInterval(),
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${value.toInt()} GB',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
                                          fontWeight: FontWeight.w500,
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
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (widget.dataPoints.length - 1).toDouble(),
                            minY: _getMinY(),
                            maxY: _getMaxY(),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateSpots(),
                                isCurved: true,
                                color: colorScheme.primary,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 5,
                                      color: colorScheme.surface,
                                      strokeWidth: 2.5,
                                      strokeColor: colorScheme.primary,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: colorScheme.primary.withValues(alpha: .1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,
                              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      touchResponse == null ||
                                      touchResponse.lineBarSpots == null ||
                                      touchResponse.lineBarSpots!.isEmpty) {
                                    touchedIndex = null;
                                    return;
                                  }
                                  touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                                });
                              },
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => isDark
                                    ? colorScheme.surfaceContainerHigh
                                    : colorScheme.surfaceContainerHighest,
                                tooltipBorderRadius: BorderRadius.circular(12),
                                tooltipBorder: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: .2),
                                  width: 1,
                                ),
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                tooltipMargin: 8,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final spotIndex = touchedSpot.spotIndex;
                                    final dataPoint = widget.dataPoints[spotIndex];
                                    final date = dataPoint.date;
                                    final usedGB = dataPoint.usedSpace / (1024 * 1024 * 1024);
                                    return LineTooltipItem(
                                      '${_getFullDate(date)}\n${usedGB.toStringAsFixed(1)} GB used',
                                      TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            );
  }

  double _getMinY() {
    if (widget.dataPoints.isEmpty) return 0;
    final values =
        widget.dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    // If all values are similar, create a reasonable range
    if (_getMaxY() - minValue < 1) {
      return (minValue - 5).clamp(0, double.infinity).toDouble();
    }
    return (minValue * 0.8).clamp(0, double.infinity).floorToDouble();
  }

  double _getMaxY() {
    if (widget.dataPoints.isEmpty) return 100;
    final values =
        widget.dataPoints.map((p) => p.usedSpace / (1024 * 1024 * 1024)).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // If all values are similar, create a reasonable range
    final minValue = values.reduce((a, b) => a < b ? a : b);
    if (maxValue - minValue < 1) {
      return maxValue + 5;
    }
    return (maxValue * 1.2).ceilToDouble();
  }

  double _getGridInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }

  double _getLeftTitleInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }

  double _getBottomTitleInterval() {
    switch (widget.period) {
      case 'This Week':
        return 1;
      case 'This Month':
        if (widget.dataPoints.length > 20) return 5;
        if (widget.dataPoints.length > 10) return 3;
        return 1;
      case 'This Year':
        return widget.dataPoints.length > 6 ? 2 : 1;
      default:
        return 1;
    }
  }

  String _getBottomTitle(int index) {
    final date = widget.dataPoints[index].date;
    switch (widget.period) {
      case 'This Week':
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case 'This Month':
        return '${date.day}';
      case 'This Year':
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[date.month - 1];
      default:
        return '';
    }
  }

  String _getFullDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<FlSpot> _generateSpots() {
    return widget.dataPoints.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;
      final usedGB = point.usedSpace / (1024 * 1024 * 1024);
      return FlSpot(index, usedGB);
    }).toList();
  }
}
