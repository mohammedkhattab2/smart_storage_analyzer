import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/pro_access_model.dart';
import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/domain/repositories/pro_access_repository.dart';

/// Implementation of ProAccessRepository
/// Currently stores locally, ready for future server integration
class ProAccessRepositoryImpl implements ProAccessRepository {
  static const String _proAccessKey = 'pro_access_data';
  static const String _proAccessValidatedKey = 'pro_access_validated';

  @override
  Future<ProAccess> getProAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_proAccessKey);

      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString),
        );
        return ProAccessModel.fromJson(json);
      }

      // Return default free access
      return ProAccessModel.defaultFree();
    } catch (e) {
      Logger.error('Failed to get Pro access', e);
      return ProAccessModel.defaultFree();
    }
  }

  @override
  Future<bool> hasFeature(ProFeature feature) async {
    final proAccess = await getProAccess();
    return proAccess.hasFeature(feature);
  }

  @override
  Future<void> saveProAccess(ProAccess proAccess) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final model = ProAccessModel.fromEntity(proAccess);
      final jsonString = Uri(
        queryParameters: model.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ).query;

      await prefs.setString(_proAccessKey, jsonString);
      Logger.info('Pro access saved successfully');
    } catch (e) {
      Logger.error('Failed to save Pro access', e);
    }
  }

  @override
  Future<void> clearProAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_proAccessKey);
      await prefs.remove(_proAccessValidatedKey);
      Logger.info('Pro access cleared');
    } catch (e) {
      Logger.error('Failed to clear Pro access', e);
    }
  }

  @override
  Future<bool> validateProAccess() async {
    try {
      // For now, just check if Pro access exists
      // In future, this would validate with server
      final proAccess = await getProAccess();

      if (!proAccess.isProUser) {
        return true; // Free users are always valid
      }

      // Check expiry date if exists
      if (proAccess.proExpiryDate != null) {
        return proAccess.proExpiryDate!.isAfter(DateTime.now());
      }

      // Mark as validated locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proAccessValidatedKey, true);

      return true;
    } catch (e) {
      Logger.error('Failed to validate Pro access', e);
      return false;
    }
  }
}
