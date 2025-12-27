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
class dashboardLoaded extends DashboardState {
  final StorageInfo storageInfo;
  final List<Category> categories;
  const dashboardLoaded({required this.storageInfo, required this.categories});
  @override
  List<Object> get props => [storageInfo, categories];
}
/// analyaing state
class DashboardAnalyzing extends DashboardState {
  final String message;
  const DashboardAnalyzing({this.message = "Analyzing your storage..."});
  @override
  List <Object> get props => [message];
}
/// error state
class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});
  @override
  List<Object> get props => [message];
}
