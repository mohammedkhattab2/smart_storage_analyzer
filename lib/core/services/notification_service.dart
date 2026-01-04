import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = 
      MethodChannel('com.smartstorage/native');
  
  static NotificationService? _instance;
  
  NotificationService._();
  
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }
  
  /// Schedule periodic notifications every 2 hours
  Future<bool> scheduleNotifications() async {
    try {
      final result = await _channel.invokeMethod('scheduleNotifications');
      return result ?? false;
    } catch (e) {
      print('Error scheduling notifications: $e');
      return false;
    }
  }
  
  /// Cancel all scheduled notifications
  Future<bool> cancelNotifications() async {
    try {
      final result = await _channel.invokeMethod('cancelNotifications');
      return result ?? false;
    } catch (e) {
      print('Error cancelling notifications: $e');
      return false;
    }
  }
  
  /// Check if notifications are enabled in settings
  Future<bool> areNotificationsEnabled() async {
    // This is a placeholder - you can implement actual notification permission check
    // For now, we'll return true assuming notifications are enabled
    return true;
  }
  
  /// Request notification permission (if needed)
  Future<bool> requestNotificationPermission() async {
    // On Android, notification permissions are granted by default for API < 33
    // For API 33+, you would need to implement permission request
    return true;
  }
}