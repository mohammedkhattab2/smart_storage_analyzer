import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// Document file data model
class DocumentFile {
  final String name;
  final String path;
  final String uri;
  final int size;
  final String mimeType;
  final DateTime lastModified;
  final String extension;

  DocumentFile({
    required this.name,
    required this.path,
    required this.uri,
    required this.size,
    required this.mimeType,
    required this.lastModified,
    required this.extension,
  });

  factory DocumentFile.fromMap(Map<dynamic, dynamic> map) {
    return DocumentFile(
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      uri: map['uri'] ?? '',
      size: map['size'] ?? 0,
      mimeType: map['mimeType'] ?? 'application/octet-stream',
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        map['lastModified'] ?? 0,
      ),
      extension: map['extension'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'uri': uri,
      'size': size,
      'mimeType': mimeType,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'extension': extension,
    };
  }
}

/// Service for handling document scanning using Storage Access Framework (SAF)
class DocumentScannerService {
  static const String _channel = 'com.smarttools.storageanalyzer/native';
  static const String _persistedUriKey = 'saf_document_uri';
  static const String _persistedFolderNameKey = 'saf_folder_name';
  
  final MethodChannel _methodChannel = const MethodChannel(_channel);
  final SharedPreferences _prefs;
  
  // Cached documents
  List<DocumentFile>? _cachedDocuments;
  String? _selectedFolderUri;
  String? _selectedFolderName;
  
  DocumentScannerService(this._prefs) {
    // Load persisted URI synchronously from SharedPreferences
    _loadPersistedUriSync();
  }
  
  /// Load previously selected folder URI from SharedPreferences (synchronous)
  void _loadPersistedUriSync() {
    try {
      _selectedFolderUri = _prefs.getString(_persistedUriKey);
      _selectedFolderName = _prefs.getString(_persistedFolderNameKey);
      
      if (_selectedFolderUri != null) {
        Logger.info('[SAF] Loaded persisted URI: $_selectedFolderUri');
        Logger.info('[SAF] Folder name: $_selectedFolderName');
      } else {
        Logger.info('[SAF] No persisted URI found');
      }
    } catch (e) {
      Logger.error('[SAF] Error loading persisted URI: $e');
    }
  }
  
  /// Check if we have an existing folder permission
  bool get hasFolderAccess => _selectedFolderUri != null;
  
  /// Get the name of the selected folder
  String? get selectedFolderName => _selectedFolderName;
  
  /// Get cached documents
  List<DocumentFile>? get cachedDocuments => _cachedDocuments;
  
  /// Open system folder picker using SAF ACTION_OPEN_DOCUMENT_TREE
  /// Returns true if a folder was selected, false if cancelled
  Future<bool> selectDocumentFolder() async {
    try {
      Logger.info('[SAF] Opening folder picker...');
      
      final Map<dynamic, dynamic>? result = await _methodChannel.invokeMethod(
        'selectDocumentFolder',
      );
      
      if (result != null && result['uri'] != null) {
        _selectedFolderUri = result['uri'];
        _selectedFolderName = result['name'] ?? 'Documents';
        
        // Persist the URI for future use
        await _prefs.setString(_persistedUriKey, _selectedFolderUri!);
        await _prefs.setString(_persistedFolderNameKey, _selectedFolderName!);
        
        Logger.info('[SAF] Folder selected: $_selectedFolderName');
        Logger.info('[SAF] URI: $_selectedFolderUri');
        
        return true;
      } else {
        Logger.info('[SAF] Folder selection cancelled');
        return false;
      }
    } catch (e) {
      Logger.error('[SAF] Error selecting folder: $e');
      return false;
    }
  }
  
