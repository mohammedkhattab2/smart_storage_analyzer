/// Permission request model for clean architecture
class PermissionRequest {
  final PermissionType type;
  final String rationale;

  PermissionRequest({
    required this.type,
    required this.rationale,
  });
}

/// Permission types enum
enum PermissionType {
  storage,
  notification,
  mediaLocation,
}