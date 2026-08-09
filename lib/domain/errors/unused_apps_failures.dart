import 'package:equatable/equatable.dart';

/// Domain-level failure representing missing Usage Access permission
/// (PACKAGE_USAGE_STATS) needed for unused apps analysis.
///
/// This stays in the pure Dart domain layer (no Flutter imports) and can be
/// thrown by repositories or use cases and handled by presentation.
class UsageAccessDeniedFailure extends Equatable implements Exception {
  final String message;

  const UsageAccessDeniedFailure({
    this.message = 'Usage access permission is required to analyze unused apps.',
  });

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'UsageAccessDeniedFailure(message: $message)';
}

/// Data-layer exception that can be thrown by repositories when the platform
/// reports that Usage Access permission is missing. Extends the domain failure
/// so presentation code can simply catch [UsageAccessDeniedFailure].
class UsageAccessDeniedException extends UsageAccessDeniedFailure {
  const UsageAccessDeniedException({
    super.message = 'Usage access permission is required to analyze unused apps.',
  });
}