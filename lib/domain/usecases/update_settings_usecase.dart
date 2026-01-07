import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class UpdateSettingsUseCase {
  final SettingsRepository repository;
  UpdateSettingsUseCase(this.repository);
  Future<void> updateNotifications(bool enabled) async {
    await repository.updateNotification(enabled);
  }

  Future<void> updateDarkMode(bool enabled) async {
    await repository.updateDarkMode(enabled);
  }
}
