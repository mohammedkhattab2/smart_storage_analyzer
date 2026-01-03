import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/domain/repositories/pro_access_repository.dart';

/// Service that manages Pro access state
/// This is the single source of truth for Pro features
class ProAccessService {
  final ProAccessRepository _repository;
  
  // Cached Pro access state
  ProAccess? _cachedProAccess;
  
  ProAccessService({required ProAccessRepository repository})
      : _repository = repository;
  
  /// Get current Pro access state
  Future<ProAccess> getProAccess() async {
    // Return cached value if available
    if (_cachedProAccess != null) {
      return _cachedProAccess!;
    }
    
    try {
      _cachedProAccess = await _repository.getProAccess();
      Logger.debug('Pro access loaded: ${_cachedProAccess!.accessType}');
      return _cachedProAccess!;
    } catch (e) {
      Logger.error('Failed to load Pro access', e);
      // Return free access on error
      _cachedProAccess = ProAccess.free();
      return _cachedProAccess!;
    }
  }
  
  /// Check if user is Pro
  Future<bool> isProUser() async {
    final access = await getProAccess();
    return access.isProUser;
  }
  
  /// Check if user has specific feature
  Future<bool> hasFeature(ProFeature feature) async {
    final access = await getProAccess();
    return access.hasFeature(feature);
  }
  
  /// Check multiple features at once
  Future<Map<ProFeature, bool>> checkFeatures(List<ProFeature> features) async {
    final access = await getProAccess();
    return Map.fromEntries(
      features.map((feature) => MapEntry(feature, access.hasFeature(feature))),
    );
  }
  
  /// Refresh Pro access (clears cache)
  Future<void> refreshProAccess() async {
    _cachedProAccess = null;
    await getProAccess();
  }
  
  /// Get Pro feature info
  static ProFeatureInfo getFeatureInfo(ProFeature feature) {
    switch (feature) {
      case ProFeature.deepAnalysis:
        return ProFeatureInfo(
          name: 'Deep Analysis',
          description: 'Advanced file system analysis with detailed insights',
          icon: 'analytics',
        );
      case ProFeature.autoCleanup:
        return ProFeatureInfo(
          name: 'Auto Cleanup',
          description: 'Automatically clean junk files on schedule',
          icon: 'auto_delete',
        );
      case ProFeature.cloudBackup:
        return ProFeatureInfo(
          name: 'Cloud Backup',
          description: 'Backup your files to cloud storage',
          icon: 'cloud_upload',
        );
      case ProFeature.batchOperations:
        return ProFeatureInfo(
          name: 'Batch Operations',
          description: 'Process multiple files at once',
          icon: 'library_add',
        );
      case ProFeature.advancedFilters:
        return ProFeatureInfo(
          name: 'Advanced Filters',
          description: 'Filter files by date, size, and custom rules',
          icon: 'filter_alt',
        );
      case ProFeature.duplicateFinder:
        return ProFeatureInfo(
          name: 'Duplicate Finder',
          description: 'Find and remove duplicate files',
          icon: 'find_in_page',
        );
      case ProFeature.customThemes:
        return ProFeatureInfo(
          name: 'Custom Themes',
          description: 'Personalize app with custom themes',
          icon: 'palette',
        );
      case ProFeature.advancedStatistics:
        return ProFeatureInfo(
          name: 'Advanced Statistics',
          description: 'Detailed storage usage analytics',
          icon: 'insights',
        );
      case ProFeature.exportReports:
        return ProFeatureInfo(
          name: 'Export Reports',
          description: 'Export storage reports as PDF/CSV',
          icon: 'download',
        );
    }
  }
}

/// Information about a Pro feature
class ProFeatureInfo {
  final String name;
  final String description;
  final String icon;
  
  const ProFeatureInfo({
    required this.name,
    required this.description,
    required this.icon,
  });
}