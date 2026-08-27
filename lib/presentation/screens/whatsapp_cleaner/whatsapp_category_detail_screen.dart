import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/whatsapp_media_item.dart';
import '../../../../domain/entities/whatsapp_scan_result.dart';
import '../../cubits/whatsapp_cleaner/whatsapp_cleaner_cubit.dart';
import '../../cubits/whatsapp_cleaner/whatsapp_cleaner_state.dart';
import '../../viewmodels/whatsapp_cleaner_viewmodel.dart';

class WhatsAppCategoryDetailScreen extends StatefulWidget {
  final WhatsAppCategorySummary categorySummary;

  const WhatsAppCategoryDetailScreen({
    super.key,
    required this.categorySummary,
  });

  @override
  State<WhatsAppCategoryDetailScreen> createState() =>
      _WhatsAppCategoryDetailScreenState();
}

class _WhatsAppCategoryDetailScreenState
    extends State<WhatsAppCategoryDetailScreen> {
  WhatsAppFilterType _selectedFilter = WhatsAppFilterType.all;
  AudioPlayer? _audioPlayer;
  String? _currentlyPlayingUri;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    if (widget.categorySummary.type == WhatsAppMediaType.voiceNotes ||
        widget.categorySummary.type == WhatsAppMediaType.audio) {
      _audioPlayer = AudioPlayer();
      _audioPlayer?.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingAudio = state == PlayerState.playing;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlay(WhatsAppMediaItem item) async {
    if (_audioPlayer == null) return;

    if (_currentlyPlayingUri == item.uri && _isPlayingAudio) {
      await _audioPlayer?.pause();
      setState(() {
        _isPlayingAudio = false;
      });
    } else {
      await _audioPlayer?.stop();
      try {
        await _audioPlayer?.play(DeviceFileSource(item.path));
        setState(() {
          _currentlyPlayingUri = item.uri;
          _isPlayingAudio = true;
        });
      } catch (e) {
        // If direct file playback fails (e.g. content URI), open via default player
        OpenFilex.open(item.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<WhatsAppCleanerCubit, WhatsAppCleanerState>(
      listener: (context, state) {
        if (state is WhatsAppCleanSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cleaned ${state.deletedFilesCount} files (${FileSizeFormatter.formatSize(state.reclaimedBytes)})',
              ),
              backgroundColor: const Color(0xFF00A884),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<WhatsAppCleanerCubit>();
        final selectedUris = state is WhatsAppLoaded ? state.selectedUris : <String>{};

        // Get latest items for this category
        List<WhatsAppMediaItem> rawItems = widget.categorySummary.items;
        if (state is WhatsAppLoaded) {
          final updatedSummary = state.scanResult.categories[widget.categorySummary.type];
          rawItems = updatedSummary?.items ?? [];
        }

        // Apply filter
        List<WhatsAppMediaItem> displayItems = List.from(rawItems);
        switch (_selectedFilter) {
          case WhatsAppFilterType.all:
            break;
          case WhatsAppFilterType.sent:
            displayItems = displayItems.where((item) => item.isSent).toList();
            break;
          case WhatsAppFilterType.received:
            displayItems = displayItems.where((item) => !item.isSent).toList();
            break;
          case WhatsAppFilterType.oldOnly:
            displayItems = displayItems.where((item) => item.isOlderThan(30)).toList();
            break;
          case WhatsAppFilterType.largestFirst:
            displayItems.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
            break;
        }

        final int selectedBytes = rawItems
            .where((item) => selectedUris.contains(item.uri))
            .fold<int>(0, (sum, i) => sum + i.sizeBytes);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.categorySummary.title),
            actions: [
              if (rawItems.isNotEmpty)
                IconButton(
                  icon: Icon(
                    selectedUris.length == displayItems.length && displayItems.isNotEmpty
                        ? Icons.select_all_rounded
                        : Icons.checklist_rounded,
                  ),
                  tooltip: selectedUris.length == displayItems.length
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: () {
                    if (selectedUris.length == displayItems.length) {
                      cubit.deselectAll();
                    } else {
                      cubit.selectAll(displayItems.map((e) => e.uri).toList());
                    }
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSize.paddingMedium,
                  vertical: AppSize.paddingSmall,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('All (${rawItems.length})', WhatsAppFilterType.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sent', WhatsAppFilterType.sent),
                    const SizedBox(width: 8),
                    _buildFilterChip('Received', WhatsAppFilterType.received),
                    const SizedBox(width: 8),
                    _buildFilterChip('Old (> 30d)', WhatsAppFilterType.oldOnly),
                    const SizedBox(width: 8),
                    _buildFilterChip('Largest First', WhatsAppFilterType.largestFirst),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Items List / Grid
              Expanded(
                child: displayItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: AppSize.paddingMedium),
                            Text(
                              'No files found in this filter',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSize.paddingMedium),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          final isSelected = selectedUris.contains(item.uri);

                          return _buildMediaTile(
                            context,
                            item: item,
                            isSelected: isSelected,
                            onTap: () => cubit.toggleItemSelection(item.uri),
                            onPlayAudio: () => _toggleAudioPlay(item),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Bottom Action Bar for batch deletion
          bottomNavigationBar: selectedUris.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSize.paddingMedium),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedUris.length} files selected',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              FileSizeFormatter.formatSize(selectedBytes),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: () => _showDeleteConfirmation(context, cubit, selectedUris.length, selectedBytes),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSize.paddingLarge,
                              vertical: AppSize.paddingSmall,
                            ),
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterChip(String label, WhatsAppFilterType filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }

  Widget _buildMediaTile(
    BuildContext context, {
    required WhatsAppMediaItem item,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onPlayAudio,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAudio = item.category == WhatsAppMediaType.voiceNotes ||
        item.category == WhatsAppMediaType.audio;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              FileSizeFormatter.formatSize(item.sizeBytes),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            if (item.isSent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sent',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: isAudio
            ? IconButton(
                icon: Icon(
                  _currentlyPlayingUri == item.uri && _isPlayingAudio
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: const Color(0xFF00A884),
                  size: 32,
                ),
                onPressed: onPlayAudio,
              )
            : IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                tooltip: 'Open file',
                onPressed: () => _openFile(context, item),
              ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, WhatsAppMediaItem item) async {
    try {
      // 1. Try native platform openDocument (supports Scoped Storage content URIs)
      const platform = MethodChannel('com.smarttools.storageanalyzer/native');
      final success = await platform.invokeMethod<bool>('openDocument', {
        'uri': item.uri,
        'mimeType': item.mimeType,
      });

      if (success == true) return;
    } catch (_) {}

    // 2. Fallback to OpenFilex with physical path
    try {
      if (item.path.isNotEmpty) {
        final result = await OpenFilex.open(item.path);
        if (result.type == ResultType.done) return;
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${item.name}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WhatsAppCleanerCubit cubit,
    int count,
    int bytes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete $count files (${FileSizeFormatter.formatSize(bytes)}) from WhatsApp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.deleteSelected();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
