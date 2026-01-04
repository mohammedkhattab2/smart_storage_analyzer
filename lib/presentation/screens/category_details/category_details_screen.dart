import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_state.dart';
import 'package:smart_storage_analyzer/core/services/file_operations_service.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CategoryDetailsCubit>()..loadCategoryFiles(category),
      child: _CategoryDetailsView(category: category),
    );
  }
}

class _CategoryDetailsView extends StatelessWidget {
  final Category category;

  const _CategoryDetailsView({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(context, colorScheme, textTheme),
      body: Stack(
        children: [
          // Magical gradient background
          _buildMagicalBackground(colorScheme, isDark),
          
          // Main content
          SafeArea(
            child: BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
              builder: (context, state) {
                if (state is CategoryDetailsLoading) {
                  return _buildMagicalLoading(colorScheme);
                }

                if (state is CategoryDetailsError) {
                  return _buildMagicalError(
                    context,
                    state,
                    colorScheme,
                  );
                }

                if (state is CategoryDetailsLoaded) {
                  if (state.files.isEmpty) {
                    return _buildMagicalEmptyState(
                      colorScheme,
                      textTheme,
                    );
                  }

                  return _buildFilesList(
                    context,
                    state,
                    colorScheme,
                    isDark,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMagicalAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface.withValues(alpha: .8),
                  colorScheme.surface.withValues(alpha: .6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: .2),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                category.color,
                category.color.withValues(
                  red: math.min(1.0, category.color.r * 1.2),
                  green: math.min(1.0, category.color.g * 1.2),
                  blue: math.min(1.0, category.color.b * 1.2),
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              category.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
            builder: (context, state) {
              if (state is CategoryDetailsLoaded) {
                return Text(
                  '${state.files.length} files • ${SizeFormatter.formatBytes(state.totalSize)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return Text(
                '${category.fileCount} files • ${SizeFormatter.formatBytes(category.sizeInBytes.toInt())}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildMagicalBackground(ColorScheme colorScheme, bool isDark) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.5, -0.5),
              radius: 1.5,
              colors: [
                category.color.withValues(alpha: isDark ? .08 : .15),
                colorScheme.surface,
                colorScheme.surfaceContainer.withValues(alpha: isDark ? .3 : .5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Floating orbs
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  category.color.withValues(alpha: .1),
                  category.color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: .08),
                  colorScheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Custom pattern painter
        CustomPaint(
          size: Size.infinite,
          painter: _CategoryBackgroundPainter(
            color: category.color.withValues(alpha: .03),
            secondaryColor: colorScheme.primary.withValues(alpha: .02),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalLoading(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  category.color.withValues(alpha: .15),
                  category.color.withValues(alpha: 0),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      category.color,
                      category.color.withValues(
                        red: math.min(1.0, category.color.r * 0.8),
                        green: math.min(1.0, category.color.g * 0.8),
                        blue: math.min(1.0, category.color.b * 0.8),
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withValues(alpha: .5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading ${category.name}...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalError(
    BuildContext context,
    CategoryDetailsError state,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.errorContainer.withValues(alpha: .15),
                colorScheme.errorContainer.withValues(alpha: .05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: .2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withValues(alpha: .1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  context.read<CategoryDetailsCubit>().loadCategoryFiles(
                    category,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalEmptyState(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  category.color.withValues(alpha: .1),
                  category.color.withValues(alpha: .05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                      colorScheme.surfaceContainer.withValues(alpha: .3),
                    ],
                  ),
                  border: Border.all(
                    color: category.color.withValues(alpha: .2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  size: 48,
                  color: category.color.withValues(alpha: .5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingLarge),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                colorScheme.onSurface,
                colorScheme.onSurfaceVariant,
              ],
            ).createShader(bounds),
            child: Text(
              'No ${category.name} found',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            'Files will appear here when detected',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(
    BuildContext context,
    CategoryDetailsLoaded state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return RefreshIndicator(
      color: category.color,
      backgroundColor: colorScheme.surface,
      strokeWidth: 3,
      displacement: 80,
      onRefresh: () async {
        await context.read<CategoryDetailsCubit>().refresh(category);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSize.paddingMedium,
          vertical: AppSize.paddingMedium,
        ),
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          return _MagicalFileListItem(
            file: file,
            category: category,
            index: index,
            isDark: isDark,
            onTap: () async {
              // Use native file opening functionality
              final fileOperations = FileOperationsService();
              final success = await fileOperations.openFile(file.path);
              
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot open ${file.name}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSize.radiusSmall,
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }


  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'images':
      case 'image':
        return Icons.image_rounded;
      case 'videos':
      case 'video':
        return Icons.video_library_rounded;
      case 'audio':
      case 'music':
        return Icons.library_music_rounded;
      case 'documents':
      case 'document':
        return Icons.folder_rounded;
      case 'apps':
      case 'applications':
        return Icons.apps_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }
}

// Enhanced file list item with magical visuals
class _MagicalFileListItem extends StatefulWidget {
  final FileItem file;
  final Category category;
  final VoidCallback onTap;
  final int index;
  final bool isDark;

  const _MagicalFileListItem({
    required this.file,
    required this.category,
    required this.onTap,
    required this.index,
    required this.isDark,
  });

  @override
  State<_MagicalFileListItem> createState() => _MagicalFileListItemState();
}

class _MagicalFileListItemState extends State<_MagicalFileListItem> {
  bool _isPressed = false;

  IconData _getFileIcon() {
    final extension = widget.file.extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return Icons.image_rounded;
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return Icons.video_file_rounded;
    } else if (['.mp3', '.wav', '.flac', '.m4a'].contains(extension)) {
      return Icons.audio_file_rounded;
    } else if (['.pdf', '.doc', '.txt', '.xlsx'].contains(extension)) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                widget.category.color.withValues(alpha: widget.isDark ? .08 : .12),
                widget.category.color.withValues(alpha: widget.isDark ? .04 : .08),
                colorScheme.surfaceContainer.withValues(alpha: .5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.category.color.withValues(alpha: .1),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: widget.category.color.withValues(alpha: .1),
              highlightColor: widget.category.color.withValues(alpha: .05),
              child: Container(
                padding: const EdgeInsets.all(AppSize.paddingMedium),
                child: Row(
                  children: [
                    // Magical icon container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.category.color.withValues(alpha: .2),
                            widget.category.color.withValues(alpha: .1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.category.color.withValues(alpha: .3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.category.color.withValues(alpha: .25),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getFileIcon(),
                        color: widget.category.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSize.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${SizeFormatter.formatBytes(widget.file.sizeInBytes)} • ${_formatDate(widget.file.lastModified)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.category.color.withValues(alpha: .15),
                            widget.category.color.withValues(alpha: .05),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: widget.category.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    return '${(difference.inDays / 365).floor()} years ago';
  }
}

// Custom background painter
class _CategoryBackgroundPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  _CategoryBackgroundPainter({
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    const spacing = 50.0;
    
    // Vertical lines
    paint.color = color;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines with gradient effect
    for (double y = 0; y < size.height; y += spacing) {
      paint.color = Color.lerp(
        color,
        secondaryColor,
        y / size.height,
      )!;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw decorative circles at intersections
    final circlePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing * 2) {
      for (double y = spacing; y < size.height; y += spacing * 2) {
        canvas.drawCircle(
          Offset(x, y),
          3,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
