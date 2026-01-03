import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

/// The initial state
class DashboardInitial extends DashboardState {}

/// loading state
class DashboardLoading extends DashboardState {}

/// loaded state
class DashboardLoaded extends DashboardState {
  final StorageInfo storageInfo;
  final List<Category> categories;
  const DashboardLoaded({required this.storageInfo, required this.categories});
  @override
  List<Object> get props => [storageInfo, categories];
}

/// analyzing state with optional progress
class DashboardAnalyzing extends DashboardState {
  final String message;
  final StorageInfo? storageInfo;
  final List<Category>? categories;
  final double? progress;

  const DashboardAnalyzing({
    this.message = "Analyzing your storage...",
    this.storageInfo,
    this.categories,
    this.progress,
  });

  @override
  List<Object?> get props => [message, storageInfo, categories, progress];
}

/// error state
class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});
  @override
  List<Object> get props => [message];
}
