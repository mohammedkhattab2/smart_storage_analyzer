import 'dart:math' as math;

class SizeFormatter {
  // change bytes to KB, MB, GB, TB
  static String formateBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return "0 Bytes";
    const k = 1024;
    final sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(k)).floor();
    final size = bytes / math.pow(k, i);
    return '${size.toStringAsFixed(decimals)} ${sizes[i]}';

  }
}
