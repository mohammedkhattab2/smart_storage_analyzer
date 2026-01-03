import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<PermissionResult> checkStoragePermission() async {
    PermissionStatus status;

    // For Android, we only need READ_EXTERNAL_STORAGE permission
    // MANAGE_EXTERNAL_STORAGE is restricted and not needed for our use case
    status = await Permission.storage.request();
    
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
          message: "Storage permission is needed to analyze your files",
        );
      case PermissionStatus.permanentlyDenied:
        return PermissionResult(
          isGranted: false,
          status: PermissionResultStatus.permanentlyDenied,
          message: "Please enable storage permission from settings",
        );
      default:
        return PermissionResult(
          isGranted: false,
          status: PermissionResultStatus.denied,
          message: "Storage permission is needed",
        );
    }
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

enum PermissionResultStatus {
  granted,
  denied,
  permanentlyDenied,
}
