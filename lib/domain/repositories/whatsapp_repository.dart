import '../entities/whatsapp_scan_result.dart';

/// Abstract repository contract for WhatsApp media scanning and operations
abstract class WhatsAppRepository {
  /// Check if a valid WhatsApp folder URI is saved with persistent permission
  Future<bool> hasSavedFolderPermission();

  /// Request user to select WhatsApp media folder via SAF picker
  Future<bool> requestFolderAccess();

  /// Perform scan of WhatsApp media folder
  Future<WhatsAppScanResult> scanMedia();

  /// Delete a list of WhatsApp media files by their URIs
  Future<int> deleteFiles(List<String> fileUris);

  /// Clear the saved folder permission
  Future<void> clearSavedFolder();
}
