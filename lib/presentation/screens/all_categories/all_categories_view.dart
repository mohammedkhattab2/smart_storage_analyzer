import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/category_details/category_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: colorScheme.surface.withValues(alpha: .75),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'All Categories',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
              leading: Container(
                margin: const EdgeInsets.all(8),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer.withValues(
                          alpha: isDark ? .3 : .6,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: .1),
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.outline.withValues(alpha: .05),
                        colorScheme.outline.withValues(alpha: .15),
                        colorScheme.outline.withValues(alpha: .05),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AllCategoriesCubit, AllCategoriesState>(
          builder: (context, state) {
            if (state is AllCategoriesLoading) {
              return const Center(child: LoadingWidget());
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSize.paddingLarge,
                            AppSize.paddingXLarge,
                            AppSize.paddingLarge,
                            AppSize.paddingMedium,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSize.paddingLarge,
                                  vertical: AppSize.paddingMedium + 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primaryContainer
                                          .withValues(alpha:  isDark ? .08 : .15,
                                          ),
                                      colorScheme.secondaryContainer
                                          .withValues(alpha:  isDark ? .05 : .1,
                                          ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ),
                                  border: Border.all(
                                    color: colorScheme.outline
                                        .withValues(alpha:  .1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha:  .1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.category_rounded,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppSize.paddingMedium,
                                        ),
                                        Text(
                                          '${state.categories.length} Categories',
                                          style: textTheme.bodyLarge
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight:
                                                    FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.primary
                                                .withValues(
                                                  red:
                                                      colorScheme
                                                          .primary
                                                          .r *
                                                      0.9,
                                                  green:
                                                      colorScheme
                                                          .primary
                                                          .g *
                                                      0.9,
                                                  blue:
                                                      colorScheme
                                                          .primary
                                                          .b *
                                                      0.9,
                                                ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha:  .2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        SizeFormatter.formateBytes(
                                          state.totalStorage,
                                        ),
                                        style: textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                              letterSpacing: 0.5,
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
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSize.paddingMedium,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final category = state.categories[index];

                            return _CategoryDetailCard(
                              category: category,
                              totalStorage: state.totalStorage,
                              index: index,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _navigateToCategoryFiles(context, category);
                              },
                            );
                          }, childCount: state.categories.length),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: AppSize.paddingXLarge),
                      ),
                    ],
                  ),
                );
              }

              if (state is AllCategoriesError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSize.paddingXLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: colorScheme.error.withValues(alpha: .6),
                        ),
                        const SizedBox(height: AppSize.paddingLarge),
                        Text(
                          'Something went wrong',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
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

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _navigateToCategoryFiles(BuildContext context, Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetailsScreen(category: category),
      ),
    );
  }
}

class _CategoryDetailCard extends StatefulWidget {
  final Category category;
  final int totalStorage;
  final int index;
  final VoidCallback onTap;

  const _CategoryDetailCard({
    required this.category,
    required this.totalStorage,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryDetailCard> createState() => _CategoryDetailCardState();
}

class _CategoryDetailCardState extends State<_CategoryDetailCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final percentage = widget.totalStorage > 0
        ? (widget.category.sizeInBytes / widget.totalStorage * 100)
        : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
        },
        onExit: (_) {
          setState(() => _isHovered = false);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSize.paddingMedium),
          child: Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: widget.category.color.withValues(alpha: .15),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                ],
              ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(24),
                          splashColor: widget.category.color.withValues(alpha:  .08,
                          ),
                          highlightColor: widget.category.color.withValues(alpha:  .05,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(
                              _isHovered
                                  ? AppSize.paddingLarge + 2
                                  : AppSize.paddingLarge,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _isHovered
                                      ? colorScheme.surfaceContainer.withValues(
                                          alpha: .95,
                                        )
                                      : colorScheme.surface.withValues(
                                          alpha: isDark ? .6 : .8,
                                        ),
                                  _isHovered
                                      ? colorScheme.surface.withValues(
                                          alpha: .9,
                                        )
                                      : colorScheme.surfaceContainer.withValues(
                                          alpha: isDark ? .4 : .6,
                                        ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isHovered
                                    ? widget.category.color.withValues(alpha: .2)
                                    : colorScheme.outline.withValues(alpha: .08),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag:
                                          'category-icon-${widget.category.name}',
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          _isHovered ? 16 : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [
                                              widget.category.color.withValues(
                                                alpha: _isHovered ? .2 : .15,
                                              ),
                                              widget.category.color.withValues(
                                                alpha: _isHovered ? .08 : .05,
                                              ),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: widget.category.color.withValues(
                                              alpha: _isHovered ? .3 : .15,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          widget.category.icon,
                                          color: widget.category.color,
                                          size: _isHovered ? 30 : 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppSize.paddingMedium + 4,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.category.name,
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.onSurface,
                                                  letterSpacing: -0.3,
                                                  fontSize: 17,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha:  .1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.folder_rounded,
                                                  size: 14,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${widget.category.fileCount} files',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          SizeFormatter.formateBytes(
                                            widget.category.sizeInBytes
                                                .toInt(),
                                          ),
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: colorScheme.onSurface,
                                            fontSize: _isHovered ? 22 : 20,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: _isHovered ? 10 : 8,
                                            vertical: _isHovered ? 6 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                widget.category.color.withValues(
                                                  alpha: .15,
                                                ),
                                                widget.category.color.withValues(
                                                  alpha: .08,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: widget.category.color
                                                  .withValues(alpha: .2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                              color: widget.category.color,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSize.paddingLarge),
                                // Enhanced Progress bar with glassmorphism
                                Stack(
                                  children: [
                                    Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha:  .5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.outline.withValues(alpha:  .1,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage / 100,
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.category.color,
                                              widget.category.color.withValues(
                                                red: widget.category.color.r *
                                                    0.8,
                                                green: widget.category.color.g *
                                                    0.8,
                                                blue: widget.category.color.b *
                                                    0.8,
                                              ),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.category.color
                                                  .withValues(alpha: .3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Interactive hint
                                if (_isHovered)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: AppSize.paddingMedium,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'View all ${widget.category.name.toLowerCase()} files',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: widget.category.color,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: widget.category.color
                                                .withValues(alpha: .1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: widget.category.color,
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
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
