import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingLoading extends OnboardingState {}

class OnboardingPageState extends OnboardingState {
  final int currentPage;
  const OnboardingPageState({required this.currentPage});

  @override
  List<Object?> get props => [currentPage];
}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}
