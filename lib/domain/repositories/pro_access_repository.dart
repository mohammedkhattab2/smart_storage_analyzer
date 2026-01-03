import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';

/// Repository interface for Pro access management
/// This will be implemented in the data layer
abstract class ProAccessRepository {
  /// Get current Pro access state
  Future<ProAccess> getProAccess();
  
  /// Check if user has specific feature
  Future<bool> hasFeature(ProFeature feature);
  
  /// Save Pro access state (for future use)
  Future<void> saveProAccess(ProAccess proAccess);
  
  /// Clear Pro access (reset to free)
  Future<void> clearProAccess();
  
  /// Validate Pro access (for future server validation)
  Future<bool> validateProAccess();
}