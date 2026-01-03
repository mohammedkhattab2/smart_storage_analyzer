class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'Smart Storage Analyzer';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Features Flags
  static const bool enableAnalytics = false;
  static const bool enableAds = false;
  static const bool enableCloudSync = false;

  // Debug
  static const bool enableLogging = true;
  static const bool showDebugBanner = false;
}
