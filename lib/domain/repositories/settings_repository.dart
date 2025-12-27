import 'package:smart_storage_analyzer/domain/entities/settings.dart';

abstract class SettingsRepository {
  Future<Settings> getSettings();
  Future<void> updateNotification(bool enabled);
  Future<void> updateDarkMode(bool enabled);
  Future<void> signOut();
}
