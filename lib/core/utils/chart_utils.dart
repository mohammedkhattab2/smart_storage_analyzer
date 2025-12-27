import 'dart:math' as math;
import 'dart:ui';

class ChartUtils {
  ChartUtils._();
  
  
  static List<double> generateMockData(int count) {
    final random = math.Random();
    return List.generate(count, (index) {
      return 50 + random.nextDouble() * 100;
    });
  }
  
  /// حساب أقصى قيمة مع margin
  static double calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    
    final max = values.reduce(math.max);
    return max * 1.2; // إضافة 20% margin
  }
  
  /// ألوان الـ Gradient للـ Chart
  static List<Color> get chartGradientColors => [
    Color(0xFF2196F3),
    Color(0xFF2196F3).withValues(alpha:  0.3),
  ];
}