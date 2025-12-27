import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';

class SignOutUsecase {
  final SettingsRepository repository;
  SignOutUsecase(this.repository);

  Future<void> excute() async {
    await repository.signOut();
  }
}
