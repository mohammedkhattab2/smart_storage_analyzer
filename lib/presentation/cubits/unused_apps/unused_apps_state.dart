part of 'unused_apps_cubit.dart';

/// Base state for Unused Apps feature.
abstract class UnusedAppsState extends Equatable {
  final UnusedAppsFilter filter;
  final UnusedAppsSort sort;

  const UnusedAppsState({
    required this.filter,
    required this.sort,
  });

  @override
  List<Object?> get props => [filter, sort];
}

/// Initial state before any loading happens.
class UnusedAppsInitial extends UnusedAppsState {
  const UnusedAppsInitial()
      : super(
          filter: UnusedAppsFilter.days30,
          sort: UnusedAppsSort.byLastUsed,
        );
}

/// Loading state while fetching unused apps.
class UnusedAppsLoading extends UnusedAppsState {
  const UnusedAppsLoading({
    required super.filter,
    required super.sort,
  });
}

/// Loaded state with list of unused apps.
class UnusedAppsLoaded extends UnusedAppsState {
  final List<UnusedApp> apps;
  /// Total size in bytes that could be reclaimed by uninstalling all
  /// currently loaded unused apps.
  final int totalReclaimableBytes;

  const UnusedAppsLoaded({
    required this.apps,
    required this.totalReclaimableBytes,
    required super.filter,
    required super.sort,
  });

  @override
  List<Object?> get props => [apps, totalReclaimableBytes, filter, sort];
}

/// Error state when loading unused apps fails.
class UnusedAppsError extends UnusedAppsState {
 final String message;

 const UnusedAppsError({
   required this.message,
   required super.filter,
   required super.sort,
 });

 @override
 List<Object?> get props => [message, filter, sort];
}

/// State emitted when Usage Access (PACKAGE_USAGE_STATS) permission is
/// required in order to load unused apps. The UI should present a dedicated
/// explanation and a button to open system settings.
class UnusedAppsPermissionRequired extends UnusedAppsState {
 final String message;

 const UnusedAppsPermissionRequired({
   required this.message,
   required super.filter,
   required super.sort,
 });

 @override
 List<Object?> get props => [message, filter, sort];
}