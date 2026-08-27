import 'package:flutter/material.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/whatsapp_scan_result.dart';

class WhatsAppQuickCleanDialog extends StatelessWidget {
  final WhatsAppScanResult scanResult;
  final VoidCallback onConfirm;

  const WhatsAppQuickCleanDialog({
    super.key,
    required this.scanResult,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final recommendedItems = scanResult.allItems
        .where((item) => item.isQuickCleanRecommended)
        .toList();

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.radiusXLarge),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_delete_rounded,
              color: Color(0xFF00A884),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          const Expanded(
            child: Text(
              'Quick Clean WhatsApp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will safely clean recommended clutter:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          Container(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSize.radiusMedium),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _buildCleanRow(
                  context,
                  icon: Icons.outbox_rounded,
                  title: 'Sent Media (Duplicate copies)',
                  color: Colors.orangeAccent,
                ),
                const Divider(height: 16),
                _buildCleanRow(
                  context,
                  icon: Icons.access_time_filled_rounded,
                  title: 'Cached Statuses',
                  color: Colors.purpleAccent,
                ),
                const Divider(height: 16),
                _buildCleanRow(
                  context,
                  icon: Icons.mic_rounded,
                  title: 'Old Voice Notes (> 30 days)',
                  color: const Color(0xFF00A884),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Reclaimed Space:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                FileSizeFormatter.formatSize(scanResult.cleanableSizeBytes),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF00A884),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${recommendedItems.length} files selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.radiusMedium),
            ),
          ),
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('Clean Now'),
        ),
      ],
    );
  }

  Widget _buildCleanRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
