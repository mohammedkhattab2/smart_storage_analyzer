import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class GetSettingsUseCase {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);
  Future<Settings> execute() async {
    return await repository.getSettings();
  }
}
