import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Cached scan result for a media type
class CachedMediaScanResult {
  final MediaScanResult result;
  final String folderName;
  final String folderUri;
  final DateTime cachedAt;

  CachedMediaScanResult({
    required this.result,
    required this.folderName,
    required this.folderUri,
    required this.cachedAt,
  });

  /// Check if cache is still valid (within 5 minutes)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(cachedAt);
    return difference.inMinutes < 5;
  }
}

/// Service to cache media scan results to avoid re-scanning on navigation
class MediaScanCacheService {
  static final MediaScanCacheService _instance = MediaScanCacheService._internal();
  factory MediaScanCacheService() => _instance;
  MediaScanCacheService._internal();

  final Map<MediaType, CachedMediaScanResult> _cache = {};

  /// Get cached result for a media type
  CachedMediaScanResult? getCachedResult(MediaType mediaType) {
    final cached = _cache[mediaType];
    if (cached != null && cached.isValid) {
      Logger.debug('[MediaScanCache] Cache hit for ${mediaType.value}');
      return cached;
    }
    if (cached != null && !cached.isValid) {
      Logger.debug('[MediaScanCache] Cache expired for ${mediaType.value}');
      _cache.remove(mediaType);
    }
    return null;
  }

  /// Cache a scan result
  void cacheResult(
    MediaType mediaType,
    MediaScanResult result,
    String folderName,
    String folderUri,
  ) {
    Logger.debug('[MediaScanCache] Caching result for ${mediaType.value}: ${result.fileCount} files');
    _cache[mediaType] = CachedMediaScanResult(
      result: result,
      folderName: folderName,
      folderUri: folderUri,
      cachedAt: DateTime.now(),
    );
  }

  /// Clear cache for a specific media type
  void clearCache(MediaType mediaType) {
    Logger.debug('[MediaScanCache] Clearing cache for ${mediaType.value}');
    _cache.remove(mediaType);
  }

  /// Clear all cached results
  void clearAllCache() {
    Logger.debug('[MediaScanCache] Clearing all cache');
    _cache.clear();
  }

  /// Check if we have a valid cached result
  bool hasCachedResult(MediaType mediaType) {
    final cached = _cache[mediaType];
    return cached != null && cached.isValid;
  }
  
  /// Check if any media cache exists and is valid
  bool hasAnyValidCache() {
    for (final entry in _cache.entries) {
      if (entry.value.isValid) {
        return true;
      }
    }
    return false;
  }
  
  /// Get the latest cache timestamp across all media types
  /// Returns null if no valid cache exists
  DateTime? getLatestCacheTimestamp() {
    DateTime? latest;
    for (final entry in _cache.entries) {
      if (entry.value.isValid) {
        if (latest == null || entry.value.cachedAt.isAfter(latest)) {
          latest = entry.value.cachedAt;
        }
      }
    }
    return latest;
  }
  
  /// Check if media cache is newer than a given timestamp
  bool hasNewerCacheThan(DateTime? timestamp) {
    if (timestamp == null) return hasAnyValidCache();
    final latestMediaCache = getLatestCacheTimestamp();
    if (latestMediaCache == null) return false;
    return latestMediaCache.isAfter(timestamp);
  }
}