import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service to handle permission requests
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check and request storage permissions with settings navigation
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13 (API 33) and above - use granular media permissions
      if (sdkInt >= 33) {
        // Check granular permissions for Android 13+
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        // Check if all permissions are granted
        final statuses = await Future.wait(
          permissions.map((permission) => permission.status),
        );

        if (statuses.every((status) => status.isGranted)) {
          return true;
        }

        // Check if any permission is permanently denied
        if (statuses.any((status) => status.isPermanentlyDenied)) {
          if (context != null && context.mounted) {
            final shouldOpenSettings = await _showPermissionDialog(
              context,
              title: 'Media Access Required',
              content:
                  'Smart Storage Analyzer needs access to your media files to:\n\n'
                  '• Analyze storage usage of photos, videos, and audio\n'
                  '• Identify large files taking up space\n'
                  '• Find duplicate files\n'
                  '• Help you free up storage space\n\n'
                  'Your files remain private and are never uploaded or shared.\n\n'
                  'Would you like to grant these permissions in settings?',
            );

            if (shouldOpenSettings) {
              await openAppSettings();
            }
          }
          return false;
        }

        // Request permissions if not granted
        final results = await Future.wait(
          permissions.map((permission) => permission.request()),
        );

        return results.every((status) => status.isGranted);
      }
      // Android 11 and 12 - use same approach as Android 13
      else if (sdkInt >= 30) {
        // For Android 11-12, we'll use the standard storage permission
        // combined with MediaStore APIs for file access
        final storageStatus = await Permission.storage.status;
        
        if (storageStatus.isGranted) {
          return true;
        }

        if (storageStatus.isPermanentlyDenied) {
          if (context != null && context.mounted) {
            final shouldOpenSettings = await _showPermissionDialog(
              context,
              title: 'Storage Access Required',
              content:
                  'Smart Storage Analyzer needs storage access to:\n\n'
                  '• Analyze your device storage usage\n'
                  '• Identify files that can be cleaned up\n'
                  '• Show storage breakdown by file type\n'
                  '• Help optimize your device storage\n\n'
                  'We use standard Android storage permissions.\n'
                  'Your data privacy is protected.\n\n'
                  'Would you like to grant this permission in settings?',
            );

            if (shouldOpenSettings) {
              await openAppSettings();
            }
          }
          return false;
        }

        // Request storage permission
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      // Android 10 and below
      else {
        final status = await Permission.storage.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isPermanentlyDenied) {
          if (context != null && context.mounted) {
            final shouldOpenSettings = await _showPermissionDialog(
              context,
              title: 'Storage Permission Required',
              content:
                  'Smart Storage Analyzer needs storage permission to:\n\n'
                  '• Analyze your device storage\n'
                  '• Show which files are using the most space\n'
                  '• Identify files you may want to clean up\n'
                  '• Help optimize storage usage\n\n'
                  'We only access files to analyze storage usage.\n'
                  'Your privacy is protected.\n\n'
                  'Would you like to grant this permission in settings?',
            );

            if (shouldOpenSettings) {
              await openAppSettings();
            }
          }
          return false;
        }

        // Request permission
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    } catch (e) {
      Logger.error('Error requesting storage permission', e);
      return false;
    }
  }

  /// Check if device is running specific Android version or above
  Future<int> getAndroidSdkInt() async {
    if (!Platform.isAndroid) return 0;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      Logger.error('Error getting Android SDK version', e);
      return 0;
    }
  }

  /// Show permission dialog with explanation and settings navigation
  Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll be redirected to app settings',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Legacy method for backward compatibility
  Future<bool> showPermissionDialog(BuildContext context) async {
    final sdkInt = await getAndroidSdkInt();
    final isAndroid13Plus = sdkInt >= 33;

    if (!context.mounted) return false;

    return await _showPermissionDialog(
      context,
      title: isAndroid13Plus
          ? 'Media Access Required'
          : 'Storage Permission Required',
      content: isAndroid13Plus
          ? 'This app needs access to your media files to:\n\n'
                '• Scan and analyze your photos, videos, and audio files\n'
                '• Show storage usage by file type\n'
                '• Help you free up space\n\n'
                'Your data privacy is our priority. We never upload or share your files.'
          : 'This app needs storage permission to:\n\n'
                '• Scan and analyze your files\n'
                '• Show storage usage\n'
                '• Help you free up space\n\n'
                'Your data privacy is our priority. We never upload or share your files.',
    );
  }

  /// Check if we have necessary permissions
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13+ - check granular permissions
      if (sdkInt >= 33) {
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        final statuses = await Future.wait(
          permissions.map((permission) => permission.status),
        );

        return statuses.every((status) => status.isGranted);
      }
      // Android 11 and above - use standard storage permission
      else if (sdkInt >= 30) {
        final storageStatus = await Permission.storage.status;
        return storageStatus.isGranted;
      }
      // Android 10 and below - check storage permission
      else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } catch (e) {
      Logger.error('Error checking storage permission', e);
      return false;
    }
  }
}
