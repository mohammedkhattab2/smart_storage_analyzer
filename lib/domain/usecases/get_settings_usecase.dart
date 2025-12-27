import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class GetSettingsUsecase {
  final SettingsRepository repository;
  GetSettingsUsecase(this.repository);

  Future<Settings> execute() async {
    return await repository.getSettings();
  }
}
