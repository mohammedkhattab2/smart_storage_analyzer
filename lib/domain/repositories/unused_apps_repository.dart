import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';

/// Repository contract for accessing installed apps and their usage data.
///
/// Domain layer only depends on this abstraction, not on MethodChannel
/// or any platform-specific implementation.
abstract class UnusedAppsRepository {
  /// Get all apps that have usage information available.
  ///
  /// The repository implementation is responsible for:
  /// - Talking to the native layer via MethodChannel
  /// - Mapping raw platform data into [UnusedApp] entities.
  Future<List<UnusedApp>> getAllApps();

  /// Get apps that are considered "unused" based on [minDaysUnused].
  ///
  /// Example thresholds:
  /// - 7 days
  /// - 30 days
  /// - 60+ days
  ///
  /// The repository may implement this either:
  /// - fully in Dart using [getAllApps] data, or
  /// - by delegating filtering to the native layer and just mapping results.
  Future<List<UnusedApp>> getUnusedApps({
    required int minDaysUnused,
  });
}