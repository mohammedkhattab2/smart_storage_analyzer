part of 'storage_analysis_cubit.dart';

abstract class StorageAnalysisState extends Equatable {
  const StorageAnalysisState();

  @override
  List<Object?> get props => [];
}

class StorageAnalysisInitial extends StorageAnalysisState {}

class StorageAnalysisInProgress extends StorageAnalysisState {
  final String message;
  final double progress;

  const StorageAnalysisInProgress({
    required this.message,
    required this.progress,
  });

  @override
  List<Object> get props => [message, progress];
}

class StorageAnalysisCompleted extends StorageAnalysisState {
  final StorageAnalysisResults results;

  const StorageAnalysisCompleted({required this.results});

  @override
  List<Object> get props => [results];
}

class StorageAnalysisError extends StorageAnalysisState {
  final String message;

  const StorageAnalysisError({required this.message});

  @override
  List<Object> get props => [message];
}

class StorageAnalysisCancelled extends StorageAnalysisState {}
