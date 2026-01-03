import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';

/// Data model for ProAccess with JSON serialization
class ProAccessModel extends ProAccess {
  const ProAccessModel({
    required super.isProUser,
    super.proExpiryDate,
    required super.accessType,
    required super.enabledFeatures,
  });

  /// Create from domain entity
  factory ProAccessModel.fromEntity(ProAccess entity) {
    return ProAccessModel(
      isProUser: entity.isProUser,
      proExpiryDate: entity.proExpiryDate,
      accessType: entity.accessType,
      enabledFeatures: entity.enabledFeatures,
    );
  }

  /// Create from JSON (for future server response)
  factory ProAccessModel.fromJson(Map<String, dynamic> json) {
    return ProAccessModel(
      isProUser: json['isProUser'] ?? false,
      proExpiryDate: json['proExpiryDate'] != null 
          ? DateTime.parse(json['proExpiryDate']) 
          : null,
      accessType: ProAccessType.values.firstWhere(
        (type) => type.name == json['accessType'],
        orElse: () => ProAccessType.free,
      ),
      enabledFeatures: (json['enabledFeatures'] as List<dynamic>?)
          ?.map((feature) => ProFeature.values.firstWhere(
                (f) => f.name == feature,
                orElse: () => ProFeature.deepAnalysis,
              ))
          .toList() ?? [],
    );
  }

  /// Convert to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'isProUser': isProUser,
      'proExpiryDate': proExpiryDate?.toIso8601String(),
      'accessType': accessType.name,
      'enabledFeatures': enabledFeatures.map((f) => f.name).toList(),
    };
  }

  /// Create default free model
  factory ProAccessModel.defaultFree() {
    return ProAccessModel(
      isProUser: false,
      accessType: ProAccessType.free,
      enabledFeatures: [],
    );
  }
}