  /// Scan documents in the selected folder
  /// Returns list of DocumentFile objects
  Future<List<DocumentFile>> scanDocuments({
    bool useCache = false,
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached documents if available and not forcing refresh
      if (useCache && !forceRefresh && _cachedDocuments != null) {
        Logger.info('[SAF] Returning cached documents: ${_cachedDocuments!.length} files');
        return _cachedDocuments!;
      }
      
      // Check if we have folder access
      if (!hasFolderAccess) {
        Logger.warning('[SAF] No folder access. Please select a folder first.');
        return [];
      }
      
      Logger.info('[SAF] Starting document scan...');
      Logger.info('[SAF] Using URI: $_selectedFolderUri');
      
      final List<dynamic>? results = await _methodChannel.invokeMethod(
        'scanDocuments',
        {
          'uri': _selectedFolderUri,
        },
      );
      
      if (results != null) {
        _cachedDocuments = results
            .map((item) => DocumentFile.fromMap(item as Map<dynamic, dynamic>))
            .toList();
        
        Logger.info('[SAF] Found ${_cachedDocuments!.length} documents');
        
        // Log some statistics
        _logDocumentStatistics();
        
        return _cachedDocuments!;
      } else {
        Logger.warning('[SAF] No documents found or scan failed');
        _cachedDocuments = [];
        return [];
      }
    } catch (e) {
      Logger.error('[SAF] Error scanning documents: $e');
      return [];
    }
  }
  
  /// Clear the selected folder and cached documents
  Future<void> clearFolderAccess() async {
    try {
      Logger.info('[SAF] Clearing folder access...');
      
      // Release URI permission on Android side
      if (_selectedFolderUri != null) {
        await _methodChannel.invokeMethod(
          'releaseUriPermission',
          {
            'uri': _selectedFolderUri,
          },
        );
      }
      
      // Clear persisted data
      await _prefs.remove(_persistedUriKey);
      await _prefs.remove(_persistedFolderNameKey);
      
      // Clear cached data
      _selectedFolderUri = null;
      _selectedFolderName = null;
      _cachedDocuments = null;
      
      Logger.info('[SAF] Folder access cleared');
    } catch (e) {
      Logger.error('[SAF] Error clearing folder access: $e');
    }
  }
  
  /// Check if the persisted URI is still valid (has permission)
  Future<bool> validatePersistedUri() async {
    if (!hasFolderAccess) return false;
    
    try {
      final bool isValid = await _methodChannel.invokeMethod(
        'validateUri',
        {
          'uri': _selectedFolderUri,
        },
      );
      
      if (!isValid) {
        Logger.warning('[SAF] Persisted URI is no longer valid');
        await clearFolderAccess();
      }
      
      return isValid;
    } catch (e) {
      Logger.error('[SAF] Error validating URI: $e');
      return false;
    }
  }
  
  /// Get document categories breakdown
  Map<String, List<DocumentFile>> getCategorizedDocuments() {
    if (_cachedDocuments == null || _cachedDocuments!.isEmpty) {
      return {};
    }
    
    final Map<String, List<DocumentFile>> categories = {
      'PDF': [],
      'Office': [],
      'Text': [],
      'Spreadsheets': [],
      'Presentations': [],
      'Other': [],
    };
    
    for (final doc in _cachedDocuments!) {
      final ext = doc.extension.toLowerCase();
      
      if (ext == '.pdf') {
        categories['PDF']!.add(doc);
      } else if (['.doc', '.docx', '.odt'].contains(ext)) {
        categories['Office']!.add(doc);
      } else if (['.txt', '.md', '.rtf', '.log'].contains(ext)) {
        categories['Text']!.add(doc);
      } else if (['.xls', '.xlsx', '.csv', '.ods'].contains(ext)) {
        categories['Spreadsheets']!.add(doc);
      } else if (['.ppt', '.pptx', '.odp'].contains(ext)) {
        categories['Presentations']!.add(doc);
      } else {
        categories['Other']!.add(doc);
      }
    }
    
    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);
    
    return categories;
  }
  
  /// Calculate total size of all documents
  int getTotalDocumentSize() {
    if (_cachedDocuments == null) return 0;
    
    return _cachedDocuments!.fold<int>(
      0,
      (total, doc) => total + doc.size,
    );
  }
  
  /// Log document statistics for debugging
  void _logDocumentStatistics() {
    if (_cachedDocuments == null || _cachedDocuments!.isEmpty) return;
    
    final categories = getCategorizedDocuments();
    final totalSize = getTotalDocumentSize();
    
    Logger.info('[SAF] Document Statistics:');
    Logger.info('[SAF] Total files: ${_cachedDocuments!.length}');
    Logger.info('[SAF] Total size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
    
    categories.forEach((category, files) {
      final categorySize = files.fold<int>(0, (sum, file) => sum + file.size);
      Logger.info('[SAF] $category: ${files.length} files, ${(categorySize / 1024 / 1024).toStringAsFixed(2)} MB');
    });
  }
}