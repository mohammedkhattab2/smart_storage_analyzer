import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for SAF-based file manager scanning
/// Scans user-selected folders and categorizes files into All, Large, Duplicates, Old
class SafFileManagerService {
  static const _channel = MethodChannel(ChannelConstants.mainChannel);
  
  // Singleton pattern
  static final SafFileManagerService _instance = SafFileManagerService._internal();
  factory SafFileManagerService() => _instance;
  SafFileManagerService._internal();
  
  // Cache for scanned files
  String? _selectedFolderUri;
  String? _selectedFolderName;
  List<ScannedFileItem>? _allFiles;
  DateTime? _lastScanTime;
  
  // Getters
  String? get selectedFolderUri => _selectedFolderUri;
  String? get selectedFolderName => _selectedFolderName;
  bool get hasFolderSelected => _selectedFolderUri != null;
  List<ScannedFileItem>? get allFiles => _allFiles;
  
  /// Select a folder using SAF
  Future<FolderSelectionResult?> selectFolder() async {
    try {
      Logger.info('[SafFileManager] Opening folder picker...');
      
      final result = await _channel.invokeMethod('selectFolder');
      
      if (result == null) {
        Logger.info('[SafFileManager] User cancelled folder selection');
        return null;
      }
      
      final uri = result['uri'] as String?;
      final name = result['name'] as String?;
      
      if (uri == null || name == null) {
        Logger.warning('[SafFileManager] Invalid folder selection result');
        return null;
      }
      
      _selectedFolderUri = uri;
      _selectedFolderName = name;
      
      Logger.info('[SafFileManager] Folder selected: $name');
      
      return FolderSelectionResult(
        uri: uri,
        name: name,
      );
    } on PlatformException catch (e) {
      Logger.error('[SafFileManager] Platform error selecting folder: ${e.message}');
      return null;
    } catch (e) {
      Logger.error('[SafFileManager] Error selecting folder: $e');
      return null;
    }
  }
  
