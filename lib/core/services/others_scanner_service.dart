import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OthersFile {
  final String name;
  final int size;
  final String mimeType;
  final String uri;

  OthersFile({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.uri,
  });

  factory OthersFile.fromMap(Map<String, dynamic> map) {
    return OthersFile(
      name: map['name'] as String,
      size: map['size'] as int,
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      uri: map['uri'] as String,
    );
  }
}

class OthersScannerService {
  static const _channel = MethodChannel('com.smarttools.storageanalyzer/native');
  static const _persistedUriKey = 'others_persisted_uri';
  static const _cachedOthersCountKey = 'cached_others_count';
  static const _cachedOthersSizeKey = 'cached_others_size';
  
  final SharedPreferences _prefs;
  List<OthersFile> _cachedOthers = [];
  String? _persistedUri;
  String? _folderName;

  OthersScannerService(this._prefs) {
    _loadPersistedUri();
  }
  
  void _loadPersistedUri() {
    _persistedUri = _prefs.getString(_persistedUriKey);
    _folderName = _prefs.getString('others_folder_name');
  }

  String? get persistedUri => _persistedUri;
  List<OthersFile> get cachedOthers => _cachedOthers;
  
  Future<String?> selectOthersFolder() async {
    try {
      final result = await _channel.invokeMethod('selectFolder');
      if (result != null && result is Map<dynamic, dynamic>) {
        final uri = result['uri'] as String?;
        if (uri != null) {
          await _persistUri(uri);
          _folderName = result['name'] as String? ?? 'Selected Folder';
          await _prefs.setString('others_folder_name', _folderName!);
          return uri;
        }
      }
      return null;
    } catch (e) {
      developer.log('Error selecting others folder: $e', name: 'OthersScannerService');
      return null;
    }
  }
  
  Future<void> _persistUri(String uri) async {
    _persistedUri = uri;
    await _prefs.setString(_persistedUriKey, uri);
  }
  
  Future<void> clearPersistedUri() async {
    _persistedUri = null;
    await _prefs.remove(_persistedUriKey);
    await _prefs.remove(_cachedOthersCountKey);
    await _prefs.remove(_cachedOthersSizeKey);
    _cachedOthers.clear();
  }
  
  Future<List<OthersFile>> scanOthers({bool forceRefresh = false}) async {
    // If no persisted URI, return empty
    if (_persistedUri == null) {
      return [];
    }
    
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _cachedOthers.isNotEmpty) {
      return _cachedOthers;
    }
    
    try {
      final result = await _channel.invokeMethod(
        'scanOthers',
        {'uri': _persistedUri},
      );
      
      if (result != null && result is Map) {
        final filesList = result['files'] as List<dynamic>? ?? [];
        _cachedOthers = filesList
            .map((file) => OthersFile.fromMap(Map<String, dynamic>.from(file)))
            .toList();
        
        // Cache the count and size for quick access
        await _cacheOthersStats();
        
        return _cachedOthers;
      }
      
      return [];
    } catch (e) {
      developer.log('Error scanning others: $e', name: 'OthersScannerService');
      return [];
    }
  }
  
  Future<void> _cacheOthersStats() async {
    final count = _cachedOthers.length;
    final totalSize = _cachedOthers.fold<int>(0, (sum, file) => sum + file.size);
    
    await _prefs.setInt(_cachedOthersCountKey, count);
    await _prefs.setInt(_cachedOthersSizeKey, totalSize);
  }
  
  int getCachedOthersCount() {
    return _prefs.getInt(_cachedOthersCountKey) ?? 0;
  }
  
  int getCachedOthersSize() {
    return _prefs.getInt(_cachedOthersSizeKey) ?? 0;
  }
  
  String? getFolderName() {
    // Return the saved folder name, or try to extract from URI
    if (_folderName != null) {
      return _folderName;
    }
    
    if (_persistedUri == null) return null;
    
    // Extract folder name from URI for display
    // The URI typically contains the folder name after the last ':'
    final parts = _persistedUri!.split(':');
    if (parts.isNotEmpty) {
      final path = parts.last;
      final pathParts = path.split('/');
      return pathParts.isNotEmpty ? pathParts.last : path;
    }
    return 'Selected Folder';
  }
}