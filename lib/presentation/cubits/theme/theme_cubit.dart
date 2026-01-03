import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_storage_analyzer/core/theme/app_theme_mode.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_state.dart';

/// Manages app theme state and persistence
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeModeKey = 'theme_mode';

  ThemeCubit() : super(const ThemeState());

  /// Load saved theme preference
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      final themeMode = AppThemeMode.fromString(savedMode);

      emit(state.copyWith(themeMode: themeMode, isLoading: false));
    } catch (e) {
      // Default to system theme if error
      emit(state.copyWith(themeMode: AppThemeMode.system, isLoading: false));
    }
  }

  /// Update theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    // Update UI immediately for responsiveness
    emit(state.copyWith(themeMode: mode));

    try {
      // Persist the change
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toStorageString());
    } catch (e) {
      // If save fails, we keep the UI updated
      // Could show error message if needed
    }
  }

  /// Get actual brightness based on theme mode and system brightness
  Brightness getActualBrightness(BuildContext context) {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    return getActualBrightness(context) == Brightness.dark;
  }
}
