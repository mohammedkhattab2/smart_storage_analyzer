import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/category_details/category_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/document_scanner/document_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/cubits/document_scan/document_scan_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/media_scanner/media_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/others_scanner/others_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/cubits/others_scan/others_scan_cubit.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/presentation/mappers/category_ui_mapper.dart';

class AllCategoriesView extends StatelessWidget {
  const AllCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(context, colorScheme, textTheme, isDark),
      body: Stack(
        children: [
          // Magical gradient background
          _buildMagicalBackground(context, colorScheme, isDark),

          // Main content
          SafeArea(
            child: BlocBuilder<AllCategoriesCubit, AllCategoriesState>(
              builder: (context, state) {
                if (state is AllCategoriesLoading) {
                  return _buildMagicalLoading(colorScheme);
                }

                if (state is AllCategoriesLoaded) {
                  return RefreshIndicator(
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    displacement: 80,
                    strokeWidth: 3,
                    triggerMode: RefreshIndicatorTriggerMode.onEdge,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await context.read<AllCategoriesCubit>().refresh();
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        decelerationRate: ScrollDecelerationRate.fast,
                      ),
                      slivers: [
                        // Magical Header with Action Buttons
                        _buildMagicalHeader(
                          context,
                          state,
                          colorScheme,
                          textTheme,
                          isDark,
                        ),

                        // Categories List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSize.paddingMedium,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final category = state.categories[index];
                                return RepaintBoundary(
                                  child: _MagicalCategoryCard(
                                    category: category,
                                    totalStorage: state.totalStorage,
                                    index: index,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _navigateToCategoryFiles(context, category);
                                    },
                                  ),
                                );
                              },
                              childCount: state.categories.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: false, // We're adding manually
                            ),
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: AppSize.paddingXLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AllCategoriesError) {
                  return _buildMagicalError(
                    context,
                    state,
                    colorScheme,
                    textTheme,
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
    bool isDark,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface.withValues(alpha: .9),
                    colorScheme.surface.withValues(alpha: .7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: LinearGradient(
                      colors: [
                        colorScheme.outline.withValues(alpha: .05),
                        colorScheme.outline.withValues(alpha: .15),
                        colorScheme.outline.withValues(alpha: .05),
                      ],
                      stops: const [0, 0.5, 1],
                    ).colors.elementAt(1),
                  ),
                ),
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.onSurface,
                  colorScheme.primary,
                  colorScheme.onSurface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'All Categories',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  fontSize: 24,
                ),
              ),
            ),
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: .15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest.withValues(
                            alpha: isDark ? .3 : .6,
                          ),
                          colorScheme.surfaceContainer.withValues(
                            alpha: isDark ? .2 : .4,
                          ),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: .15),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalBackground(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Stack(
      children: [
        // Primary gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.5, -0.3),
              radius: 2.0,
              colors: [
                colorScheme.primaryContainer.withValues(
                  alpha: isDark ? .05 : .1,
                ),
                colorScheme.surface,
                colorScheme.secondaryContainer.withValues(
                  alpha: isDark ? .03 : .08,
                ),
                colorScheme.tertiaryContainer.withValues(
                  alpha: isDark ? .02 : .05,
                ),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Floating orbs
        Positioned(
          top: 150,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
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
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: .06),
                  colorScheme.secondary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          left: 50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.tertiary.withValues(alpha: .05),
                  colorScheme.tertiary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Custom pattern - optimized
        if (!isDark)  // Only show pattern in light mode for performance
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _OptimizedAllCategoriesBackgroundPainter(
                primaryColor: colorScheme.primary.withValues(alpha: .02),
                secondaryColor: colorScheme.secondary.withValues(alpha: .01),
              ),
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
          // Layered loading indicator
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: .1),
                        colorScheme.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: .2),
                      width: 2,
                    ),
                  ),
                ),
                // Inner circle
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: .5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [colorScheme.onSurface, colorScheme.primary],
            ).createShader(bounds),
            child: Text(
              'Loading Categories...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalHeader(
    BuildContext context,
    AllCategoriesLoaded state,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSize.paddingLarge,
          AppSize.paddingXLarge,
          AppSize.paddingLarge,
          AppSize.paddingMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: .1),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(
                        alpha: isDark ? .12 : .2,
                      ),
                      colorScheme.secondaryContainer.withValues(
                        alpha: isDark ? .08 : .15,
                      ),
                      colorScheme.tertiaryContainer.withValues(
                        alpha: isDark ? .05 : .1,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: .15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: .2),
                                colorScheme.primary.withValues(alpha: .05),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: .3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            size: 24,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSize.paddingMedium),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.categories.length} Categories',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Storage Used',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(
                              red: colorScheme.primary.r * 0.85,
                              green: colorScheme.primary.g * 0.85,
                              blue: colorScheme.primary.b * 0.85,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: .3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Text(
                        SizeFormatter.formatBytes(state.totalStorage),
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 16,
                        ),
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

  Widget _buildMagicalError(
    BuildContext context,
    AllCategoriesError state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.errorContainer.withValues(alpha: .15),
                    colorScheme.errorContainer.withValues(alpha: 0),
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
                        colorScheme.error.withValues(alpha: .2),
                        colorScheme.errorContainer.withValues(alpha: .3),
                      ],
                    ),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingLarge),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.error,
                  colorScheme.error.withValues(alpha: .7),
                ],
              ).createShader(bounds),
              child: Text(
                'Something went wrong',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              state.message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategoryFiles(BuildContext context, Category category) {
    final categoryName = category.name.toLowerCase();
    
    // Check if this is a media category (Images, Videos, Audio)
    // These require SAF-based scanning due to policy compliance
    if (categoryName == 'images' || categoryName == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaScannerScreen(
            mediaType: MediaType.images,
            categoryName: 'Images',
          ),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<AllCategoriesCubit>().refresh();
        }
      });
    } else if (categoryName == 'videos' || categoryName == 'video') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaScannerScreen(
            mediaType: MediaType.videos,
            categoryName: 'Videos',
          ),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<AllCategoriesCubit>().refresh();
        }
      });
    } else if (categoryName == 'audio' || categoryName == 'music') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaScannerScreen(
            mediaType: MediaType.audio,
            categoryName: 'Audio',
          ),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<AllCategoriesCubit>().refresh();
        }
      });
    } else if (categoryName == 'documents' || categoryName == 'document') {
      // Navigate to DocumentScannerScreen for Documents category
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<DocumentScanCubit>()..checkSavedFolder(),
            child: const DocumentScannerScreen(),
          ),
        ),
      ).then((_) {
        // Refresh categories when returning from document scanner
        if (context.mounted) {
          context.read<AllCategoriesCubit>().refresh();
        }
      });
    } else if (categoryName == 'others' || categoryName == 'other') {
      // Navigate to OthersScannerScreen for Others category
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<OthersScanCubit>()..checkSavedFolder(),
            child: const OthersScannerScreen(),
          ),
        ),
      ).then((_) {
        // Refresh categories when returning from others scanner
        if (context.mounted) {
          context.read<AllCategoriesCubit>().refresh();
        }
      });
    } else {
      // Navigate to regular category details for Apps and other categories
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CategoryDetailsScreen(category: category),
        ),
      );
    }
  }
}

