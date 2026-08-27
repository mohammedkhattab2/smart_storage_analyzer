import '../repositories/whatsapp_repository.dart';

class DeleteWhatsAppMediaUseCase {
  final WhatsAppRepository _repository;

  DeleteWhatsAppMediaUseCase(this._repository);

  Future<int> execute(List<String> fileUris) async {
    if (fileUris.isEmpty) return 0;
    return await _repository.deleteFiles(fileUris);
  }
}
