import '../repositories/whatsapp_repository.dart';

class CheckWhatsAppFolderUseCase {
  final WhatsAppRepository _repository;

  CheckWhatsAppFolderUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.hasSavedFolderPermission();
  }
}
