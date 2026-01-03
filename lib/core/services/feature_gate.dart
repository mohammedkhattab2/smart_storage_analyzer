import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/services/pro_access_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';

/// Feature Gate for controlling access to Pro features
/// This ensures clean separation between free and Pro features
class FeatureGate {
  final ProAccessService _proAccessService;
  
  FeatureGate({required ProAccessService proAccessService})
      : _proAccessService = proAccessService;
  
  /// Check if a feature is available
  Future<bool> isFeatureAvailable(ProFeature feature) async {
    try {
      final hasAccess = await _proAccessService.hasFeature(feature);
      if (!hasAccess) {
        Logger.info('Feature ${feature.name} is not available for free users');
      }
      return hasAccess;
    } catch (e) {
      Logger.error('Error checking feature availability', e);
      return false;
    }
  }
  
  /// Execute a function only if feature is available
  Future<T?> executeIfAvailable<T>({
    required ProFeature feature,
    required Future<T> Function() action,
    Future<T> Function()? fallback,
    VoidCallback? onRestricted,
  }) async {
    final isAvailable = await isFeatureAvailable(feature);
    
    if (isAvailable) {
      return await action();
    } else {
      onRestricted?.call();
      return fallback != null ? await fallback() : null;
    }
  }
  
  /// Show Pro feature dialog when accessing restricted feature
  Future<void> showProFeatureDialog(
    BuildContext context,
    ProFeature feature,
  ) async {
    final featureInfo = ProAccessService.getFeatureInfo(feature);
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProFeatureDialog(
        featureInfo: featureInfo,
        onUpgrade: () {
          Navigator.pop(context);
          _showUpgradeInfo(context);
        },
      ),
    );
  }
  
  /// Show upgrade information (no payment)
  void _showUpgradeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeInfoDialog(),
    );
  }
}

/// Dialog shown when accessing Pro features
class ProFeatureDialog extends StatelessWidget {
  final ProFeatureInfo featureInfo;
  final VoidCallback onUpgrade;
  
  const ProFeatureDialog({
    super.key,
    required this.featureInfo,
    required this.onUpgrade,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(featureInfo.icon),
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              featureInfo.name,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This is a Pro feature',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            featureInfo.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: onUpgrade,
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Learn More'),
        ),
      ],
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'analytics':
        return Icons.analytics_outlined;
      case 'auto_delete':
        return Icons.auto_delete_outlined;
      case 'cloud_upload':
        return Icons.cloud_upload_outlined;
      case 'library_add':
        return Icons.library_add_outlined;
      case 'filter_alt':
        return Icons.filter_alt_outlined;
      case 'find_in_page':
        return Icons.find_in_page_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'insights':
        return Icons.insights_outlined;
      case 'download':
        return Icons.download_outlined;
      default:
        return Icons.star_outlined;
    }
  }
}

/// Upgrade information dialog (no payment)
class UpgradeInfoDialog extends StatelessWidget {
  const UpgradeInfoDialog({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Smart Storage Pro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock powerful features:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._buildFeatureList(context),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: .1),
                    colorScheme.secondary.withValues(alpha: .1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: .3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    color: colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pro version coming soon!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re working hard to bring you amazing Pro features',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
  
  List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      'Deep file analysis',
      'Auto cleanup scheduler',
      'Cloud backup integration',
      'Batch file operations',
      'Advanced filters & sorting',
      'Duplicate file finder',
      'Custom themes',
      'Advanced statistics',
      'Export reports',
    ];
    
    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    )).toList();
  }
}