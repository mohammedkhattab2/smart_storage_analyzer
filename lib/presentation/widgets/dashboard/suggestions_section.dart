import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/entities/cleaning_suggestion.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/suggestions/suggestions_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/suggestions/suggestions_state.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

/// Dashboard section that displays smart cleaning suggestions.
///
/// This widget contains **no business logic**:
/// - It does not compute thresholds or analyze data.
/// - It only reacts to [SuggestionsCubit] state and triggers navigation.
class SuggestionsSection extends StatelessWidget {
  const SuggestionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider<SuggestionsCubit>(
      create: (_) => sl<SuggestionsCubit>()..loadSuggestions(),
      child: BlocBuilder<SuggestionsCubit, SuggestionsState>(
        builder: (context, state) {
          if (state is SuggestionsLoading || state is SuggestionsInitial) {
            return _SuggestionsSkeleton(colorScheme: colorScheme);
          }

          if (state is SuggestionsError) {
            return _SuggestionsError(message: state.message);
          }

          if (state is SuggestionsLoaded) {
            if (state.suggestions.isEmpty) {
              // No suggestions to show - render nothing to keep dashboard clean.
              return const SizedBox.shrink();
            }

            return _SuggestionsList(
              suggestions: state.suggestions,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SuggestionsSkeleton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SuggestionsSkeleton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Row(
          children: List.generate(2, (index) {
            return Expanded(
              child: Container(
                height: 90,
                margin: EdgeInsets.only(
                  right: index == 0 ? AppSize.paddingSmall : 0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(AppSize.radiusMedium),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SuggestionsError extends StatelessWidget {
  final String message;

  const _SuggestionsError({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSize.paddingMedium),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<CleaningSuggestion> suggestions;

  const _SuggestionsList({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Suggestions',
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Column(
          children: suggestions
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
                  child: _SuggestionCard(
                    suggestion: s,
                    colorScheme: colorScheme,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final CleaningSuggestion suggestion;
  final ColorScheme colorScheme;

  const _SuggestionCard({
    required this.suggestion,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _mapActionTypeToIcon(suggestion.actionType);
    final buttonLabel = _mapActionTypeToButtonLabel(suggestion.actionType);

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withValues(alpha: .12),
            child: Icon(
              iconData,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSize.paddingSmall),
          FilledButton.tonal(
            onPressed: () => _handleAction(context, suggestion.actionType),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  IconData _mapActionTypeToIcon(CleaningSuggestionActionType type) {
    switch (type) {
      case CleaningSuggestionActionType.cleanCache:
        return Icons.auto_delete_rounded;
      case CleaningSuggestionActionType.showUnusedApps:
        return Icons.apps_rounded;
      case CleaningSuggestionActionType.showLargeFiles:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _mapActionTypeToButtonLabel(CleaningSuggestionActionType type) {
    switch (type) {
      case CleaningSuggestionActionType.cleanCache:
        return 'Clean';
      case CleaningSuggestionActionType.showUnusedApps:
        return 'Review';
      case CleaningSuggestionActionType.showLargeFiles:
        return 'View';
    }
  }

  void _handleAction(BuildContext context, CleaningSuggestionActionType type) {
    switch (type) {
      case CleaningSuggestionActionType.cleanCache:
        // Navigate to deep storage analysis / cleanup flow
        context.push(AppRoutes.storageAnalysis);
        break;
      case CleaningSuggestionActionType.showUnusedApps:
        // Navigate to Unused Apps screen
        context.push(AppRoutes.unusedApps);
        break;
      case CleaningSuggestionActionType.showLargeFiles:
        // Navigate to file manager focused on large files tab
        context.push(
          AppRoutes.fileManager,
          extra: FileCategory.large,
        );
        break;
    }
  }
}