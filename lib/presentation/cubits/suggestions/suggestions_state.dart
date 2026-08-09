import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/cleaning_suggestion.dart';

abstract class SuggestionsState extends Equatable {
  const SuggestionsState();

  @override
  List<Object?> get props => [];
}

class SuggestionsInitial extends SuggestionsState {
  const SuggestionsInitial();
}

class SuggestionsLoading extends SuggestionsState {
  const SuggestionsLoading();
}

class SuggestionsLoaded extends SuggestionsState {
  final List<CleaningSuggestion> suggestions;

  const SuggestionsLoaded({required this.suggestions});

  @override
  List<Object?> get props => [suggestions];
}

class SuggestionsError extends SuggestionsState {
  final String message;

  const SuggestionsError(this.message);

  @override
  List<Object?> get props => [message];
}