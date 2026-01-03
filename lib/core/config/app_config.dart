class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'Smart Storage Analyzer';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // API (للمستقبل)
  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Analytics (للمستقبل)
  static const bool enableAnalytics = true;
  static const String analyticsKey = 'YOUR_ANALYTICS_KEY';

  // Features Flags
  static const bool enablePremium = false; // سنفعلها لاحقاً
  static const bool enableAds = false; // سنفعلها لاحقاً
  static const bool enableCloudSync = false;

  // Debug
  static const bool enableLogging = true;
  static const bool showDebugBanner = false;
}
