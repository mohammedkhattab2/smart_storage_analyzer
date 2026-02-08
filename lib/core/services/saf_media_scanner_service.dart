import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Model for scanned media file
class ScannedMediaFile {
  final String id;
  final String name;
  final String path;
  final String uri;
  final int size;
  final int lastModified;
  final String extension;
  final String mimeType;
  final String mediaType;
  final bool canRead;

  ScannedMediaFile({
    required this.id,
    required this.name,
    required this.path,
    required this.uri,
    required this.size,
    required this.lastModified,
    required this.extension,
    required this.mimeType,
    required this.mediaType,
    required this.canRead,
  });

  factory ScannedMediaFile.fromMap(Map<String, dynamic> map) {
    return ScannedMediaFile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      uri: map['uri']?.toString() ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      lastModified: (map['lastModified'] as num?)?.toInt() ?? 0,
      extension: map['extension']?.toString() ?? '',
      mimeType: map['mimeType']?.toString() ?? '',
      mediaType: map['mediaType']?.toString() ?? '',
      canRead: map['canRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'size': size,
      'lastModified': lastModified,
      'extension': extension,
      'mimeType': mimeType,
      'mediaType': mediaType,
      'canRead': canRead,
    };
  }
}

/// Result of media folder selection
class MediaFolderSelection {
  final String uri;
  final String name;
  final String mediaType;
  final bool canRead;

  MediaFolderSelection({
    required this.uri,
    required this.name,
    required this.mediaType,
    required this.canRead,
  });

  factory MediaFolderSelection.fromMap(Map<String, dynamic> map) {
    return MediaFolderSelection(
      uri: map['uri']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mediaType: map['mediaType']?.toString() ?? '',
      canRead: map['canRead'] as bool? ?? false,
    );
  }
}

/// Result of media folder scan
class MediaScanResult {
  final List<ScannedMediaFile> files;
  final int totalSize;
  final int fileCount;
  final String mediaType;
  final String folderUri;

  MediaScanResult({
    required this.files,
    required this.totalSize,
    required this.fileCount,
    required this.mediaType,
    required this.folderUri,
  });

  factory MediaScanResult.fromMap(Map<String, dynamic> map) {
    final filesList = (map['files'] as List<dynamic>?)
            ?.map((f) => ScannedMediaFile.fromMap(Map<String, dynamic>.from(f)))
            .toList() ??
        [];

    return MediaScanResult(
      files: filesList,
      totalSize: (map['totalSize'] as num?)?.toInt() ?? 0,
      fileCount: (map['fileCount'] as num?)?.toInt() ?? 0,
      mediaType: map['mediaType']?.toString() ?? '',
      folderUri: map['folderUri']?.toString() ?? '',
    );
  }
}

/// Persisted media URI info
class PersistedMediaUri {
  final String uri;
  final String name;
  final String mediaType;
  final bool isValid;

  PersistedMediaUri({
    required this.uri,
    required this.name,
    required this.mediaType,
    required this.isValid,
  });

  factory PersistedMediaUri.fromMap(Map<String, dynamic> map) {
    return PersistedMediaUri(
      uri: map['uri']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mediaType: map['mediaType']?.toString() ?? '',
      isValid: map['isValid'] as bool? ?? false,
    );
  }
}

/// Media type enum for type safety
enum MediaType {
  images,
  videos,
  audio,
}

extension MediaTypeExtension on MediaType {
  String get value {
    switch (this) {
      case MediaType.images:
        return 'images';
      case MediaType.videos:
        return 'videos';
      case MediaType.audio:
        return 'audio';
    }
  }

  static MediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'images':
      case 'image':
        return MediaType.images;
      case 'videos':
      case 'video':
        return MediaType.videos;
      case 'audio':
      case 'music':
        return MediaType.audio;
      default:
        return MediaType.images;
    }
  }
}

/// Service for SAF-based media scanning.
/// 
/// This service provides policy-compliant media file access using
/// Storage Access Framework (SAF). It does NOT require any media
/// permissions (READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, READ_MEDIA_AUDIO).
/// 
/// Usage:
/// 1. Call [selectMediaFolder] to let user pick a folder
/// 2. Call [scanMediaFolder] to scan the selected folder
/// 3. Use [getPersistedMediaUri] to check for previously selected folders
class SafMediaScannerService {
  static const _channel = MethodChannel('com.smarttools.storageanalyzer/native');

  /// Singleton instance
  static final SafMediaScannerService _instance = SafMediaScannerService._internal();
  factory SafMediaScannerService() => _instance;
  SafMediaScannerService._internal();

