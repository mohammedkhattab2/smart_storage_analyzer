import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
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

class _StorageChartWidgetState extends State<StorageChartWidget>
    with SingleTickerProviderStateMixin {
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
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StorageChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Usage Trend',
              style: TextStyle(
                fontSize: AppSize.fontMedium,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSize.paddingMedium),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getGridInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.textSecondary.withOpacity(0.1),
                            strokeWidth: 1,
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
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
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
                              return Text(
                                '${value.toInt()} GB',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (widget.dataPoints.length - 1).toDouble(),
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateAnimatedSpots(_animation.value),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.primary,
                                strokeWidth: 2,
                                strokeColor: AppColors.cardBackground,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.primary.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => AppColors.cardBackground,
                          tooltipPadding: EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final spotIndex = touchedSpot.spotIndex;
                              final dataPoint = widget.dataPoints[spotIndex];
                              final date = dataPoint.date;
                              final usedGB =
                                  dataPoint.usedSpace / (1024 * 1024 * 1024);
                              return LineTooltipItem(
                                '${_getFullDate(date)}\n${usedGB.toStringAsFixed(1)} GB used',
                                TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinY() {
    if (widget.dataPoints.isEmpty) return 0;
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    return (values.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
  }

  double _getMaxY() {
    if (widget.dataPoints.isEmpty) return 100;
    final values = widget.dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    return (values.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();
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
        return widget.dataPoints.length > 15 ? 5 : 2;
      case 'This Year':
        return 1;
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
          'Dec'
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
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<FlSpot> _generateAnimatedSpots(double animationValue) {
    return widget.dataPoints.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;
      final usedGB = point.usedSpace / (1024 * 1024 * 1024);
      
      // Animate from bottom to actual position
      final animatedY = usedGB * animationValue;
      
      return FlSpot(index, animatedY);
    }).toList();
  }
}
