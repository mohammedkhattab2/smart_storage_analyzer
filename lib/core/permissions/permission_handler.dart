import 'package:permission_handler/permission_handler.dart';

/// Permission handler for Smart Storage Analyzer
///
/// IMPORTANT: Google Play Photo and Video Permissions Policy Compliance
/// This app does NOT request:
/// - READ_MEDIA_IMAGES
/// - READ_MEDIA_VIDEO
/// - READ_MEDIA_AUDIO
/// - READ_EXTERNAL_STORAGE
/// - WRITE_EXTERNAL_STORAGE
///
/// Instead, we use PACKAGE_USAGE_STATS for storage analysis.
/// The Permission.storage request has been removed to comply with policy.
class PermissionHandler {
  /// Check notification permission (the only permission we request via permission_handler)
  static Future<PermissionResult> checkNotificationPermission() async {
    PermissionStatus status;

    // Only request notification permission - storage analysis uses PACKAGE_USAGE_STATS
    // which is handled via native channel, not permission_handler
    status = await Permission.notification.request();

    switch (status) {
      case PermissionStatus.granted:
        return PermissionResult(
          isGranted: true,
          status: PermissionResultStatus.granted,
        );
      case PermissionStatus.denied:
        return PermissionResult(
          isGranted: false,
          status: PermissionResultStatus.denied,
          message: "Notification permission is needed for storage alerts",
        );
      case PermissionStatus.permanentlyDenied:
        return PermissionResult(
          isGranted: false,
          status: PermissionResultStatus.permanentlyDenied,
          message: "Please enable notification permission from settings",
        );
      default:
        return PermissionResult(
          isGranted: false,
          status: PermissionResultStatus.denied,
          message: "Notification permission is needed",
        );
    }
  }
  
  /// Legacy method - now returns granted since we don't need storage permission
  /// Storage analysis uses PACKAGE_USAGE_STATS via native channel
  @Deprecated('Use PermissionService.checkUsageStatsPermission() instead')
  static Future<PermissionResult> checkStoragePermission() async {
    // We no longer request storage permission to comply with Google Play policy
    // Storage analysis is done via PACKAGE_USAGE_STATS permission
    return PermissionResult(
      isGranted: true,
      status: PermissionResultStatus.granted,
      message: "Storage analysis uses Usage Stats permission (handled separately)",
    );
  }
}

class PermissionResult {
  final bool isGranted;
  final PermissionResultStatus status;
  final String? message;

  PermissionResult({
    required this.isGranted,
    required this.status,
    this.message,
  });
}

enum PermissionResultStatus { granted, denied, permanentlyDenied }
