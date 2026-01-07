import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/channel_constants.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service to communicate with native Android storage APIs
/// Follows MVVM architecture - no direct UI interaction
class NativeStorageService {
  static const _channel = MethodChannel(ChannelConstants.storageChannel);

  /// Singleton pattern for service
  static final NativeStorageService _instance =
      NativeStorageService._internal();
  factory NativeStorageService() => _instance;
  NativeStorageService._internal();

  /// Get total storage space in bytes from native Android
  /// Returns 0 if unable to fetch
  Future<int> getTotalStorageBytes() async {
    try {
      final int totalBytes = await _channel.invokeMethod('getTotalStorage');
      return totalBytes;
    } on PlatformException catch (e) {
      Logger.error('Error getting total storage: ${e.message}');
      return 0;
    } catch (e) {
      Logger.error('Unexpected error getting total storage', e);
      return 0;
    }
  }

  /// Get free storage space in bytes from native Android
  /// Returns 0 if unable to fetch
  Future<int> getFreeStorageBytes() async {
    try {
      final int freeBytes = await _channel.invokeMethod('getFreeStorage');
      return freeBytes;
    } on PlatformException catch (e) {
      Logger.error('Error getting free storage: ${e.message}');
      return 0;
    } catch (e) {
      Logger.error('Unexpected error getting free storage', e);
      return 0;
    }
  }

  /// Get used storage space in bytes from native Android
  /// Returns 0 if unable to fetch
  Future<int> getUsedStorageBytes() async {
    try {
      final int usedBytes = await _channel.invokeMethod('getUsedStorage');
      return usedBytes;
    } on PlatformException catch (e) {
      Logger.error('Error getting used storage: ${e.message}');
      return 0;
    } catch (e) {
      Logger.error('Unexpected error getting used storage', e);
      return 0;
    }
  }

  /// Get all storage information at once
  /// More efficient than calling individual methods
  Future<StorageData> getStorageData() async {
    try {
      // Call all methods in parallel for better performance
      final results = await Future.wait([
        getTotalStorageBytes(),
        getFreeStorageBytes(),
        getUsedStorageBytes(),
      ]);

      return StorageData(
        totalBytes: results[0],
        freeBytes: results[1],
        usedBytes: results[2],
      );
    } catch (e) {
      Logger.error('Error getting storage data', e);
      // Return default values on error
      return StorageData(totalBytes: 0, freeBytes: 0, usedBytes: 0);
    }
  }

  /// Convert bytes to GB with proper decimal places
  static double bytesToGB(int bytes) {
    if (bytes <= 0) return 0.0;
    return bytes / (1024 * 1024 * 1024); // bytes to GB
  }

  /// Format bytes to readable GB string
  static String formatBytesToGB(int bytes, {int decimals = 2}) {
    final gb = bytesToGB(bytes);
    return gb.toStringAsFixed(decimals);
  }
}

/// Data class to hold storage information
class StorageData {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  const StorageData({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  /// Get total storage in GB
  double get totalGB => NativeStorageService.bytesToGB(totalBytes);

  /// Get free storage in GB
  double get freeGB => NativeStorageService.bytesToGB(freeBytes);

  /// Get used storage in GB
  double get usedGB => NativeStorageService.bytesToGB(usedBytes);

  /// Get used percentage (0-1)
  double get usedPercentage {
    if (totalBytes <= 0) return 0.0;
    return usedBytes / totalBytes;
  }

  /// Get free percentage (0-1)
  double get freePercentage {
    if (totalBytes <= 0) return 0.0;
    return freeBytes / totalBytes;
  }

  @override
  String toString() {
    return 'StorageData(total: ${totalGB.toStringAsFixed(2)}GB, '
        'used: ${usedGB.toStringAsFixed(2)}GB, '
        'free: ${freeGB.toStringAsFixed(2)}GB)';
  }
}
