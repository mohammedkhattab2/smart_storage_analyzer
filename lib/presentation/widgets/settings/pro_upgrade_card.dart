import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/services/feature_gate.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_state.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/pro_badge.dart';

/// Pro upgrade card for settings screen
class ProUpgradeCard extends StatelessWidget {
  const ProUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProAccessCubit, ProAccessState>(
      builder: (context, state) {
        final isProUser = state is ProAccessLoaded && state.proAccess.isProUser;

        if (isProUser) {
          // Show Pro status for Pro users (future feature)
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(AppSize.paddingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(
                  alpha: isDark ? .3 : .5,
                ),
                colorScheme.secondaryContainer.withValues(
                  alpha: isDark ? .3 : .5,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: .2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showProInfo(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(AppSize.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSize.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Upgrade to',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  const ProBadge(),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock powerful features',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.paddingMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.new_releases_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeInfoDialog(),
    );
  }
}
