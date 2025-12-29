import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class StorageChartWidget extends StatelessWidget {
  final List<StorageDataPoint> dataPoints;
  final String period;
  const StorageChartWidget({
    super.key,
    required this.dataPoints,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(AppSize.paddingMedium),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < dataPoints.length) {
                      return Text(
                        _getBottomTitle(value.toInt()),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (dataPoints.length - 1).toDouble(),
            minY: _getMinY(),
            maxY: _getMaxY(),
            lineBarsData: [
              LineChartBarData(
                spots: _generateSpots(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.0),
                    ]
                    )
                ) 
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMinY() {
    if (dataPoints.isEmpty) return 0;
    final values = dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    return values.reduce((a, b) => a < b ? a : b) * 0.9;
  }

  double _getMaxY() {
    if (dataPoints.isEmpty) return 128;
    final values = dataPoints
        .map((p) => p.usedSpace / (1024 * 1024 * 1024))
        .toList();
    return values.reduce((a, b) => a > b ? a : b) * 1.1;
  }

  String _getBottomTitle(int index) {
    final data = dataPoints[index].date;
    switch (period) {
      case 'This Week':
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[data.weekday - 1].substring(0, 1);
      case 'This Month':
        return '${data.day}';
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
        return months[data.month - 1].substring(0, 3);
      default:
        return '';
    }
  }

  List<FlSpot> _generateSpots() {
    return dataPoints.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;
      final usedGB = point.usedSpace / (1024 * 1024 * 1024);
      return FlSpot(index, usedGB);
    }).toList();
  }
}
