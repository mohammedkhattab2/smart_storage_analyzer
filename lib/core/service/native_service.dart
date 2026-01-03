import 'package:flutter/services.dart';

class NativeService {
  static const platform = MethodChannel('com.smartstorage/native');

  /// Check if app has usage stats permission
  static Future<bool> checkUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod('checkUsagePermission');
      return result;
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  /// Request usage stats permission
  static Future<void> requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } catch (e) {
      print('Error requesting usage permission: $e');
    }
  }

  /// Get storage info from native
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getStorageInfo',
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error getting storage info: $e');
      return {};
    }
  }

  /// Get all files from native
  static Future<List<Map<String, dynamic>>> getAllFiles() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getAllFiles');
      return result.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }
}
