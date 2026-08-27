import '../../core/utils/logger.dart';
import '../../domain/entities/whatsapp_media_item.dart';
import '../../domain/entities/whatsapp_scan_result.dart';
import '../../domain/usecases/check_whatsapp_folder_usecase.dart';
import '../../domain/usecases/delete_whatsapp_media_usecase.dart';
import '../../domain/usecases/request_whatsapp_folder_access_usecase.dart';
import '../../domain/usecases/scan_whatsapp_media_usecase.dart';

enum WhatsAppFilterType {
  all,
  sent,
  received,
  oldOnly,
  largestFirst,
}

/// ViewModel for WhatsApp Cleaner feature following MVVM pattern
class WhatsAppCleanerViewModel {
  final CheckWhatsAppFolderUseCase _checkFolderUseCase;
  final RequestWhatsAppFolderAccessUseCase _requestFolderUseCase;
  final ScanWhatsAppMediaUseCase _scanMediaUseCase;
  final DeleteWhatsAppMediaUseCase _deleteMediaUseCase;

  WhatsAppCleanerViewModel({
    required CheckWhatsAppFolderUseCase checkFolderUseCase,
    required RequestWhatsAppFolderAccessUseCase requestFolderUseCase,
    required ScanWhatsAppMediaUseCase scanMediaUseCase,
    required DeleteWhatsAppMediaUseCase deleteMediaUseCase,
  })  : _checkFolderUseCase = checkFolderUseCase,
        _requestFolderUseCase = requestFolderUseCase,
        _scanMediaUseCase = scanMediaUseCase,
        _deleteMediaUseCase = deleteMediaUseCase;

  Future<bool> checkFolderPermission() async {
    try {
      return await _checkFolderUseCase.execute();
    } catch (e) {
      Logger.error('WhatsAppCleanerViewModel: Error checking folder permission', e);
      return false;
    }
  }

  Future<bool> requestFolderAccess() async {
    try {
      return await _requestFolderUseCase.execute();
    } catch (e) {
      Logger.error('WhatsAppCleanerViewModel: Error requesting folder access', e);
      return false;
    }
  }

  Future<WhatsAppScanResult> scanMedia() async {
    try {
      Logger.info('WhatsAppCleanerViewModel: Scanning WhatsApp media...');
      final result = await _scanMediaUseCase.execute();
      Logger.success('WhatsAppCleanerViewModel: Scan completed with ${result.totalFilesCount} files');
      return result;
    } catch (e) {
      Logger.error('WhatsAppCleanerViewModel: Error scanning media', e);
      rethrow;
    }
  }

  Future<int> deleteFiles(List<String> fileUris) async {
    try {
      Logger.info('WhatsAppCleanerViewModel: Deleting ${fileUris.length} files...');
      final count = await _deleteMediaUseCase.execute(fileUris);
      Logger.success('WhatsAppCleanerViewModel: Deleted $count files');
      return count;
    } catch (e) {
      Logger.error('WhatsAppCleanerViewModel: Error deleting files', e);
      rethrow;
    }
  }

  /// Filter a category list of items based on filter mode
  List<WhatsAppMediaItem> filterItems(
    List<WhatsAppMediaItem> items,
    WhatsAppFilterType filter,
  ) {
    List<WhatsAppMediaItem> filtered = List.from(items);

    switch (filter) {
      case WhatsAppFilterType.all:
        break;
      case WhatsAppFilterType.sent:
        filtered = filtered.where((item) => item.isSent).toList();
        break;
      case WhatsAppFilterType.received:
        filtered = filtered.where((item) => !item.isSent).toList();
        break;
      case WhatsAppFilterType.oldOnly:
        filtered = filtered.where((item) => item.isOlderThan(30)).toList();
        break;
      case WhatsAppFilterType.largestFirst:
        filtered.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }

    return filtered;
  }
}