  /// Scan the selected folder for all files
  Future<FileScanResult> scanFolder({
    void Function(int scanned, int total)? onProgress,
  }) async {
    if (_selectedFolderUri == null) {
      return FileScanResult(
        files: [],
        totalSize: 0,
        error: 'No folder selected',
      );
    }
    
    try {
      Logger.info('[SafFileManager] Scanning folder: $_selectedFolderName');
      
      final result = await _channel.invokeMethod('scanFolderForFiles', {
        'uri': _selectedFolderUri,
        'recursive': true,
      });
      
      if (result == null) {
        return FileScanResult(
          files: [],
          totalSize: 0,
          error: 'Failed to scan folder',
        );
      }
      
      final filesData = result['files'] as List<dynamic>? ?? [];
      final files = <ScannedFileItem>[];
      int totalSize = 0;
      
      for (int i = 0; i < filesData.length; i++) {
        final fileData = filesData[i] as Map<dynamic, dynamic>;
        final file = ScannedFileItem.fromMap(fileData);
        files.add(file);
        totalSize += file.size;
        
        if (onProgress != null && i % 100 == 0) {
          onProgress(i, filesData.length);
        }
      }
      
      // Sort by size (largest first)
      files.sort((a, b) => b.size.compareTo(a.size));
      
      _allFiles = files;
      _lastScanTime = DateTime.now();
      
      Logger.info('[SafFileManager] Scanned ${files.length} files, total size: ${totalSize ~/ (1024 * 1024)} MB');
      
      return FileScanResult(
        files: files,
        totalSize: totalSize,
      );
    } on PlatformException catch (e) {
      Logger.error('[SafFileManager] Platform error scanning folder: ${e.message}');
      return FileScanResult(
        files: [],
        totalSize: 0,
        error: e.message ?? 'Platform error',
      );
    } catch (e) {
      Logger.error('[SafFileManager] Error scanning folder: $e');
      return FileScanResult(
        files: [],
        totalSize: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Get files by category
  List<ScannedFileItem> getFilesByCategory(FileCategory category) {
    if (_allFiles == null || _allFiles!.isEmpty) {
      return [];
    }
    
    switch (category) {
      case FileCategory.all:
        return _allFiles!;
        
      case FileCategory.large:
        // Files larger than 50MB
        return _allFiles!.where((f) => f.size > 50 * 1024 * 1024).toList();
        
      case FileCategory.duplicates:
        return _findDuplicates();
        
      case FileCategory.old:
        // Files not modified in the last 6 months
        final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
        return _allFiles!.where((f) => f.lastModified.isBefore(sixMonthsAgo)).toList();
        
      default:
        return _allFiles!;
    }
  }
  
  /// Find duplicate files based on size and name similarity
  List<ScannedFileItem> _findDuplicates() {
    if (_allFiles == null || _allFiles!.isEmpty) {
      return [];
    }
    
    final duplicates = <ScannedFileItem>[];
    final sizeGroups = <int, List<ScannedFileItem>>{};
    
    // Group files by size
    for (final file in _allFiles!) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }
    
    // Find groups with more than one file (potential duplicates)
    for (final group in sizeGroups.values) {
      if (group.length > 1) {
        // Further check by name hash for better accuracy
        final nameGroups = <String, List<ScannedFileItem>>{};
        for (final file in group) {
          // Create a hash based on file name without extension
          final baseName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '').toLowerCase();
          final hash = md5.convert(utf8.encode(baseName)).toString().substring(0, 8);
          nameGroups.putIfAbsent(hash, () => []).add(file);
        }
        
        for (final nameGroup in nameGroups.values) {
          if (nameGroup.length > 1) {
            duplicates.addAll(nameGroup);
          }
        }
      }
    }
    
    return duplicates;
  }
  
  /// Convert ScannedFileItem to FileItem for compatibility
  List<FileItem> convertToFileItems(List<ScannedFileItem> scannedFiles) {
    return scannedFiles.map((f) => FileItem(
      id: f.id,
      name: f.name,
      path: f.uri,
      sizeInBytes: f.size,
      extension: f.extension,
      lastModified: f.lastModified,
      category: _getCategoryFromExtension(f.extension),
    )).toList();
  }
  
  FileCategory _getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic'].contains(ext)) {
      return FileCategory.all; // Images fall under all
    } else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'].contains(ext)) {
      return FileCategory.all; // Videos fall under all
    } else if (['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a'].contains(ext)) {
      return FileCategory.all; // Audio fall under all
    } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].contains(ext)) {
      return FileCategory.all; // Documents fall under all
    } else if (['.apk', '.aab'].contains(ext)) {
      return FileCategory.all; // Apps fall under all
    } else {
      return FileCategory.all; // Others fall under all
    }
  }
  
  /// Clear cached data
  void clearCache() {
    _allFiles = null;
    _lastScanTime = null;
  }
  
  /// Clear folder selection
  void clearFolderSelection() {
    _selectedFolderUri = null;
    _selectedFolderName = null;
    clearCache();
  }
  
  /// Check if cache is valid (within 5 minutes)
  bool get isCacheValid {
    if (_lastScanTime == null || _allFiles == null) return false;
    return DateTime.now().difference(_lastScanTime!).inMinutes < 5;
  }
}

/// Result of folder selection
class FolderSelectionResult {
  final String uri;
  final String name;
  
  FolderSelectionResult({
    required this.uri,
    required this.name,
  });
}

/// Result of file scan
class FileScanResult {
  final List<ScannedFileItem> files;
  final int totalSize;
  final String? error;
  
  FileScanResult({
    required this.files,
    required this.totalSize,
    this.error,
  });
  
  bool get hasError => error != null;
  int get fileCount => files.length;
}

/// Scanned file item from SAF
class ScannedFileItem {
  final String id;
  final String name;
  final String uri;
  final int size;
  final String extension;
  final DateTime lastModified;
  final String mimeType;
  
  ScannedFileItem({
    required this.id,
    required this.name,
    required this.uri,
    required this.size,
    required this.extension,
    required this.lastModified,
    required this.mimeType,
  });
  
  factory ScannedFileItem.fromMap(Map<dynamic, dynamic> map) {
    final name = map['name'] as String? ?? 'Unknown';
    final uri = map['uri'] as String? ?? '';
    
    return ScannedFileItem(
      id: map['id'] as String? ?? uri.hashCode.toString(),
      name: name,
      uri: uri,
      size: (map['size'] as num?)?.toInt() ?? 0,
      extension: _getExtension(name),
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        (map['lastModified'] as num?)?.toInt() ?? 0,
      ),
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
    );
  }
  
  static String _getExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex).toLowerCase();
  }
}