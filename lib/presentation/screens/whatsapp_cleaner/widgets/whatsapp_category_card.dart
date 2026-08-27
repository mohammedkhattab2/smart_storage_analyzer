import 'package:flutter/material.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/whatsapp_media_item.dart';
import '../../../../domain/entities/whatsapp_scan_result.dart';

class WhatsAppCategoryCard extends StatelessWidget {
  final WhatsAppCategorySummary summary;
  final int totalWhatsAppSize;
  final VoidCallback onTap;

  const WhatsAppCategoryCard({
    super.key,
    required this.summary,
    required this.totalWhatsAppSize,
    required this.onTap,
  });

  IconData _getCategoryIcon(WhatsAppMediaType type) {
    switch (type) {
      case WhatsAppMediaType.voiceNotes:
        return Icons.mic_rounded;
      case WhatsAppMediaType.sentMedia:
        return Icons.outbox_rounded;
      case WhatsAppMediaType.statuses:
        return Icons.access_time_filled_rounded;
      case WhatsAppMediaType.images:
        return Icons.image_rounded;
      case WhatsAppMediaType.videos:
        return Icons.videocam_rounded;
      case WhatsAppMediaType.audio:
        return Icons.audiotrack_rounded;
      case WhatsAppMediaType.documents:
        return Icons.description_rounded;
      case WhatsAppMediaType.stickers:
        return Icons.emoji_emotions_rounded;
      case WhatsAppMediaType.animatedGifs:
        return Icons.gif_box_rounded;
    }
  }

  Color _getCategoryColor(WhatsAppMediaType type, ColorScheme colorScheme) {
    switch (type) {
      case WhatsAppMediaType.voiceNotes:
        return const Color(0xFF00A884); // WhatsApp Green
      case WhatsAppMediaType.sentMedia:
        return Colors.orangeAccent;
      case WhatsAppMediaType.statuses:
        return Colors.purpleAccent;
      case WhatsAppMediaType.images:
        return Colors.blueAccent;
      case WhatsAppMediaType.videos:
        return Colors.redAccent;
      case WhatsAppMediaType.audio:
        return Colors.tealAccent;
      case WhatsAppMediaType.documents:
        return Colors.amberAccent;
      case WhatsAppMediaType.stickers:
        return Colors.pinkAccent;
      case WhatsAppMediaType.animatedGifs:
        return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _getCategoryColor(summary.type, colorScheme);
    final double percentage = totalWhatsAppSize > 0
        ? (summary.totalBytes / totalWhatsAppSize).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSize.paddingSmall),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSize.radiusMedium),
                    ),
                    child: Icon(
                      _getCategoryIcon(summary.type),
                      color: categoryColor,
                      size: AppSize.iconMedium,
                    ),
                  ),
                  if (summary.fileCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${summary.fileCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FileSizeFormatter.formatSize(summary.totalBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
