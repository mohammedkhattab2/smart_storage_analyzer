import '../repositories/whatsapp_repository.dart';

class RequestWhatsAppFolderAccessUseCase {
  final WhatsAppRepository _repository;

  RequestWhatsAppFolderAccessUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.requestFolderAccess();
  }
}
