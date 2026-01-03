import 'package:flutter/material.dart';

/// Theme mode options for the app
enum AppThemeMode {
  system('System', Icons.brightness_auto),
  light('Light', Icons.light_mode),
  dark('Dark', Icons.dark_mode);

  final String label;
  final IconData icon;

  const AppThemeMode(this.label, this.icon);

  /// Convert to Flutter's ThemeMode
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Get from string value
  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  /// Convert to string for storage
  String toStorageString() {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }
}
