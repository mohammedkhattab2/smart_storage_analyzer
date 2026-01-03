import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/settings_model.dart';
import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _notificationsKey = "notifications_enabled";
  static const String _darkModeKey = "dark_mode_enabled";

  @override
  Future<Settings> getSettings() async {
    Logger.debug("Getting settings...");
    final prefs = await SharedPreferences.getInstance();
    return SettingsModel(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      darkModeEnabled: prefs.getBool(_darkModeKey) ?? true,
    );
  }

  @override
  Future<void> signOut() async {
    Logger.info("Signing out...");

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool("hasSeenOnboarding", true);
  }

  @override
  Future<void> updateDarkMode(bool enabled) async {
    Logger.debug('Updating dark mode: $enabled');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  @override
  Future<void> updateNotification(bool enabled) async {
    Logger.debug('Updating notifications: $enabled');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
