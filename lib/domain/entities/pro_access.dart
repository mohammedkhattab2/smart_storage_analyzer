/// Entity representing Pro access state
/// This is the core domain model for Pro features
class ProAccess {
  final bool isProUser;
  final DateTime? proExpiryDate;
  final ProAccessType accessType;
  final List<ProFeature> enabledFeatures;

  const ProAccess({
    required this.isProUser,
    this.proExpiryDate,
    required this.accessType,
    required this.enabledFeatures,
  });

  /// Default free user state
  factory ProAccess.free() => const ProAccess(
        isProUser: false,
        accessType: ProAccessType.free,
        enabledFeatures: [],
      );

  bool hasFeature(ProFeature feature) => enabledFeatures.contains(feature);
}

/// Type of Pro access (for future expansion)
enum ProAccessType {
  free,
  pro,
  // Future: trial, lifetime, etc.
}

/// Available Pro features
enum ProFeature {
  // Storage features
  deepAnalysis,
  autoCleanup,
  cloudBackup,
  
  // File features
  batchOperations,
  advancedFilters,
  duplicateFinder,
  
  // UI features
  customThemes,
  advancedStatistics,
  exportReports,
}