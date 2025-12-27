import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/presentation/cubits/onboarding/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingPageState(currentPage: 0));

  void changePage(int page) {
    emit(OnboardingPageState(currentPage: page));
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("hasSeenOnboarding", true);
      emit(OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError("message"));
    }
  }
}
