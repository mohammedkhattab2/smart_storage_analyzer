import 'package:equatable/equatable.dart';

/// Domain entity representing an installed application with usage metadata.
///
/// Pure Dart (no Flutter imports) to keep the domain layer framework-agnostic.
class UnusedApp extends Equatable {
  final String packageName;
  final String appName;
  /// Last time the app was used, as reported by the platform layer.
  final DateTime lastUsed;
  /// Total app size in bytes (APK + data + cache where available).
  final int appSizeBytes;
  /// Optional flag indicating if this is a system app.
  final bool isSystemApp;

  const UnusedApp({
    required this.packageName,
    required this.appName,
    required this.lastUsed,
    required this.appSizeBytes,
    this.isSystemApp = false,
  });

  @override
  List<Object?> get props => [
        packageName,
        appName,
        lastUsed,
        appSizeBytes,
        isSystemApp,
      ];
}