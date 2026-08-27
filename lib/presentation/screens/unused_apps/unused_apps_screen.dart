import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/core/services/app_management_service.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_unused_apps_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/unused_apps/unused_apps_cubit.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';

class UnusedAppsScreen extends StatelessWidget {
  const UnusedAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UnusedAppsCubit>(
      create: (_) => sl<UnusedAppsCubit>()..loadUnusedApps(),
      child: const _UnusedAppsView(),
    );
  }
}

class _UnusedAppsView extends StatefulWidget {
  const _UnusedAppsView();

  @override
  State<_UnusedAppsView> createState() => _UnusedAppsViewState();
}

class _UnusedAppsViewState extends State<_UnusedAppsView> {
  final DateFormat _dateFormat = DateFormat.yMMMd();
  final AppManagementService _appManagementService = AppManagementService();
  final PermissionService _permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: AppSize.paddingMedium,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSize.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unused Apps',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find and remove apps you no longer use',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerLow,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingMedium,
              vertical: AppSize.paddingMedium,
            ),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSize.paddingMedium),
                Expanded(
                  child: BlocBuilder<UnusedAppsCubit, UnusedAppsState>(
                    builder: (context, state) {
                      if (state is UnusedAppsLoading) {
                        return const LoadingWidget();
                      }

                      if (state is UnusedAppsError) {
                        return _buildErrorState(context, state.message);
                      }

                      if (state is UnusedAppsPermissionRequired) {
                        return _buildPermissionRequiredState(
                          context,
                          state.message,
                        );
                      }

                      if (state is UnusedAppsLoaded) {
                        if (state.apps.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return _buildList(
                          context,
                          state.apps,
                          state.totalReclaimableBytes,
                        );
                      }

                      // Initial state fallback
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cubit = context.read<UnusedAppsCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Text(
                'Filters & sorting',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: cubit.currentFilter,
                  onChanged: (value) {
                    if (value != null) {
                      cubit.changeFilter(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSize.paddingMedium),
              Expanded(
                child: _SortDropdown(
                  value: cubit.currentSort,
                  onChanged: (value) {
                    if (value != null) {
                      cubit.changeSort(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<UnusedApp> apps,
    int totalReclaimableBytes,
  ) {
    return ListView.separated(
      itemCount: apps.length + 1,
      separatorBuilder: (_, separatorIndex) =>
          const SizedBox(height: AppSize.paddingSmall),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryBanner(
            context,
            totalReclaimableBytes,
            apps.length,
          );
        }

        final app = apps[index - 1];
        final messenger = ScaffoldMessenger.of(context);
 
        return _UnusedAppTile(
          app: app,
          formattedDate: _dateFormat.format(app.lastUsed),
          onUninstall: () async {
            final success =
                await _appManagementService.uninstallApp(app.packageName);
 
            if (!mounted) return;
 
            if (!success) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Unable to start uninstall.'),
                ),
              );
            }
            // لا نقوم بعمل refresh تلقائي بعد استدعاء شاشة الـ uninstall
            // عشان لما ترجع من شاشة النظام ما يحصلش إعادة تحميل للقائمة
            // وتقدر تجرّب أي تطبيق تاني مباشرة.
          },
        );
      },
    );
  }

  Widget _buildSummaryBanner(
    BuildContext context,
    int totalReclaimableBytes,
    int appCount,
  ) {
    if (appCount == 0 || totalReclaimableBytes <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formattedSize = SizeFormatter.formatBytes(totalReclaimableBytes);
    final appsLabel = appCount == 1 ? 'app' : 'apps';

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.secondary.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_delete_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart cleanup opportunity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can free up $formattedSize by removing $appCount unused $appsLabel.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.successContainer.withValues(alpha: 0.9),
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 32,
                color: colorScheme.success,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Text(
              'No unused apps found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'Your installed apps look actively used for the selected period.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.errorContainer,
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            FilledButton.icon(
              onPressed: () {
                context.read<UnusedAppsCubit>().loadUnusedApps();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequiredState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.infoContainer.withValues(alpha: 0.9),
              ),
              child: Icon(
                Icons.privacy_tip_outlined,
                size: 32,
                color: colorScheme.info,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Text(
              'Usage access required',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            FilledButton.icon(
              onPressed: () async {
                await _permissionService.openUsageAccessSettings();
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnusedAppTile extends StatelessWidget {
  final UnusedApp app;
  final String formattedDate;
  final VoidCallback onUninstall;

  const _UnusedAppTile({
    required this.app,
    required this.formattedDate,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.apps,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  app.packageName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Last used $formattedDate',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            SizeFormatter.formatBytes(app.appSizeBytes),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          if (app.isSystemApp)
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('System app'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: onUninstall,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Uninstall'),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final UnusedAppsFilter value;
  final ValueChanged<UnusedAppsFilter?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<UnusedAppsFilter>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Unused period',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: UnusedAppsFilter.days7,
          child: Text('7+ days'),
        ),
        DropdownMenuItem(
          value: UnusedAppsFilter.days30,
          child: Text('30+ days'),
        ),
        DropdownMenuItem(
          value: UnusedAppsFilter.days60Plus,
          child: Text('60+ days'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final UnusedAppsSort value;
  final ValueChanged<UnusedAppsSort?> onChanged;

  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<UnusedAppsSort>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Sort by',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: UnusedAppsSort.byLastUsed,
          child: Text('Last used'),
        ),
        DropdownMenuItem(
          value: UnusedAppsSort.bySizeDesc,
          child: Text('Size'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}