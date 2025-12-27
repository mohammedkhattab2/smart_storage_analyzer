import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> checkStoragePermission(BuildContext context) async {
    PermissionStatus status;

    // android 13
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Storage permission is needed to analyze your files"),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      case PermissionStatus.permanentlyDenied:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Permission Required"),
            content: Text('Please enable storage permission from settings'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
        return false;
      default:
        return false;
    }
  }
}
