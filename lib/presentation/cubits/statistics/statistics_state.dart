import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();
  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final StorageStatistics statistics;
  final List<String> availablePeriods;
  const StatisticsLoaded({
    required this.statistics,
    required this.availablePeriods,
  });

  @override
  List<Object?> get props => [statistics, availablePeriods];
}

class StatisticsError extends StatisticsState {
  final String message;
  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
