import 'package:smart_storage_analyzer/domain/entities/settings.dart';

class SettingsModel extends Settings {
  const SettingsModel({
    required bool notificationsEnabled,
    required bool darkModeEnabled,
    required bool isPremiumUser,
  }) : super(
         notificationsEnabled: notificationsEnabled,
         darkModeEnabled: darkModeEnabled,
         isPremiumUser: isPremiumUser,
       );
  
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? true,
      isPremiumUser: json['isPremiumUser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'isPremiumUser': isPremiumUser,
    };
  }
}
