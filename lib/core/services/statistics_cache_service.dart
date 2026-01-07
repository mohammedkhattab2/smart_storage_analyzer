import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/data/models/statistics_model.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Service to cache statistics data for better performance
class StatisticsCacheService {
  static const String _cacheKeyPrefix = 'statistics_cache_';
  static const String _cacheTimestampPrefix = 'statistics_timestamp_';
  static const Duration _cacheValidityDuration = Duration(minutes: 30);
  
  final SharedPreferences _prefs;
  
  StatisticsCacheService._(this._prefs);
  
  /// Create an instance of the cache service
  static Future<StatisticsCacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StatisticsCacheService._(prefs);
  }
  
  /// Get cached statistics for a given period
  Future<StorageStatistics?> getCachedStatistics(String period) async {
    try {
      final cacheKey = '$_cacheKeyPrefix$period';
      final timestampKey = '$_cacheTimestampPrefix$period';
      
      // Check if cache exists
      final cachedJson = _prefs.getString(cacheKey);
      final timestampMs = _prefs.getInt(timestampKey);
      
      if (cachedJson == null || timestampMs == null) {
        return null;
      }
      
      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      final now = DateTime.now();
      if (now.difference(cacheTime) > _cacheValidityDuration) {
        Logger.debug('Statistics cache expired for period: $period');
        // Clear expired cache
        await _prefs.remove(cacheKey);
        await _prefs.remove(timestampKey);
        return null;
      }
      
      // Parse and return cached data
      final Map<String, dynamic> jsonData = json.decode(cachedJson);
      return _parseStatisticsFromJson(jsonData);
    } catch (e) {
      Logger.error('Error reading statistics cache for period: $period', e);
      return null;
    }
  }
  
  /// Cache statistics data for a given period
  Future<void> cacheStatistics(String period, StorageStatistics statistics) async {
    try {
      final cacheKey = '$_cacheKeyPrefix$period';
      final timestampKey = '$_cacheTimestampPrefix$period';
      
      // Convert to JSON
      final jsonData = _statisticsToJson(statistics);
      final jsonString = json.encode(jsonData);
      
      // Save to cache
      await _prefs.setString(cacheKey, jsonString);
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      Logger.debug('Statistics cached for period: $period');
    } catch (e) {
      Logger.error('Error caching statistics for period: $period', e);
    }
  }
  
  /// Clear all statistics cache
  Future<void> clearCache() async {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cacheKeyPrefix) || key.startsWith(_cacheTimestampPrefix)
      );
      
      for (final key in cacheKeys) {
        await _prefs.remove(key);
      }
      
      Logger.info('Statistics cache cleared');
    } catch (e) {
      Logger.error('Error clearing statistics cache', e);
    }
  }
  
  /// Clear cache for a specific period
  Future<void> clearCacheForPeriod(String period) async {
    try {
      final cacheKey = '$_cacheKeyPrefix$period';
      final timestampKey = '$_cacheTimestampPrefix$period';
      
      await _prefs.remove(cacheKey);
      await _prefs.remove(timestampKey);
      
      Logger.debug('Statistics cache cleared for period: $period');
    } catch (e) {
      Logger.error('Error clearing statistics cache for period: $period', e);
    }
  }
  
  /// Convert statistics to JSON for caching
  Map<String, dynamic> _statisticsToJson(StorageStatistics statistics) {
    return {
      'period': statistics.period,
      'currentFreeSpace': statistics.currentFreeSpace,
      'totalSpace': statistics.totalSpace,
      'dataPoints': statistics.dataPoints.map((point) => {
        'date': point.date.toIso8601String(),
        'usedSpace': point.usedSpace,
        'freeSpace': point.freeSpace,
      }).toList(),
      'categoryBreakdown': statistics.categoryBreakdown.map((category) => {
        'id': category.id,
        'name': category.name,
        'sizeInBytes': category.sizeInBytes,
        'fileCount': category.fileCount,
      }).toList(),
    };
  }
  
  /// Parse statistics from JSON
  StorageStatistics _parseStatisticsFromJson(Map<String, dynamic> json) {
    final dataPoints = (json['dataPoints'] as List).map((pointData) {
      return StorageDataPointModel(
        date: DateTime.parse(pointData['date']),
        usedSpace: pointData['usedSpace'].toDouble(),
        freeSpace: pointData['freeSpace'].toDouble(),
      );
    }).toList();
    
    // Note: Categories are simplified here, full reconstruction might need more data
    final categories = <Category>[];
    
    return StorageStatisticsModel(
      period: json['period'],
      currentFreeSpace: json['currentFreeSpace'].toDouble(),
      totalSpace: json['totalSpace'].toDouble(),
      dataPoints: dataPoints,
      categoryBreakdown: categories,
    );
  }
}

/// Cache manager for periodic cleanup
class CacheManager {
  static Timer? _cleanupTimer;
  
  /// Start periodic cache cleanup
  static void startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        Logger.debug('Running periodic cache cleanup...');
        final cacheService = await StatisticsCacheService.create();
        
        // Get all cache keys and remove expired ones
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        final timestampKeys = keys.where(
          (key) => key.startsWith(StatisticsCacheService._cacheTimestampPrefix),
        );
        
        for (final timestampKey in timestampKeys) {
          final timestampMs = prefs.getInt(timestampKey);
          if (timestampMs != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
            if (DateTime.now().difference(cacheTime) > 
                StatisticsCacheService._cacheValidityDuration) {
              // Extract period from timestamp key
              final period = timestampKey.replaceFirst(
                StatisticsCacheService._cacheTimestampPrefix, 
                '',
              );
              await cacheService.clearCacheForPeriod(period);
            }
          }
        }
        
        Logger.debug('Periodic cache cleanup completed');
      } catch (e) {
        Logger.error('Error in periodic cache cleanup', e);
      }
    });
  }
  
  /// Stop periodic cache cleanup
  static void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}