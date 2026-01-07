import 'dart:math' as math;
import 'dart:ui';

class ChartUtils {
  ChartUtils._();

  /// Calculate maximum Y value with margin
  static double calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;

    final max = values.reduce(math.max);
    return max * 1.2; // Add 20% margin for better visualization
  }

  /// Gradient colors for charts
  static List<Color> get chartGradientColors => [
    Color(0xFF2196F3),
    Color(0xFF2196F3).withValues(alpha: 0.3),
  ];

  /// Calculate percentage change between two values
  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Format storage value for chart display
  static String formatStorageValue(double bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double value = bytes;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