// Enhanced Category Card with more magical effects
class _MagicalCategoryCard extends StatefulWidget {
  final Category category;
  final int totalStorage;
  final int index;
  final VoidCallback onTap;

  const _MagicalCategoryCard({
    required this.category,
    required this.totalStorage,
    required this.index,
    required this.onTap,
  });

  @override
  State<_MagicalCategoryCard> createState() => _MagicalCategoryCardState();
}

class _MagicalCategoryCardState extends State<_MagicalCategoryCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  
  // Cache expensive calculations
  late final double _percentage;
  late final String _formattedSize;
  late final String _percentageString;
  
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pre-calculate values
    _percentage = widget.totalStorage > 0
        ? (widget.category.sizeInBytes / widget.totalStorage * 100)
        : 0.0;
    _formattedSize = SizeFormatter.formatBytes(widget.category.sizeInBytes.toInt());
    _percentageString = '${_percentage.toStringAsFixed(1)}%';
    
    // Setup hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    
    if (!mounted) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSize.paddingMedium),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? 0.95 : _hoverAnimation.value,
                child: child!,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: CategoryUIMapper.getColor(widget.category.id).withValues(
                      alpha: _isHovered ? .2 : .1,
                    ),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 8),
                    spreadRadius: _isHovered ? -2 : -5,
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                      blurRadius: 50,
                      offset: const Offset(0, 15),
                      spreadRadius: -10,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(28),
                      splashColor: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .08),
                      highlightColor: CategoryUIMapper.getColor(widget.category.id).withValues(
                        alpha: .05,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CategoryUIMapper.getColor(widget.category.id).withValues(
                                alpha: isDark ? .08 : .12,
                              ),
                              colorScheme.surfaceContainer.withValues(
                                alpha: _isHovered ? .8 : .6,
                              ),
                              colorScheme.surface.withValues(
                                alpha: _isHovered ? .9 : .7,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _isHovered
                                ? CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .25)
                                : colorScheme.outline.withValues(alpha: .1),
                            width: _isHovered ? 2 : 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Enhanced icon with multiple layers
                                _buildMagicalIcon(),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                              colors: _isHovered
                                                  ? [
                                                      CategoryUIMapper.getColor(widget.category.id),
                                                      CategoryUIMapper.getColor(widget.category.id)
                                                          .withValues(
                                                            red: math.min(
                                                              1.0,
                                                              CategoryUIMapper.getColor(widget.category.id)
                                                                      .r *
                                                                  1.2,
                                                            ),
                                                            green: math.min(
                                                              1.0,
                                                              CategoryUIMapper.getColor(widget.category.id)
                                                                      .g *
                                                                  1.2,
                                                            ),
                                                            blue: math.min(
                                                              1.0,
                                                              CategoryUIMapper.getColor(widget.category.id)
                                                                      .b *
                                                                  1.2,
                                                            ),
                                                          ),
                                                    ]
                                                  : [
                                                      colorScheme.onSurface,
                                                      colorScheme.onSurface,
                                                    ],
                                            ).createShader(bounds),
                                        child: Text(
                                          widget.category.name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.3,
                                                fontSize: _isHovered ? 18 : 17,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildFileCountChip(
                                        colorScheme,
                                        textTheme,
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStorageInfo(
                                  colorScheme,
                                  textTheme,
                                  _percentage,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildMagicalProgressBar(_percentage, colorScheme),
                            if (_isHovered)
                              _buildHoverHint(colorScheme, textTheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalIcon() {
    return Hero(
      tag: 'category-icon-${widget.category.name}',
      child: SizedBox(
        width: _isHovered ? 64 : 60,
        height: _isHovered ? 64 : 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: _isHovered ? 64 : 60,
              height: _isHovered ? 64 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3),
                    CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                    CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            // Main icon container
            Container(
              width: _isHovered ? 52 : 48,
              height: _isHovered ? 52 : 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2),
                    CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CategoryUIMapper.getColor(widget.category.id).withValues(
                    alpha: _isHovered ? .4 : .3,
                  ),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .4),
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                CategoryUIMapper.getIcon(widget.category.id),
                color: CategoryUIMapper.getColor(widget.category.id),
                size: _isHovered ? 32 : 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCountChip(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: .2),
            colorScheme.primaryContainer.withValues(alpha: .1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: .15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '${widget.category.fileCount} files',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              CategoryUIMapper.getColor(widget.category.id),
              CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .8),
            ],
          ).createShader(bounds),
          child: Text(
            _formattedSize,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isHovered ? 12 : 10,
            vertical: _isHovered ? 8 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CategoryUIMapper.getColor(widget.category.id),
                CategoryUIMapper.getColor(widget.category.id).withValues(
                  red: CategoryUIMapper.getColor(widget.category.id).r * 0.8,
                  green: CategoryUIMapper.getColor(widget.category.id).g * 0.8,
                  blue: CategoryUIMapper.getColor(widget.category.id).b * 0.8,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _percentageString,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalProgressBar(double percentage, ColorScheme colorScheme) {
    return Stack(
      children: [
        // Background track
        Container(
          height: 14,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: .4),
                colorScheme.surfaceContainerHighest.withValues(alpha: .6),
              ],
            ),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: .1),
              width: 1,
            ),
          ),
        ),
        // Progress fill with gradient
        FractionallySizedBox(
          widthFactor: percentage / 100,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CategoryUIMapper.getColor(widget.category.id),
                  CategoryUIMapper.getColor(widget.category.id).withValues(
                    red: CategoryUIMapper.getColor(widget.category.id).r * 0.85,
                    green: CategoryUIMapper.getColor(widget.category.id).g * 0.85,
                    blue: CategoryUIMapper.getColor(widget.category.id).b * 0.85,
                  ),
                  CategoryUIMapper.getColor(widget.category.id).withValues(
                    red: CategoryUIMapper.getColor(widget.category.id).r * 0.7,
                    green: CategoryUIMapper.getColor(widget.category.id).g * 0.7,
                    blue: CategoryUIMapper.getColor(widget.category.id).b * 0.7,
                  ),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .4),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        // Shine effect overlay
        if (_isHovered)
          FractionallySizedBox(
            widthFactor: percentage / 100,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: .2),
                    Colors.white.withValues(alpha: 0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHoverHint(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                CategoryUIMapper.getColor(widget.category.id),
                CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .7),
              ],
            ).createShader(bounds),
            child: Text(
              'View all ${widget.category.name.toLowerCase()} files',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2),
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: CategoryUIMapper.getColor(widget.category.id),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized background painter
class _OptimizedAllCategoriesBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _OptimizedAllCategoriesBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw simplified pattern with larger spacing
    const spacing = 150.0;
    paint.color = primaryColor;
    
    // Only draw visible diamonds
    final startX = 0.0;
    final endX = size.width;
    final startY = 0.0;
    final endY = size.height;

    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        // Skip if diamond would be completely outside canvas
        if (x - spacing/2 > endX && x + spacing/2 < startX) continue;
        if (y - spacing/2 > endY && y + spacing/2 < startY) continue;
        
        final path = Path();
        path.moveTo(x, y - spacing / 2);
        path.lineTo(x + spacing / 2, y);
        path.lineTo(x, y + spacing / 2);
        path.lineTo(x - spacing / 2, y);
        path.close();

        canvas.drawPath(path, paint);
      }
    }

    // Draw fewer circles
    paint.color = secondaryColor;
    paint.style = PaintingStyle.fill;

    for (double x = startX; x <= endX; x += spacing * 2) {
      for (double y = startY; y <= endY; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
