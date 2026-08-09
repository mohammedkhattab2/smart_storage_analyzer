import 'dart:io';

import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service for app-level management operations such as uninstalling apps.
///
/// This service is the only place that talks directly to the platform
/// for app management, keeping MethodChannel usage out of UI and Cubits.
class AppManagementService {
  static const MethodChannel _channel =
      MethodChannel(ChannelConstants.mainChannel);

  AppManagementService._();

  static final AppManagementService _instance = AppManagementService._();

  factory AppManagementService() => _instance;

  /// Request uninstall of an app by its package name.
  ///
  /// On Android this will open the system uninstall screen using
  /// `Intent.ACTION_UNINSTALL_PACKAGE`. The user must confirm the action.
  ///
  /// Returns `true` if the intent was successfully launched, `false` otherwise.
  Future<bool> uninstallApp(String packageName) async {
    try {
      if (!Platform.isAndroid) {
        Logger.warning(
          '[AppManagementService] Uninstall is only supported on Android',
        );
        return false;
      }

      if (packageName.isEmpty) {
        Logger.warning(
          '[AppManagementService] Cannot uninstall app with empty package name',
        );
        return false;
      }

      final result = await _channel.invokeMethod<bool>(
        'uninstallApp',
        {
          'packageName': packageName,
        },
      );

      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error(
        '[AppManagementService] Platform error while uninstalling $packageName: ${e.message}',
        e,
      );
      return false;
    } catch (e) {
      Logger.error(
        '[AppManagementService] Unexpected error while uninstalling $packageName',
        e,
      );
      return false;
    }
  }
}