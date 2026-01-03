import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service to handle permission requests
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check and request storage permissions
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 11 (API 30) and above
      if (await _isAndroid11OrAbove()) {
        // Check if we have manage external storage permission
        final status = await Permission.manageExternalStorage.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          final result = await Permission.manageExternalStorage.request();
          return result.isGranted;
        }

        // If permanently denied, show settings
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      } else {
        // For Android 10 and below
        final status = await Permission.storage.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }

        // If permanently denied, show settings
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }

      return false;
    } catch (e) {
      Logger.error('Error requesting storage permission', e);
      return false;
    }
  }

  /// Check if device is Android 11 or above
  Future<bool> _isAndroid11OrAbove() async {
    if (!Platform.isAndroid) return false;

    // Android SDK 30 = Android 11
    return Platform.operatingSystemVersion.contains('SDK 30') ||
        Platform.operatingSystemVersion.contains('SDK 31') ||
        Platform.operatingSystemVersion.contains('SDK 32') ||
        Platform.operatingSystemVersion.contains('SDK 33') ||
        Platform.operatingSystemVersion.contains('SDK 34');
  }

  /// Show permission dialog with explanation
  Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Text(
                'This app needs storage permission to:\n\n'
                '• Scan and analyze your files\n'
                '• Show storage usage\n'
                '• Help you free up space\n\n'
                'Your data privacy is our priority. We never upload or share your files.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Deny'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Allow'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Check if we have necessary permissions
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await _isAndroid11OrAbove()) {
        final status = await Permission.manageExternalStorage.status;
        return status.isGranted;
      } else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } catch (e) {
      Logger.error('Error checking storage permission', e);
      return false;
    }
  }
}
