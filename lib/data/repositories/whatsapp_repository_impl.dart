import '../../core/utils/logger.dart';
import '../../domain/entities/whatsapp_media_item.dart';
import '../../domain/entities/whatsapp_scan_result.dart';
import '../../domain/repositories/whatsapp_repository.dart';
import '../datasources/whatsapp_saf_datasource.dart';

class WhatsAppRepositoryImpl implements WhatsAppRepository {
  final WhatsAppSAFDataSource _dataSource;

  WhatsAppRepositoryImpl(this._dataSource);

  @override
  Future<bool> hasSavedFolderPermission() async {
    // 1. Check if direct scan finds actual WhatsApp media on device without SAF
    final directResult = await _dataSource.tryDirectScan();
    if (directResult != null && directResult['path'] != null) {
      final rawItems = directResult['items'] as List<dynamic>?;
      if (rawItems != null && rawItems.isNotEmpty) {
        final path = directResult['path'] as String;
        await _dataSource.saveFolderUri('file://$path');
        return true;
      }
    }

    // 2. Check saved SAF URI
    final uri = _dataSource.getSavedFolderUri();
    if (uri == null || uri.isEmpty) return false;
    final isValid = await _dataSource.validateUri(uri);
    if (!isValid) {
      await _dataSource.clearSavedFolder();
      return false;
    }
    return true;
  }

  @override
  Future<bool> requestFolderAccess() async {
    final uri = await _dataSource.selectFolder();
    return uri != null && uri.isNotEmpty;
  }

  @override
  Future<WhatsAppScanResult> scanMedia() async {
    final uri = _dataSource.getSavedFolderUri();
    if (uri == null || uri.isEmpty) {
      Logger.warning('WhatsAppRepository: No folder URI saved. Returning empty result.');
      return WhatsAppScanResult.empty();
    }

    final rawList = await _dataSource.scanMedia(uri);
    if (rawList.isEmpty && uri.startsWith('file://')) {
      Logger.warning('WhatsAppRepository: Direct file scan returned 0 files. Clearing invalid URI.');
      await _dataSource.clearSavedFolder();
    }
    final items = rawList.map((map) => WhatsAppMediaItem.fromMap(map)).toList();
    return WhatsAppScanResult.fromItems(items);
  }

  @override
  Future<int> deleteFiles(List<String> fileUris) async {
    if (fileUris.isEmpty) return 0;
    return await _dataSource.deleteFiles(fileUris);
  }

  @override
  Future<void> clearSavedFolder() async {
    await _dataSource.clearSavedFolder();
  }
}
