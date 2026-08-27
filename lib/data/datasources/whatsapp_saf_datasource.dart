import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

abstract class WhatsAppSAFDataSource {
  Future<String?> selectFolder();
  Future<bool> validateUri(String uri);
  Future<List<Map<dynamic, dynamic>>> scanMedia(String folderUri);
  Future<int> deleteFiles(List<String> uris);
  Future<Map<String, dynamic>?> tryDirectScan();
  String? getSavedFolderUri();
  Future<void> saveFolderUri(String uri);
  Future<void> clearSavedFolder();
}

class WhatsAppSAFDataSourceImpl implements WhatsAppSAFDataSource {
  static const String _channelName = 'com.smarttools.storageanalyzer/native';
  static const String _prefsKeyUri = 'whatsapp_saf_folder_uri';

  final MethodChannel _channel = const MethodChannel(_channelName);
  final SharedPreferences _prefs;

  WhatsAppSAFDataSourceImpl(this._prefs);

  @override
  String? getSavedFolderUri() {
    return _prefs.getString(_prefsKeyUri);
  }

  @override
  Future<void> saveFolderUri(String uri) async {
    await _prefs.setString(_prefsKeyUri, uri);
  }

  @override
  Future<void> clearSavedFolder() async {
    await _prefs.remove(_prefsKeyUri);
  }

  @override
  Future<bool> validateUri(String uri) async {
    try {
      final isValid = await _channel.invokeMethod<bool>('validateWhatsAppUri', {
        'uri': uri,
      });
      return isValid ?? false;
    } catch (e) {
      Logger.error('WhatsAppSAFDataSource: Error validating URI', e);
      return false;
    }
  }

  @override
  Future<String?> selectFolder() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('selectWhatsAppFolder');
      if (result != null && result['uri'] != null) {
        final uri = result['uri'] as String;
        await saveFolderUri(uri);
        return uri;
      }
      return null;
    } catch (e) {
      Logger.error('WhatsAppSAFDataSource: Error selecting WhatsApp folder', e);
      return null;
    }
  }

  @override
  Future<List<Map<dynamic, dynamic>>> scanMedia(String folderUri) async {
    try {
      final result = await _channel.invokeListMethod<dynamic>('scanWhatsAppMedia', {
        'uri': folderUri,
      });
      if (result == null) return [];
      return result.map((item) => item as Map<dynamic, dynamic>).toList();
    } catch (e) {
      Logger.error('WhatsAppSAFDataSource: Error scanning WhatsApp media', e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> tryDirectScan() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('tryDirectScan');
      return result;
    } catch (e) {
      Logger.error('WhatsAppSAFDataSource: Error trying direct scan', e);
      return null;
    }
  }

  @override
  Future<int> deleteFiles(List<String> uris) async {
    try {
      final deletedCount = await _channel.invokeMethod<int>('deleteWhatsAppFiles', {
        'uris': uris,
      });
      return deletedCount ?? 0;
    } catch (e) {
      Logger.error('WhatsAppSAFDataSource: Error deleting WhatsApp files', e);
      return 0;
    }
  }
}
