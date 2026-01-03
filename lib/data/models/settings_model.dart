import 'package:smart_storage_analyzer/domain/entities/settings.dart';

class SettingsModel extends Settings {
  const SettingsModel({
    required super.notificationsEnabled,
    required super.darkModeEnabled,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
    };
  }
}
