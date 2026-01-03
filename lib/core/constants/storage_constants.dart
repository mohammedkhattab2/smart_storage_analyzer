class StorageConstants {
  StorageConstants._();

  // Real threshold values for file categorization
  static const int largeSizeThreshold = 100 * 1024 * 1024; // 100 MB
  static const int oldFileThresholdDays = 90; // 3 months

  // Cache duration for storage data
  static const Duration storageCacheDuration = Duration(seconds: 30);

  // Minimum free space warning threshold (5%)
  static const double minFreeSpacePercentage = 0.05;
}
