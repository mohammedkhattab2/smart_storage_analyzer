import 'dart:io';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

class FileOperationsService {
  static const platform = MethodChannel(ChannelConstants.mainChannel);

  /// Open a file using native file viewer
  Future<bool> openFile(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        Logger.warning('File operations are only supported on Android');
        return false;
      }

      final result = await platform.invokeMethod<bool>('openFile', {
        'path': filePath,
      });

      return result ?? false;
    } catch (e) {
      Logger.error('Failed to open file: $e');
      return false;
    }
  }

  /// Share a single file using native share sheet
  Future<bool> shareFile(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        Logger.warning('File operations are only supported on Android');
        return false;
      }

      final result = await platform.invokeMethod<bool>('shareFile', {
        'path': filePath,
      });

      return result ?? false;
    } catch (e) {
      Logger.error('Failed to share file: $e');
      return false;
    }
  }

  /// Share multiple files using native share sheet
  Future<bool> shareFiles(List<String> filePaths) async {
    try {
      if (!Platform.isAndroid) {
        Logger.warning('File operations are only supported on Android');
        return false;
      }

      if (filePaths.isEmpty) {
        Logger.warning('No files to share');
        return false;
      }

      final result = await platform.invokeMethod<bool>('shareFiles', {
        'paths': filePaths,
      });

      return result ?? false;
    } catch (e) {
      Logger.error('Failed to share files: $e');
      return false;
    }
  }
}
