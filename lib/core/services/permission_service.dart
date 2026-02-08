import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service to handle permission requests
///
/// Updated for Google Play Photo and Video Permissions Policy compliance.
/// This app is a storage analyzer that does NOT require:
/// - READ_MEDIA_IMAGES
/// - READ_MEDIA_VIDEO
/// - READ_MEDIA_AUDIO
/// - READ_EXTERNAL_STORAGE
/// - WRITE_EXTERNAL_STORAGE
///
/// Instead, it uses:
/// - PACKAGE_USAGE_STATS for app storage analysis (requires user to grant in Settings)
/// - SAF (Storage Access Framework) for user-selected folder access
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const MethodChannel _channel = MethodChannel('com.smarttools.storageanalyzer/native');

  /// Check and request usage stats permission (for app storage analysis)
  /// This is the only permission needed for policy-compliant storage analysis
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;

    try {
      // Check if usage stats permission is granted
      final hasPermission = await checkUsageStatsPermission();
      
      if (hasPermission) {
        return true;
      }

      // Show dialog explaining why we need usage stats permission
      if (context != null && context.mounted) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          title: 'Usage Access Required',
          content:
              'Smart Storage Analyzer needs Usage Access permission to:\n\n'
              '• Analyze app storage usage\n'
              '• Show which apps are using the most space\n'
              '• Calculate total storage breakdown\n'
              '• Help you identify apps to uninstall\n\n'
              'This permission allows us to see app sizes without accessing your personal files.\n\n'
              'Your privacy is protected - we never access your photos, videos, or documents.\n\n'
              'Would you like to grant this permission in settings?',
        );

        if (shouldOpenSettings) {
          await requestUsageStatsPermission();
        }
      }
      
      return false;
    } catch (e) {
      Logger.error('Error requesting usage stats permission', e);
      return false;
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

  /// Check if we have necessary permissions (usage stats for policy compliance)
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // For policy-compliant storage analysis, we only need usage stats permission
      return await checkUsageStatsPermission();
    } catch (e) {
      Logger.error('Error checking storage permission', e);
      return false;
    }
  }
  
  /// Check if the app is policy compliant (no media permissions)
  bool isPolicyCompliant() {
    // This app does not request READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, etc.
    return true;
  }
}
