import 'package:flutter/material.dart';

/// Material 3 Color Schemes for Light and Dark themes
/// Following Google's Material You design principles
class AppColorSchemes {
  AppColorSchemes._();

  // === Light Color Scheme ===
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary colors - Blue tone for storage/tech feeling
    primary: Color(0xFF1565C0), // Deep blue
    onPrimary: Color(0xFFFFFFFF), // White on primary
    primaryContainer: Color(0xFFD1E4FF), // Light blue container
    onPrimaryContainer: Color(0xFF001D36), // Dark blue on container
    inversePrimary: Color(0xFF90CAF9), // Light blue inverse
    // Secondary colors - Teal accent
    secondary: Color(0xFF00838F), // Teal
    onSecondary: Color(0xFFFFFFFF), // White on secondary
    secondaryContainer: Color(0xFFB2EBF2), // Light teal container
    onSecondaryContainer: Color(0xFF002022), // Dark teal on container
    // Tertiary colors - Purple accent for premium features
    tertiary: Color(0xFF6750A4), // Material purple
    onTertiary: Color(0xFFFFFFFF), // White on tertiary
    tertiaryContainer: Color(0xFFE7DEFF), // Light purple container
    onTertiaryContainer: Color(0xFF21005D), // Dark purple on container
    // Error colors
    error: Color(0xFFD32F2F), // Material red
    onError: Color(0xFFFFFFFF), // White on error
    errorContainer: Color(0xFFF9DEDC), // Light red container
    onErrorContainer: Color(0xFF410E0B), // Dark red on container
    // Background colors - Soft, not harsh white
    surface: Color(0xFFF5F7FA), // Very light gray-blue
    onSurface: Color(0xFF1A1C1E), // Almost black
    surfaceContainerLowest: Color(0xFFFFFFFF), // Pure white
    surfaceContainerLow: Color(0xFFF7F9FC), // Off white
    surfaceContainer: Color(0xFFF1F3F6), // Light gray
    surfaceContainerHigh: Color(0xFFEBEDF0), // Gray
    surfaceContainerHighest: Color(0xFFE1E3E6), // Darker gray
    // Additional colors
    outline: Color(0xFF73777C), // Medium gray for borders
    outlineVariant: Color(0xFFC3C6CB), // Light gray for subtle borders
    shadow: Color(0xFF000000), // Black for shadows
    scrim: Color(0xFF000000), // Black for scrims
    inverseSurface: Color(0xFF2E3133), // Dark gray
    onInverseSurface: Color(0xFFF0F2F4), // Light gray on dark
    surfaceTint: Color(0xFF1565C0), // Primary tint
  );

  // === Dark Color Scheme ===
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary colors - Lighter blue for dark mode
    primary: Color(0xFF90CAF9), // Light blue
    onPrimary: Color(0xFF003258), // Dark blue on primary
    primaryContainer: Color(0xFF004880), // Medium blue container
    onPrimaryContainer: Color(0xFFD1E4FF), // Light blue on container
    inversePrimary: Color(0xFF1565C0), // Deep blue inverse
    // Secondary colors - Lighter teal for dark mode
    secondary: Color(0xFF4DD0E1), // Light teal
    onSecondary: Color(0xFF003739), // Dark teal on secondary
    secondaryContainer: Color(0xFF004F53), // Medium teal container
    onSecondaryContainer: Color(0xFFB2EBF2), // Light teal on container
    // Tertiary colors - Lighter purple for dark mode
    tertiary: Color(0xFFCBBEFF), // Light purple
    onTertiary: Color(0xFF332074), // Dark purple on tertiary
    tertiaryContainer: Color(0xFF4A398B), // Medium purple container
    onTertiaryContainer: Color(0xFFE7DEFF), // Light purple on container
    // Error colors
    error: Color(0xFFF2B8B5), // Light red
    onError: Color(0xFF601410), // Dark red on error
    errorContainer: Color(0xFF8C1D18), // Medium red container
    onErrorContainer: Color(0xFFF9DEDC), // Light red on container
    // Background colors - True dark, not gray
    surface: Color(0xFF0F1419), // Very dark blue-black
    onSurface: Color(0xFFE2E3E5), // Light gray
    surfaceContainerLowest: Color(0xFF0A0E13), // Darkest
    surfaceContainerLow: Color(0xFF181C21), // Very dark
    surfaceContainer: Color(0xFF1C2026), // Dark
    surfaceContainerHigh: Color(0xFF262A30), // Medium dark
    surfaceContainerHighest: Color(0xFF31353B), // Less dark
    // Additional colors
    outline: Color(0xFF8D9096), // Medium gray for borders
    outlineVariant: Color(0xFF43474C), // Dark gray for subtle borders
    shadow: Color(0xFF000000), // Black for shadows
    scrim: Color(0xFF000000), // Black for scrims
    inverseSurface: Color(0xFFE2E3E5), // Light gray
    onInverseSurface: Color(0xFF2E3133), // Dark gray on light
    surfaceTint: Color(0xFF90CAF9), // Primary tint
  );

  // === Semantic Colors (shared between themes) ===

  // Success colors
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);
  static const Color successContainerLight = Color(0xFFE8F5E9);
  static const Color successContainerDark = Color(0xFF1B5E20);

  // Warning colors
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color warningContainerLight = Color(0xFFFFF3E0);
  static const Color warningContainerDark = Color(0xFFE65100);

  // Info colors
  static const Color infoLight = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF64B5F6);
  static const Color infoContainerLight = Color(0xFFE3F2FD);
  static const Color infoContainerDark = Color(0xFF0D47A1);

  // === Category Colors (optimized for both themes) ===

  // Images - Purple
  static const Color imageCategoryLight = Color(0xFF9C27B0);
  static const Color imageCategoryDark = Color(0xFFBA68C8);

  // Videos - Pink
  static const Color videoCategoryLight = Color(0xFFE91E63);
  static const Color videoCategoryDark = Color(0xFFEC407A);

  // Audio - Teal
  static const Color audioCategoryLight = Color(0xFF009688);
  static const Color audioCategoryDark = Color(0xFF26A69A);

  // Documents - Indigo
  static const Color documentCategoryLight = Color(0xFF3F51B5);
  static const Color documentCategoryDark = Color(0xFF5C6BC0);

  // Apps - Blue Grey
  static const Color appsCategoryLight = Color(0xFF607D8B);
  static const Color appsCategoryDark = Color(0xFF78909C);

  // Others - Brown
  static const Color othersCategoryLight = Color(0xFF795548);
  static const Color othersCategoryDark = Color(0xFF8D6E63);

  // === Gradient Colors ===
  static const List<Color> premiumGradientLight = [
    Color(0xFF6750A4),
    Color(0xFF9C27B0),
  ];

  static const List<Color> premiumGradientDark = [
    Color(0xFF9580DB),
    Color(0xFFBA68C8),
  ];

  static const List<Color> storageGradientLight = [
    Color(0xFF1565C0),
    Color(0xFF2196F3),
  ];

  static const List<Color> storageGradientDark = [
    Color(0xFF64B5F6),
    Color(0xFF90CAF9),
  ];
}

