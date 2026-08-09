import 'package:equatable/equatable.dart';

/// High-level smart cleaning suggestion shown on the dashboard.
///
/// Domain-only representation (no Flutter imports).
class CleaningSuggestion extends Equatable {
  final String id;
  final String title;
  final String description;
  final CleaningSuggestionActionType actionType;
  /// Potential space saved in bytes if the user completes this action.
  final int potentialSpaceSaved;

  const CleaningSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.potentialSpaceSaved,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        actionType,
        potentialSpaceSaved,
      ];
}

/// What action should be triggered for this suggestion.
///
/// The actual navigation / UI behaviour is handled in the presentation layer.
enum CleaningSuggestionActionType {
  cleanCache,
  showUnusedApps,
  showLargeFiles,
}