  /// Open folder picker for media type selection.
  /// 
  /// Returns [MediaFolderSelection] if user selects a folder, null if cancelled.
  /// The selected folder URI is automatically persisted for future use.
  Future<MediaFolderSelection?> selectMediaFolder(MediaType mediaType) async {
    try {
      Logger.info('[SafMediaScanner] Opening folder picker for ${mediaType.value}');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'selectMediaFolder',
        {'mediaType': mediaType.value},
      );

      if (result == null) {
        Logger.info('[SafMediaScanner] User cancelled folder selection');
        return null;
      }

      final selection = MediaFolderSelection.fromMap(Map<String, dynamic>.from(result));
      Logger.success('[SafMediaScanner] Folder selected: ${selection.name}');
      return selection;
    } on PlatformException catch (e) {
      Logger.error('[SafMediaScanner] Error selecting folder: ${e.message}', e);
      rethrow;
    } catch (e) {
      Logger.error('[SafMediaScanner] Unexpected error selecting folder', e);
      rethrow;
    }
  }

  /// Scan a media folder for files of the specified type.
  /// 
  /// [uri] - The content URI of the folder to scan (from [selectMediaFolder])
  /// [mediaType] - The type of media to scan for
  /// 
  /// Returns [MediaScanResult] with all found files and statistics.
  Future<MediaScanResult> scanMediaFolder(String uri, MediaType mediaType) async {
    try {
      Logger.info('[SafMediaScanner] Scanning ${mediaType.value} folder: $uri');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'scanMediaFolder',
        {
          'uri': uri,
          'mediaType': mediaType.value,
        },
      );

      if (result == null) {
        throw PlatformException(
          code: 'SCAN_ERROR',
          message: 'Scan returned null result',
        );
      }

      final scanResult = MediaScanResult.fromMap(Map<String, dynamic>.from(result));
      Logger.success(
        '[SafMediaScanner] Scan complete: ${scanResult.fileCount} files, '
        '${_formatBytes(scanResult.totalSize)}',
      );
      return scanResult;
    } on PlatformException catch (e) {
      Logger.error('[SafMediaScanner] Error scanning folder: ${e.message}', e);
      rethrow;
    } catch (e) {
      Logger.error('[SafMediaScanner] Unexpected error scanning folder', e);
      rethrow;
    }
  }

  /// Get persisted URI for a media type.
  /// 
  /// Returns [PersistedMediaUri] if a valid URI exists, null otherwise.
  /// The URI is validated to ensure it still has permission.
  Future<PersistedMediaUri?> getPersistedMediaUri(MediaType mediaType) async {
    try {
      Logger.debug('[SafMediaScanner] Getting persisted URI for ${mediaType.value}');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getPersistedMediaUri',
        {'mediaType': mediaType.value},
      );

      if (result == null) {
        Logger.debug('[SafMediaScanner] No persisted URI for ${mediaType.value}');
        return null;
      }

      final persistedUri = PersistedMediaUri.fromMap(Map<String, dynamic>.from(result));
      Logger.debug('[SafMediaScanner] Found persisted URI: ${persistedUri.name}');
      return persistedUri;
    } on PlatformException catch (e) {
      Logger.error('[SafMediaScanner] Error getting persisted URI: ${e.message}', e);
      return null;
    } catch (e) {
      Logger.error('[SafMediaScanner] Unexpected error getting persisted URI', e);
      return null;
    }
  }

  /// Clear persisted URI for a media type.
  /// 
  /// This also releases the URI permission.
  Future<bool> clearPersistedMediaUri(MediaType mediaType) async {
    try {
      Logger.info('[SafMediaScanner] Clearing persisted URI for ${mediaType.value}');
      
      final result = await _channel.invokeMethod<bool>(
        'clearPersistedMediaUri',
        {'mediaType': mediaType.value},
      );

      Logger.success('[SafMediaScanner] Cleared persisted URI for ${mediaType.value}');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('[SafMediaScanner] Error clearing persisted URI: ${e.message}', e);
      return false;
    } catch (e) {
      Logger.error('[SafMediaScanner] Unexpected error clearing persisted URI', e);
      return false;
    }
  }

  /// Validate if a URI is still accessible.
  /// 
  /// Returns true if the URI has valid permission and the folder exists.
  Future<bool> validateMediaUri(String uri) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'validateMediaUri',
        {'uri': uri},
      );

      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('[SafMediaScanner] Error validating URI: ${e.message}', e);
      return false;
    } catch (e) {
      Logger.error('[SafMediaScanner] Unexpected error validating URI', e);
      return false;
    }
  }

  /// Check if a media type has a persisted folder selection.
  Future<bool> hasPersistedFolder(MediaType mediaType) async {
    final persistedUri = await getPersistedMediaUri(mediaType);
    return persistedUri != null && persistedUri.isValid;
  }

  /// Select folder and scan in one operation.
  /// 
  /// Convenience method that combines [selectMediaFolder] and [scanMediaFolder].
  /// Returns null if user cancels folder selection.
  Future<MediaScanResult?> selectAndScanFolder(MediaType mediaType) async {
    final selection = await selectMediaFolder(mediaType);
    if (selection == null) return null;

    return scanMediaFolder(selection.uri, mediaType);
  }

  /// Scan using persisted folder if available, otherwise prompt for selection.
  /// 
  /// Returns null if no persisted folder and user cancels selection.
  Future<MediaScanResult?> scanWithPersistedOrSelect(MediaType mediaType) async {
    // Check for persisted URI first
    final persistedUri = await getPersistedMediaUri(mediaType);
    
    if (persistedUri != null && persistedUri.isValid) {
      Logger.info('[SafMediaScanner] Using persisted folder: ${persistedUri.name}');
      return scanMediaFolder(persistedUri.uri, mediaType);
    }

    // No persisted URI, prompt for selection
    Logger.info('[SafMediaScanner] No persisted folder, prompting for selection');
    return selectAndScanFolder(mediaType);
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}