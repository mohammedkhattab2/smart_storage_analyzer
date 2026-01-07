import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class SignOutUseCase {
  final SettingsRepository repository;

  SignOutUseCase(this.repository);
  Future<void> execute() async {
    await repository.signOut();
  }
}
