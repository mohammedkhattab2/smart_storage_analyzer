import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Platform specific utilities
class PlatformUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check if Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if Web
  static bool get isWeb => kIsWeb;

  /// Get device info
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final Map<String, dynamic> deviceData = {};

    try {
      if (isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData['platform'] = 'Android';
        deviceData['version'] = androidInfo.version.release;
        deviceData['device'] = androidInfo.model;
        deviceData['brand'] = androidInfo.brand;
      } else if (isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData['platform'] = 'iOS';
        deviceData['version'] = iosInfo.systemVersion;
        deviceData['device'] = iosInfo.model;
        deviceData['name'] = iosInfo.name;
      }
    } catch (e) {
      Logger.error('Failed to get device info', e);
    }

    return deviceData;
  }
}
