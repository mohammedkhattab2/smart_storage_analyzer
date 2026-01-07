import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';

/// Base state for ProAccess
abstract class ProAccessState {}

/// Initial state
class ProAccessInitial extends ProAccessState {}

/// Loading state
class ProAccessLoading extends ProAccessState {}

/// Loaded state with Pro access data
class ProAccessLoaded extends ProAccessState {
  final ProAccess proAccess;

  ProAccessLoaded({required this.proAccess});
}

/// State when showing Pro feature info
class ProAccessShowingInfo extends ProAccessState {
  final ProAccess proAccess;

  ProAccessShowingInfo({required this.proAccess});
}

/// Error state
class ProAccessError extends ProAccessState {
  final String message;

  ProAccessError({required this.message});
}
