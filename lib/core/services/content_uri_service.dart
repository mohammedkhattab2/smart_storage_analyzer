import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling Android content URIs
/// Provides methods to read content URIs, get file info, and open files
class ContentUriService {
  static const _channel = MethodChannel('com.smarttools.storageanalyzer/native');
  
  /// Check if a path is a content URI
  static bool isContentUri(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('content://');
  }
  
  /// Read bytes from a content URI
  /// Returns null if the URI cannot be read
  static Future<Uint8List?> readContentUriBytes(String uri) async {
    try {
      if (!isContentUri(uri)) {
        // For regular file paths, read directly
        return null;
      }
      
      final String? base64Data = await _channel.invokeMethod('readContentUri', {
        'uri': uri,
      });
      
      if (base64Data != null) {
        return base64Decode(base64Data);
      }
      return null;
    } catch (e) {
      developer.log('Error reading content URI: $e', name: 'ContentUriService');
      return null;
    }
  }
  
  /// Get information about a content URI
  /// Returns a map with name, size, mimeType, and uri
  static Future<Map<String, dynamic>?> getContentUriInfo(String uri) async {
    try {
      if (!isContentUri(uri)) {
        return null;
      }
      
      final result = await _channel.invokeMethod('getContentUriInfo', {
        'uri': uri,
      });
      
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      developer.log('Error getting content URI info: $e', name: 'ContentUriService');
      return null;
    }
  }
  
  /// Open a content URI with the system default app
  /// This is used as a fallback when in-app viewing fails
  static Future<bool> openContentUri(String uri, {String? mimeType}) async {
    try {
      if (!isContentUri(uri)) {
        return false;
      }
      
      developer.log('Opening URI: $uri with mimeType: $mimeType', name: 'ContentUriService');
      
      final bool success = await _channel.invokeMethod('openContentUri', {
        'uri': uri,
        'mimeType': mimeType,
      });
      
      developer.log('Result: $success', name: 'ContentUriService');
      return success;
    } catch (e) {
      developer.log('Error opening content URI: $e', name: 'ContentUriService');
      return false;
    }
  }
  
  /// Convert a content URI to a file path if possible
  /// Note: This may not always work on Android Q+ due to scoped storage
  static Future<String?> getPathFromContentUri(String uri) async {
    try {
      if (!isContentUri(uri)) {
        return uri; // Return as-is if not a content URI
      }
      
      // Try to get info and extract path if available
      final info = await getContentUriInfo(uri);
      if (info != null && info['path'] != null) {
        return info['path'];
      }
      
      // Path not available, return null
      return null;
    } catch (e) {
      developer.log('Error getting path from content URI: $e', name: 'ContentUriService');
      return null;
    }
  }
  
  /// Create a temporary file from content URI bytes
  /// Useful for packages that don't support content URIs directly
  static Future<String?> createTempFileFromContentUri(String uri, String fileName) async {
    try {
      if (!isContentUri(uri)) {
        return uri; // Return as-is if not a content URI
      }
      
      final bytes = await readContentUriBytes(uri);
      if (bytes == null) {
        return null;
      }
      
      // Create a temporary file with the provided bytes
      final tempDir = await getTemporaryDirectory();
      
      // Ensure the file name has a proper extension
      String tempFileName = fileName;
      if (!fileName.contains('.')) {
        // If no extension, try to determine from content URI info
        final info = await getContentUriInfo(uri);
        if (info != null && info['mimeType'] != null) {
          final extension = _getExtensionFromMimeType(info['mimeType']);
          if (extension != null) {
            tempFileName = '$fileName$extension';
          }
        }
      }
      
      // Create a unique file name to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$tempFileName';
      final tempFile = File(path.join(tempDir.path, uniqueFileName));
      
      // Write bytes to the temp file
      await tempFile.writeAsBytes(bytes);
      
      developer.log('Created temp file: ${tempFile.path}', name: 'ContentUriService');
      return tempFile.path;
    } catch (e) {
      developer.log('Error creating temp file from content URI: $e', name: 'ContentUriService');
      return null;
    }
  }
  
  /// Helper method to get file extension from mime type
  static String? _getExtensionFromMimeType(String mimeType) {
    final mimeTypeMap = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'image/bmp': '.bmp',
      'video/mp4': '.mp4',
      'video/x-msvideo': '.avi',
      'video/quicktime': '.mov',
      'video/x-matroska': '.mkv',
      'video/webm': '.webm',
      'video/3gpp': '.3gp',
      'audio/mpeg': '.mp3',
      'audio/wav': '.wav',
      'audio/flac': '.flac',
      'audio/aac': '.aac',
      'audio/ogg': '.ogg',
      'audio/mp4': '.m4a',
      'application/pdf': '.pdf',
      'application/msword': '.doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
      'application/vnd.ms-excel': '.xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '.xlsx',
      'application/vnd.ms-powerpoint': '.ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': '.pptx',
      'text/plain': '.txt',
      'application/rtf': '.rtf',
      'text/html': '.html',
      'application/xml': '.xml',
      'application/json': '.json',
      'text/csv': '.csv',
      'application/zip': '.zip',
      'application/x-rar-compressed': '.rar',
      'application/x-7z-compressed': '.7z',
      'application/x-tar': '.tar',
      'application/gzip': '.gz',
    };
    
    return mimeTypeMap[mimeType.toLowerCase()];
  }
}