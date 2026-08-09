import 'dart:io';

import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/unused_app_model.dart';
import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';
import 'package:smart_storage_analyzer/domain/errors/unused_apps_failures.dart';
import 'package:smart_storage_analyzer/domain/repositories/unused_apps_repository.dart';

/// Concrete implementation of [UnusedAppsRepository].
///
/// Responsibilities:
/// - Communicate with Android via MethodChannel (apps category)
/// - Map platform data into [UnusedApp] domain entities
/// - Apply basic filtering by inactivity period (in Dart)
///
/// This keeps platform details out of the domain and presentation layers.
class UnusedAppsRepositoryImpl implements UnusedAppsRepository {
  static const MethodChannel _channel =
      MethodChannel(ChannelConstants.mainChannel);

  @override
  Future<List<UnusedApp>> getAllApps() async {
    if (!Platform.isAndroid) {
      Logger.info('[UnusedAppsRepositoryImpl] Non-Android platform, returning empty list');
      return [];
    }

    try {
      Logger.info('[UnusedAppsRepositoryImpl] Fetching app storage stats from native layer');

      // Ensure usage access permission is granted before querying app stats.
      final bool hasUsageAccess =
          await _channel.invokeMethod<bool>('checkUsagePermission') ?? false;
      if (!hasUsageAccess) {
        Logger.warning(
          '[UnusedAppsRepositoryImpl] Usage access permission not granted. Throwing UsageAccessDeniedException.',
        );
        throw const UsageAccessDeniedException();
      }

      final dynamic result = await _channel.invokeMethod(
        'getFilesByCategory',
        {'category': 'apps'},
      );

      if (result is! List) {
        Logger.warning(
          '[UnusedAppsRepositoryImpl] Unexpected result type from native: ${result.runtimeType}',
        );
        return [];
      }

      final apps = result
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => UnusedAppModel.fromMap(map).toEntity())
          // استبعد تطبيقات النظام بالكامل، نعرض فقط تطبيقات المستخدم (ألعاب / برامج)
          .where((app) => !app.isSystemApp)
          .toList();

      Logger.info(
        '[UnusedAppsRepositoryImpl] Mapped ${apps.length} apps from native stats',
      );

      return apps;
    } on UsageAccessDeniedException {
      // Propagate permission-specific error so the domain/presentation layers
      // can show a dedicated "Usage Access Required" UI.
      rethrow;
    } catch (e) {
      Logger.error('[UnusedAppsRepositoryImpl] Failed to load app stats', e);
      return [];
    }
  }

  @override
  Future<List<UnusedApp>> getUnusedApps({
    required int minDaysUnused,
  }) async {
    final allApps = await getAllApps();
    if (allApps.isEmpty) return [];

    final now = DateTime.now();
    final unusedApps = allApps.where((app) {
      final inactivityDays = now.difference(app.lastUsed).inDays;
      return inactivityDays >= minDaysUnused;
    }).toList();

    Logger.info(
      '[UnusedAppsRepositoryImpl] Filtered ${unusedApps.length} unused apps with threshold $minDaysUnused days',
    );

    return unusedApps;
  }
}