/// Extension for easy access to category colors based on theme
extension CategoryColors on ColorScheme {
  Color get imageCategory => brightness == Brightness.light
      ? AppColorSchemes.imageCategoryLight
      : AppColorSchemes.imageCategoryDark;

  Color get videoCategory => brightness == Brightness.light
      ? AppColorSchemes.videoCategoryLight
      : AppColorSchemes.videoCategoryDark;

  Color get audioCategory => brightness == Brightness.light
      ? AppColorSchemes.audioCategoryLight
      : AppColorSchemes.audioCategoryDark;

  Color get documentCategory => brightness == Brightness.light
      ? AppColorSchemes.documentCategoryLight
      : AppColorSchemes.documentCategoryDark;

  Color get appsCategory => brightness == Brightness.light
      ? AppColorSchemes.appsCategoryLight
      : AppColorSchemes.appsCategoryDark;

  Color get othersCategory => brightness == Brightness.light
      ? AppColorSchemes.othersCategoryLight
      : AppColorSchemes.othersCategoryDark;
}

/// Extension for semantic colors
extension SemanticColors on ColorScheme {
  Color get success => brightness == Brightness.light
      ? AppColorSchemes.successLight
      : AppColorSchemes.successDark;

  Color get successContainer => brightness == Brightness.light
      ? AppColorSchemes.successContainerLight
      : AppColorSchemes.successContainerDark;

  Color get warning => brightness == Brightness.light
      ? AppColorSchemes.warningLight
      : AppColorSchemes.warningDark;

  Color get warningContainer => brightness == Brightness.light
      ? AppColorSchemes.warningContainerLight
      : AppColorSchemes.warningContainerDark;

  Color get info => brightness == Brightness.light
      ? AppColorSchemes.infoLight
      : AppColorSchemes.infoDark;

  Color get infoContainer => brightness == Brightness.light
      ? AppColorSchemes.infoContainerLight
      : AppColorSchemes.infoContainerDark;
}

/// Extension for gradient colors
extension GradientColors on ColorScheme {
  List<Color> get premiumGradient => brightness == Brightness.light
      ? AppColorSchemes.premiumGradientLight
      : AppColorSchemes.premiumGradientDark;

  List<Color> get storageGradient => brightness == Brightness.light
      ? AppColorSchemes.storageGradientLight
      : AppColorSchemes.storageGradientDark;
}
