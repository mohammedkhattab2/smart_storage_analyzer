import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/services/content_uri_service.dart';

class InAppMediaViewerScreen extends StatefulWidget {
  final FileItem file;
  final List<FileItem> allFiles;

  const InAppMediaViewerScreen({
    super.key,
    required this.file,
    required this.allFiles,
  });

  @override
  State<InAppMediaViewerScreen> createState() => _InAppMediaViewerScreenState();
}

class _InAppMediaViewerScreenState extends State<InAppMediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allFiles.indexOf(widget.file);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _shareFile() async {
    final file = widget.allFiles[_currentIndex];
    try {
      await Share.shareXFiles([XFile(file.path)], subject: file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile() async {
    final file = widget.allFiles[_currentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final fileToDelete = File(file.path);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name} deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate deletion
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete file: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _openInExternalApp() async {
    final file = widget.allFiles[_currentIndex];
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open file: ${result.message}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Media viewer
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.allFiles.length,
              itemBuilder: (context, index) {
                final file = widget.allFiles[index];
                return _MediaContentWidget(
                  file: file,
                  key: ValueKey(file.path),
                );
              },
            ),

            // Top controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSize.paddingMedium),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.allFiles[_currentIndex].name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_currentIndex + 1} of ${widget.allFiles.length}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (value) async {
                            switch (value) {
                              case 'share':
                                await _shareFile();
                                break;
                              case 'delete':
                                await _deleteFile();
                                break;
                              case 'open_external':
                                await _openInExternalApp();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_rounded),
                                  SizedBox(width: 12),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'open_external',
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded),
                                  SizedBox(width: 12),
                                  Text('Open in External App'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSize.paddingLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // File info
                          Container(
                            padding: const EdgeInsets.all(
                              AppSize.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getFileIcon(widget.allFiles[_currentIndex]),
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: AppSize.paddingMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Size',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white60,
                                        ),
                                      ),
                                      Text(
                                        SizeFormatter.formatBytes(
                                          widget
                                              .allFiles[_currentIndex]
                                              .sizeInBytes,
                                        ),
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modified',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(
                                        widget
                                            .allFiles[_currentIndex]
                                            .lastModified,
                                      ),
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSize.paddingMedium),

                          // Page indicator
                          if (widget.allFiles.length > 1)
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.allFiles.length,
                                itemBuilder: (context, index) {
                                  final isActive = index == _currentIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Container(
                                        width: isActive ? 32 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(FileItem file) {
    final extension = file.extension.toLowerCase();
    if (_isImage(extension)) {
      return Icons.image_rounded;
    } else if (_isVideo(extension)) {
      return Icons.video_file_rounded;
    } else if (_isAudio(extension)) {
      return Icons.audio_file_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  bool _isImage(String extension) {
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    ].contains(extension);
  }

  bool _isVideo(String extension) {
    return [
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
      '.webm',
      '.3gp',
    ].contains(extension);
  }

  bool _isAudio(String extension) {
    return [
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.opus',
      '.m4a',
      '.wma',
      '.amr',
      '.3gpp',
      '.3gp',
      '.webm', // WebM can contain audio only
    ].contains(extension);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}

// Separate widget for media content to handle different file types
class _MediaContentWidget extends StatefulWidget {
  final FileItem file;

  const _MediaContentWidget({super.key, required this.file});

  @override
  State<_MediaContentWidget> createState() => _MediaContentWidgetState();
}

class _MediaContentWidgetState extends State<_MediaContentWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    try {
      final extension = widget.file.extension.toLowerCase();

      if (_isVideo(extension)) {
        await _initializeVideo();
      } else if (_isAudio(extension)) {
        await _initializeAudio();
      } else if (_isImage(extension)) {
        // Images don't need initialization
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unsupported file type';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load media: ${e.toString()}';
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if path is a content URI or regular file path
      if (ContentUriService.isContentUri(widget.file.path)) {
        // For content URIs on Android, use networkUrl which can handle content URIs
        final uri = Uri.parse(widget.file.path);
        _videoController = VideoPlayerController.networkUrl(uri);
      } else {
        // For regular file paths
        _videoController = VideoPlayerController.file(File(widget.file.path));
      }
      
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error playing video',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Try opening with external app
                    Navigator.pop(context);
                    _openFileExternally();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open with External App'),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  Future<void> _openFileExternally() async {
    try {
      if (ContentUriService.isContentUri(widget.file.path)) {
        // Use ContentUriService to open content URIs
        final success = await ContentUriService.openContentUri(
          widget.file.path,
          mimeType: _getMimeType(widget.file.extension),
        );
        if (!success) {
          // Fallback to share if opening fails
          await Share.shareXFiles([XFile(widget.file.path)], subject: widget.file.name);
        }
      } else {
        await OpenFilex.open(widget.file.path);
      }
    } catch (e) {
      // Handle error silently
      developer.log('Error opening file externally: $e', name: 'MediaViewer');
    }
  }
  
  String? _getMimeType(String extension) {
    final ext = extension.toLowerCase();
    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.bmp': 'image/bmp',
      '.mp4': 'video/mp4',
      '.avi': 'video/x-msvideo',
      '.mov': 'video/quicktime',
      '.mkv': 'video/x-matroska',
      '.webm': 'video/webm',
      '.3gp': 'video/3gpp',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.flac': 'audio/flac',
      '.aac': 'audio/aac',
      '.ogg': 'audio/ogg',
      '.m4a': 'audio/mp4',
    };
    return mimeTypes[ext];
  }

  Future<void> _initializeAudio() async {
    // Check if this is a content URI for audio - audioplayers doesn't support them
    if (ContentUriService.isContentUri(widget.file.path)) {
      developer.log('Audio file is a content URI - audioplayers does not support content URIs', name: 'MediaViewer');
      // Don't even try to initialize, go straight to showing the external app option
      setState(() {
        _isLoading = false;
        _audioPlayer = null; // Mark as not initialized
      });
      return;
    }
    
    // For regular file paths, try to initialize
    try {
      _audioPlayer = AudioPlayer();
      
      developer.log('Initializing audio for device file: ${widget.file.path}', name: 'MediaViewer');
      await _audioPlayer!.setSourceDeviceFile(widget.file.path);
      developer.log('Audio loaded successfully from device file', name: 'MediaViewer');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error initializing audio: $e', name: 'MediaViewer');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to play this audio file.\n\nTry opening with an external app.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openFileExternally,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with External App'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    final extension = widget.file.extension.toLowerCase();

    if (_isImage(extension)) {
      return _buildImageViewer();
    } else if (_isVideo(extension)) {
      return _buildVideoPlayer();
    } else if (_isAudio(extension)) {
      return _buildAudioPlayer();
    }

    return _buildUnsupportedFileType();
  }

  Widget _buildImageViewer() {
    // For content URIs, we need to load the image differently
    if (ContentUriService.isContentUri(widget.file.path)) {
      return FutureBuilder<Uint8List?>(
        future: _loadImageFromContentUri(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      _openFileExternally();
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open with External App'),
                  ),
                ],
              ),
            );
          }
          
          return PhotoView(
            imageProvider: MemoryImage(snapshot.data!),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.file.path),
          );
        },
      );
    } else {
      // For regular file paths
      return PhotoView(
        imageProvider: FileImage(File(widget.file.path)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.file.path),
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _openFileExternally();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open with External App'),
                ),
              ],
            ),
          );
        },
      );
    }
  }
  
  Future<Uint8List?> _loadImageFromContentUri() async {
    try {
      // Use ContentUriService to load bytes from content URI
      if (ContentUriService.isContentUri(widget.file.path)) {
        return await ContentUriService.readContentUriBytes(widget.file.path);
      }
      return null;
    } catch (e) {
      developer.log('Error loading image from content URI: $e', name: 'MediaViewer');
      return null;
    }
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildAudioPlayer() {
    // Check if audio player is initialized (content URIs won't initialize)
    if (_audioPlayer == null) {
      // Show a nice UI for audio files that can't be played in-app
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.audio_file_rounded,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                widget.file.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                SizeFormatter.formatBytes(widget.file.sizeInBytes),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              // Info message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade300, size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Audio preview not available.\nTap below to play in your music app.',
                        style: TextStyle(color: Colors.orange.shade100, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Primary action button
              ElevatedButton.icon(
                onPressed: _openFileExternally,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Play in Music App'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // If audio player is initialized (regular files), show player controls
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.audio_file_rounded,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              widget.file.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _AudioControlsWidget(audioPlayer: _audioPlayer!),
            const SizedBox(height: 24),
            // Add external app option
            TextButton.icon(
              onPressed: _openFileExternally,
              icon: const Icon(Icons.open_in_new, color: Colors.white70),
              label: const Text(
                'Open with External App',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedFileType() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.file_present_rounded,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            'Cannot preview this file type',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            widget.file.extension,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  bool _isImage(String extension) {
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    ].contains(extension);
  }

  bool _isVideo(String extension) {
    return [
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
      '.webm',
      '.3gp',
    ].contains(extension);
  }

  bool _isAudio(String extension) {
    return [
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.opus',
      '.m4a',
      '.wma',
      '.amr',
      '.3gpp',
      '.3gp',
      '.webm', // WebM can contain audio only
    ].contains(extension);
  }
}

// Audio controls widget
class _AudioControlsWidget extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const _AudioControlsWidget({required this.audioPlayer});

  @override
  State<_AudioControlsWidget> createState() => _AudioControlsWidgetState();
}

class _AudioControlsWidgetState extends State<_AudioControlsWidget> {
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    widget.audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    widget.audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: _position.inMilliseconds.toDouble(),
          max: _duration.inMilliseconds.toDouble(),
          onChanged: (value) async {
            await widget.audioPlayer.seek(
              Duration(milliseconds: value.toInt()),
            );
          },
          activeColor: Colors.white,
          inactiveColor: Colors.white24,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10_rounded),
              iconSize: 32,
              color: Colors.white,
              onPressed: () async {
                final newPosition = _position - const Duration(seconds: 10);
                await widget.audioPlayer.seek(
                  newPosition < Duration.zero ? Duration.zero : newPosition,
                );
              },
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                iconSize: 48,
                color: Colors.black,
                onPressed: () async {
                  if (_isPlaying) {
                    await widget.audioPlayer.pause();
                  } else {
                    await widget.audioPlayer.resume();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.forward_10_rounded),
              iconSize: 32,
              color: Colors.white,
              onPressed: () async {
                final newPosition = _position + const Duration(seconds: 10);
                await widget.audioPlayer.seek(
                  newPosition > _duration ? _duration : newPosition,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds";
  }
}
