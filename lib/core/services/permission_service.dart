import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

import 'package:permission_handler/permission_handler.dart';

/// Service to handle permission requests
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const MethodChannel _channel = MethodChannel('com.smarttools.storageanalyzer/native');

  /// Check and request storage and media permissions
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;

    try {
      final sdkInt = await getAndroidSdkInt();
      if (sdkInt >= 33) {
        // Android 13+ (API 33+)
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        
        final hasMediaAccess = statuses.values.any((status) => status.isGranted || status.isLimited);
        if (!hasMediaAccess && context != null && context.mounted) {
          final shouldOpenSettings = await showPermissionDialog(context);
          if (shouldOpenSettings) {
            await openAppSettings();
          }
        }
      } else {
        // Android 12 and below
        final status = await Permission.storage.request();
        if (!status.isGranted && context != null && context.mounted) {
          final shouldOpenSettings = await showPermissionDialog(context);
          if (shouldOpenSettings) {
            await openAppSettings();
          }
        }
      }

      return true;
    } catch (e) {
      Logger.error('Error requesting storage permission', e);
      return true;
    }
  }
  
  /// Check if usage stats permission is granted
  Future<bool> checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsagePermission');
      return result ?? false;
    } catch (e) {
      Logger.error('Error checking usage stats permission', e);
      return false;
    }
  }
  
  /// Request usage stats permission (opens system settings)
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {
      Logger.error('Error requesting usage stats permission', e);
    }
  }

  /// Check if app has All Files Access (Android 11+)
  Future<bool> hasManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('hasManageStoragePermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request All Files Access (opens Settings page for Android 11+)
  Future<bool> requestManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('requestManageStoragePermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Explicit API used by presentation layer when the unused apps screen
  /// detects that Usage Access is required. This invokes the dedicated
  /// MethodChannel handler that opens Settings.ACTION_USAGE_ACCESS_SETTINGS.
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      Logger.error('Error opening usage access settings', e);
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
      final sdkInt = await getAndroidSdkInt();
      if (sdkInt >= 33) {
        final photos = await Permission.photos.isGranted;
        final videos = await Permission.videos.isGranted;
        final audio = await Permission.audio.isGranted;
        if (photos || videos || audio) return true;
      } else {
        final storage = await Permission.storage.isGranted;
        if (storage) return true;
      }
      return true; // Return true so scan proceeds with whatever is accessible
    } catch (e) {
      Logger.error('Error checking storage permission', e);
      return true;
    }
  }
  
  /// Check if the app is policy compliant (no media permissions)
  bool isPolicyCompliant() {
    // This app does not request READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, etc.
    return true;
  }
}
