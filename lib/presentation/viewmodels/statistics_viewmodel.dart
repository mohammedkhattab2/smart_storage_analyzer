import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_statistics_usecase.dart';
import 'package:smart_storage_analyzer/core/services/statistics_cache_service.dart';

class StatisticsViewModel {
  final GetStatisticsUseCase getStatisticsUsecase;
  StatisticsCacheService? _cacheService;
  bool _isInitialized = false;
  
  // Track ongoing computations to prevent duplicate requests
  final Map<String, Future<StorageStatistics>> _pendingRequests = {};

  StatisticsViewModel({required this.getStatisticsUsecase});
  
  /// Initialize the view model (should be called after construction)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _cacheService = await StatisticsCacheService.create();
      _isInitialized = true;
      Logger.info('Statistics cache service initialized');
    } catch (e) {
      Logger.error('Failed to initialize cache service', e);
    }
  }

  List<String> getAvailablePeriods() {
    // Return constant periods - no need to access repository for static data
    return ['This Week', 'This Month', 'This Year'];
  }

  /// Get statistics with caching to improve performance
  Future<StorageStatistics> getStatistics(String period) async {
    try {
      // Ensure initialization
      await initialize();
      
      Logger.info('Getting statistics for period: $period');
      
      // Check if we already have a pending request for this period
      if (_pendingRequests.containsKey(period)) {
        Logger.debug('Returning existing pending request for $period');
        return await _pendingRequests[period]!;
      }
      
      // Check cache first if available
      if (_cacheService != null) {
        final cachedStats = await _cacheService!.getCachedStatistics(period);
        if (cachedStats != null) {
          Logger.info('Returning cached statistics for $period');
          return cachedStats;
        }
      }
      
      // Create a new computation request
      final request = _computeStatistics(period);
      _pendingRequests[period] = request;
      
      try {
        final statistics = await request;
        
        // Cache the result for future use if cache service is available
        if (_cacheService != null) {
          await _cacheService!.cacheStatistics(period, statistics);
        }
        
        return statistics;
      } finally {
        // Remove from pending requests
        _pendingRequests.remove(period);
      }
    } catch (e) {
      Logger.error('Error getting statistics in ViewModel', e);
      rethrow;
    }
  }
  
  /// Compute statistics in background
  Future<StorageStatistics> _computeStatistics(String period) async {
    Logger.info('Computing fresh statistics for $period');
    
    // Execute the use case - heavy computation happens in repository/isolate
    final statistics = await getStatisticsUsecase.excute(period);
    
    Logger.success('Statistics computation completed for $period');
    return statistics;
  }
  
  /// Preload statistics for all periods in background
  void preloadStatistics() {
    Logger.info('Preloading statistics for all periods');
    
    for (final period in getAvailablePeriods()) {
      // Fire-and-forget preload; use onError of then to avoid returning a value
      getStatistics(period).then((_) {}, onError: (e) {
        Logger.warning('Failed to preload statistics for $period: $e');
      });
    }
  }
  
  /// Clear cached statistics
  Future<void> clearCache() async {
    Logger.info('Clearing statistics cache');
    if (_cacheService != null) {
      await _cacheService!.clearCache();
    }
    _pendingRequests.clear();
  }
  
  /// Check if statistics are cached for a period
  Future<bool> hasCache(String period) async {
    if (_cacheService != null) {
      final cached = await _cacheService!.getCachedStatistics(period);
      return cached != null;
    }
    return false;
  }
  
  void dispose() {
    _pendingRequests.clear();
    _cacheService = null;
    _isInitialized = false;
  }
}
