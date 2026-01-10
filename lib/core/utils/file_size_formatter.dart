import 'dart:math' as math;

/// Utility class for formatting file sizes in human-readable format
class FileSizeFormatter {
  /// Format file size in bytes to human-readable format
  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const base = 1024;
    
    int digitGroups = (bytes > 0) ? (math.log(bytes) / math.log(base)).floor() : 0;
    
    if (digitGroups >= units.length) {
      digitGroups = units.length - 1;
    }
    
    double size = bytes / math.pow(base, digitGroups);
    
    // Format with appropriate decimal places
    String formattedSize;
    if (digitGroups == 0) {
      // Bytes - no decimal places
      formattedSize = size.toStringAsFixed(0);
    } else if (size >= 100) {
      // Large numbers - no decimal places
      formattedSize = size.toStringAsFixed(0);
    } else if (size >= 10) {
      // Medium numbers - 1 decimal place
      formattedSize = size.toStringAsFixed(1);
    } else {
      // Small numbers - 2 decimal places
      formattedSize = size.toStringAsFixed(2);
    }
    
    return '$formattedSize ${units[digitGroups]}';
  }
  
  /// Format file size with more detail
  static String formatSizeDetailed(int bytes) {
    if (bytes <= 0) return '0 bytes';
    
    const units = ['bytes', 'KB', 'MB', 'GB', 'TB'];
    const base = 1024;
    
    int digitGroups = (bytes > 0) ? (math.log(bytes) / math.log(base)).floor() : 0;
    
    if (digitGroups >= units.length) {
      digitGroups = units.length - 1;
    }
    
    double size = bytes / math.pow(base, digitGroups);
    
    String formattedSize = size.toStringAsFixed(2);
    
    // Remove unnecessary trailing zeros
    if (formattedSize.contains('.')) {
      formattedSize = formattedSize.replaceAll(RegExp(r'\.?0+$'), '');
    }
    
    return '$formattedSize ${units[digitGroups]}';
  }
  
  /// Parse human-readable file size to bytes
  static int parseSize(String sizeString) {
    // Remove extra spaces and convert to uppercase
    String normalized = sizeString.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
    
    // Extract number and unit
    final match = RegExp(r'^([\d.]+)\s*([KMGT]?B)?$').firstMatch(normalized);
    
    if (match == null) {
      throw FormatException('Invalid size format: $sizeString');
    }
    
    double value = double.parse(match.group(1)!);
    String? unit = match.group(2);
    
    const multipliers = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024,
    };
    
    int multiplier = multipliers[unit] ?? 1;
    
    return (value * multiplier).round();
  }
  
  /// Get percentage of used space
  static double getUsagePercentage(int used, int total) {
    if (total <= 0) return 0.0;
    return (used / total) * 100;
  }
  
  /// Format percentage
  static String formatPercentage(double percentage) {
    if (percentage < 1) {
      return '${percentage.toStringAsFixed(2)}%';
    } else if (percentage < 10) {
      return '${percentage.toStringAsFixed(1)}%';
    } else {
      return '${percentage.toStringAsFixed(0)}%';
    }
  }
}