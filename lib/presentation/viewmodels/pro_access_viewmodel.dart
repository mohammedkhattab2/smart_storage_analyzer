import 'package:smart_storage_analyzer/core/services/feature_gate.dart';
import 'package:smart_storage_analyzer/core/services/pro_access_service.dart';
import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/domain/usecases/check_pro_feature_usecase.dart';

/// ViewModel for managing Pro access logic
/// Follows MVVM pattern - separates business logic from UI
class ProAccessViewModel {
  final ProAccessService _proAccessService;
  final FeatureGate _featureGate;
  final GetProAccessUsecase _getProAccessUsecase;
  final CheckProFeatureUsecase _checkProFeatureUsecase;
  
  ProAccessViewModel({
    required ProAccessService proAccessService,
    required FeatureGate featureGate,
    required GetProAccessUsecase getProAccessUsecase,
    required CheckProFeatureUsecase checkProFeatureUsecase,
  })  : _proAccessService = proAccessService,
        _featureGate = featureGate,
        _getProAccessUsecase = getProAccessUsecase,
        _checkProFeatureUsecase = checkProFeatureUsecase;
  
  /// Get current Pro access state
  Future<ProAccess> getProAccess() async {
    return await _getProAccessUsecase.execute();
  }
  
  /// Check if user has a specific feature
  Future<bool> hasFeature(String featureName) async {
    try {
      final feature = ProFeature.values.firstWhere(
        (f) => f.name == featureName,
      );
      return await _checkProFeatureUsecase.execute(feature);
    } catch (e) {
      return false; // Feature not found or error
    }
  }
  
  /// Get feature gate for UI checks
  FeatureGate get featureGate => _featureGate;
  
  /// Check if user is Pro
  Future<bool> isProUser() async {
    return await _proAccessService.isProUser();
  }
  
  /// Get list of all Pro features with their status
  Future<Map<ProFeature, bool>> getAllFeaturesStatus() async {
    final features = ProFeature.values;
    return await _proAccessService.checkFeatures(features);
  }
  
  /// Refresh Pro access state
  Future<void> refreshProAccess() async {
    await _proAccessService.refreshProAccess();
  }
  
  /// Get feature information
  ProFeatureInfo getFeatureInfo(ProFeature feature) {
    return ProAccessService.getFeatureInfo(feature);
  }
  
  /// Get all Pro features info
  List<ProFeatureInfo> getAllFeaturesInfo() {
    return ProFeature.values
        .map((feature) => ProAccessService.getFeatureInfo(feature))
        .toList();
  }
}