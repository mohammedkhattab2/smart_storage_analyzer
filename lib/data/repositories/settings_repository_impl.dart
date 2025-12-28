import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/data/models/settings_model.dart';
import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _notificationsKey = "notificationd_enabled";
  static const String _darkModeKey = "dark_mode_enabled";
  static const String _premiumKey = "is_premium_user";

  @override
  Future<Settings> getSettings() async {
    print("Getting settings...");
    final prefs = await SharedPreferences.getInstance();
    return SettingsModel(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      darkModeEnabled: prefs.getBool(_darkModeKey) ?? true,
      isPremiumUser: prefs.getBool(_premiumKey) ?? false,
    );
  }

  @override
  Future<void> signOut() async {
    print("Signing out...");

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool("hasSeenOnboarding", true);
  }

  @override
  Future<void> updateDarkMode(bool enabled) async {
    print('Updating dark mode: $enabled');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  @override
  Future<void> updateNotification(bool enabled) async {
    print('Updating notifications: $enabled');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
