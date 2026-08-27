import '../entities/whatsapp_scan_result.dart';
import '../repositories/whatsapp_repository.dart';

class ScanWhatsAppMediaUseCase {
  final WhatsAppRepository _repository;

  ScanWhatsAppMediaUseCase(this._repository);

  Future<WhatsAppScanResult> execute() async {
    return await _repository.scanMedia();
  }
}
