import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

/// Dashboard quick actions row.
///
/// This widget contains **no business logic**:
/// - No storage analysis
/// - No cache computation
/// - No SAF or MethodChannel usage
///
/// It only triggers navigation to existing flows.
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionButton(
              icon: Icons.chat_rounded,
              label: 'WhatsApp Cleaner',
              color: const Color(0xFF00A884),
              onTap: () {
                context.push(AppRoutes.whatsappCleaner);
              },
            ),
            _QuickActionButton(
              icon: Icons.auto_delete_rounded,
              label: 'Clean Cache',
              color: colorScheme.primary,
              onTap: () {
                // Navigate to storage analysis / cleanup flow for this app's cache only
                context.push(AppRoutes.storageAnalysis);
              },
            ),
            _QuickActionButton(
              icon: Icons.apps_rounded,
              label: 'Unused Apps',
              color: colorScheme.tertiary,
              onTap: () {
                // Navigate to Unused Apps detector screen
                context.push(AppRoutes.unusedApps);
              },
            ),
            _QuickActionButton(
              icon: Icons.insert_drive_file_rounded,
              label: 'Large Files',
              color: colorScheme.secondary,
              onTap: () {
                // Navigate to file manager focused on large files tab
                context.push(
                  AppRoutes.fileManager,
                  extra: FileCategory.large,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: .18),
                      color.withValues(alpha: .05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: .3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}