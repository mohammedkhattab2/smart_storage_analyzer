import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';

class FileListWidget extends StatelessWidget {
  final List<FileItem> files;
  final Set<String> selectedFileIds;
  final Function(String) onFileToggle;

  const FileListWidget({
    super.key,
    required this.files,
    required this.selectedFileIds,
    required this.onFileToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(AppSize.paddingMedium),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FileItemWidget(
          file: file,
          isSelected: selectedFileIds.contains(file.id),
          onToggle: () => onFileToggle(file.id),
        );
      },
    );
  }
}

class FileItemWidget extends StatelessWidget {
  final FileItem file;
  final bool isSelected;
  final VoidCallback onToggle;

  const FileItemWidget({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha:  .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(file.extension),
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          file.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              SizeFormatter.formateBytes(file.sizeInBytes),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'â€¢',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getTimeAgo(file.lastModified),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(ext)) {
      return Icons.image_outlined;
    } else if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return Icons.video_file_outlined;
    } else if (['.mp3', '.wav', '.flac', '.aac'].contains(ext)) {
      return Icons.audio_file_outlined;
    } else if (['.pdf', '.doc', '.docx', '.txt'].contains(ext)) {
      return Icons.description_outlined;
    } else if (['.zip', '.rar', '.7z'].contains(ext)) {
      return Icons.folder_zip_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
