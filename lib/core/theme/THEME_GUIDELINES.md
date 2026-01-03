# Material 3 Theme System Guidelines

## Overview
This Flutter app implements a comprehensive Material 3 (Material You) design system with full support for Light, Dark, and System theme modes. The theme system prioritizes visual excellence, accessibility, and consistent user experience across all screens.

## Color System Architecture

### 1. Material 3 Color Schemes
The app uses two complete Material 3 color schemes defined in `app_color_schemes.dart`:
- **Light Theme**: Soft, professional colors with excellent contrast
- **Dark Theme**: True dark backgrounds (not gray) for OLED displays

### 2. Color Usage Guidelines

#### Primary Colors
- **Light**: Deep blue (#1565C0) - Professional, trustworthy
- **Dark**: Light blue (#90CAF9) - Easy on eyes in dark mode
- **Usage**: Primary actions, active states, brand elements

#### Surface Colors
- **Light**: Soft gray-blue (#F5F7FA) - Not harsh white
- **Dark**: Very dark blue-black (#0F1419) - True dark for battery savings
- **Usage**: Backgrounds, cards, containers

#### Category Colors
Special colors for file categories that adapt to theme:
```dart
// Access via ColorScheme extension:
colorScheme.imageCategory  // Purple tones
colorScheme.videoCategory  // Pink tones
colorScheme.audioCategory  // Teal tones
colorScheme.documentCategory  // Indigo tones
colorScheme.appsCategory  // Blue-gray tones
colorScheme.othersCategory  // Brown tones
```

#### Semantic Colors
```dart
// Access via ColorScheme extension:
colorScheme.success  // Green for positive actions
colorScheme.warning  // Orange for alerts
colorScheme.error  // Red for destructive actions
```

## Implementation Guidelines

### 1. Never Use Hardcoded Colors
```dart
// ❌ Bad
color: Colors.blue
color: Color(0xFF2196F3)
color: AppColors.primary  // Old constant

// ✅ Good
color: Theme.of(context).colorScheme.primary
color: colorScheme.onSurface
```

### 2. Surface Hierarchy
Use the correct surface level for visual hierarchy:
- `surface` - Main background
- `surfaceContainer` - Cards, elevated content
- `surfaceContainerLow` - Subtle elevation
- `surfaceContainerHigh` - Dialogs, modals
- `surfaceContainerHighest` - Highest elevation

### 3. Text Colors
Always pair text with appropriate background:
```dart
// On primary color
Container(
  color: colorScheme.primary,
  child: Text('Text', style: TextStyle(color: colorScheme.onPrimary)),
)

// On surface
Container(
  color: colorScheme.surface,
  child: Text('Text', style: TextStyle(color: colorScheme.onSurface)),
)
```

### 4. Interactive Elements
```dart
// Buttons
ElevatedButton(
  // Uses theme defaults automatically
)

// Custom interactive elements
InkWell(
  borderRadius: BorderRadius.circular(AppSize.radiusMedium),
  child: Container(
    color: colorScheme.secondaryContainer,
    child: Icon(
      icon,
      color: colorScheme.onSecondaryContainer,
    ),
  ),
)
```

## Theme Switching

### User Preferences
The app supports three theme modes:
1. **System** (default) - Follows device theme
2. **Light** - Always light theme
3. **Dark** - Always dark theme

### Implementation
```dart
// Access current theme mode
final themeMode = context.read<ThemeCubit>().state.themeMode;

// Change theme
context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark);

// Check if dark mode
final isDark = context.read<ThemeCubit>().isDarkMode(context);
```

## Widget Guidelines

### 1. Cards
```dart
Card(
  // elevation: 0, // Set by theme
  // color: colorScheme.surfaceContainer, // Set by theme
  child: content,
)
```

### 2. Navigation
Bottom navigation uses `secondaryContainer` for selected state:
```dart
NavigationBar(
  // backgroundColor: colorScheme.surfaceContainer,
  // indicatorColor: colorScheme.secondaryContainer,
)
```

### 3. Dialogs
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    // backgroundColor: colorScheme.surfaceContainerHigh, // Set by theme
    title: Text('Title'),
    content: Text('Content'),
  ),
)
```

## Typography

The app uses Material 3 typography with proper scaling:
- **Display**: Large feature text (57-36sp)
- **Headline**: Section headers (32-24sp)
- **Title**: Component titles (22-14sp)
- **Body**: Regular content (16-12sp)
- **Label**: Small UI text (14-11sp)

## Accessibility

### Contrast Requirements
- All text meets WCAG AA standards
- Interactive elements have sufficient touch targets (48x48dp)
- Colors tested for color-blind accessibility

### Theme Adaptation
- System UI overlays adapt to theme
- Status bar icons change color based on brightness
- Navigation bar matches theme surface

## Best Practices

### 1. Use Theme Extensions
```dart
// Category colors
final imageColor = colorScheme.imageCategory;

// Semantic colors
final errorColor = colorScheme.error;
final errorContainer = colorScheme.errorContainer;
```

### 2. Shadow and Elevation
```dart
// Adaptive shadows
BoxShadow(
  color: brightness == Brightness.dark
    ? Colors.black.withOpacity(0.3)
    : colorScheme.shadow.withOpacity(0.08),
  blurRadius: 20,
)
```

## File Structure

```
lib/core/theme/
├── app_theme.dart          # ThemeData definitions
├── app_color_schemes.dart  # Material 3 color schemes
├── app_theme_mode.dart     # Theme mode enum
└── THEME_GUIDELINES.md     # This file

lib/presentation/cubits/theme/
├── theme_cubit.dart        # Theme state management
└── theme_state.dart        # Theme state model
```

## Testing Checklist

When adding new features or screens:
- [ ] Test in Light mode
- [ ] Test in Dark mode  
- [ ] Test System mode with OS light/dark
- [ ] Verify text readability
- [ ] Check interactive element contrast
- [ ] Validate color consistency
- [ ] Test on OLED displays (true black)
- [ ] Verify shadows and elevations

## Migration from Legacy Colors

If you find old color references:
1. Remove `import 'app_colors.dart'`
2. Add `final colorScheme = Theme.of(context).colorScheme;`
3. Replace colors using this mapping:
   - `AppColors.primary` → `colorScheme.primary`
   - `AppColors.background` → `colorScheme.surface`
   - `AppColors.cardBackground` → `colorScheme.surfaceContainer`
   - `AppColors.textPrimary` → `colorScheme.onSurface`
   - `AppColors.textSecondary` → `colorScheme.onSurfaceVariant`

## Future Enhancements

1. **Dynamic Color**: Support Material You dynamic theming from wallpaper
2. **Custom Themes**: Allow users to create custom color schemes
3. **Contrast Modes**: High contrast accessibility options
4. **Theme Animations**: Smooth transitions between themes

---

*Last Updated: December 2024*
*Material Design Version: Material 3*
*Flutter SDK: 3.0+*