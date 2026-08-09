import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';

/// Data-layer model representing an app with usage and size information
/// coming from the native (Android) side via MethodChannel.
///
/// This model is responsible for:
/// - Parsing raw platform maps
/// - Converting to the pure domain entity [UnusedApp].
class UnusedAppModel extends Equatable {
  final String packageName;
  final String appName;
  final DateTime lastUsed;
  final int appSizeBytes;
  final bool isSystemApp;

  const UnusedAppModel({
    required this.packageName,
    required this.appName,
    required this.lastUsed,
    required this.appSizeBytes,
    this.isSystemApp = false,
  });

  factory UnusedAppModel.fromMap(Map<dynamic, dynamic> map) {
    final packageName = map['packageName'] as String? ?? '';
    final appName = map['name'] as String? ?? map['appName'] as String? ?? packageName;

    // lastUsed can be provided as millis since epoch or omitted.
    // If missing, we treat it as "never used" => epoch(0).
    final lastUsedMillis = (map['lastUsed'] as num?)?.toInt();
    final lastUsed = lastUsedMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastUsedMillis)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final size = (map['size'] as num?)?.toInt() ?? 0;
    final isSystem = map['isSystemApp'] as bool? ?? false;

    return UnusedAppModel(
      packageName: packageName,
      appName: appName,
      lastUsed: lastUsed,
      appSizeBytes: size,
      isSystemApp: isSystem,
    );
  }

  UnusedApp toEntity() {
    return UnusedApp(
      packageName: packageName,
      appName: appName,
      lastUsed: lastUsed,
      appSizeBytes: appSizeBytes,
      isSystemApp: isSystemApp,
    );
  }

  @override
  List<Object?> get props => [
        packageName,
        appName,
        lastUsed,
        appSizeBytes,
        isSystemApp,
      ];
}