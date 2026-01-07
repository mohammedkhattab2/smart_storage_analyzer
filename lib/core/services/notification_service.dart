import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel(
    ChannelConstants.mainChannel,
  );

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
      Logger.error('Error scheduling notifications', e);
      return false;
    }
  }

  /// Cancel all scheduled notifications
  Future<bool> cancelNotifications() async {
    try {
      final result = await _channel.invokeMethod('cancelNotifications');
      return result ?? false;
    } catch (e) {
      Logger.error('Error cancelling notifications', e);
      return false;
    }
  }

  /// Check if notifications are enabled in settings
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _channel.invokeMethod('areNotificationsEnabled');
      return result ?? false;
    } catch (e) {
      Logger.error('Error checking notification status', e);
      return false;
    }
  }

  /// Request notification permission (if needed)
  Future<bool> requestNotificationPermission() async {
    try {
      // On Android, notification permissions are granted by default for API < 33
      // For API 33+, this method will handle permission request
      final result = await _channel.invokeMethod('requestNotificationPermission');
      return result ?? false;
    } catch (e) {
      Logger.error('Error requesting notification permission', e);
      return false;
    }
  }
}
