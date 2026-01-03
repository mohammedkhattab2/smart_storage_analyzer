import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';

abstract class AllCategoriesState extends Equatable {
  const AllCategoriesState();

  @override
  List<Object?> get props => [];
}

class AllCategoriesInitial extends AllCategoriesState {}

class AllCategoriesLoading extends AllCategoriesState {}

class AllCategoriesLoaded extends AllCategoriesState {
  final List<Category> categories;
  final int totalStorage;

  const AllCategoriesLoaded({
    required this.categories,
    required this.totalStorage,
  });

  @override
  List<Object?> get props => [categories, totalStorage];
}

class AllCategoriesError extends AllCategoriesState {
  final String message;

  const AllCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
