# Smart Storage Analyzer - Permissions Guide

This guide explains how permissions are handled in the Smart Storage Analyzer app, ensuring a smooth user experience across Android and iOS platforms.

## Overview

The app requires storage permissions to analyze device storage and provide insights about file usage. We've implemented a comprehensive permission system that:

- Handles different Android API levels (Android 10, 11, 13+)
- Provides graceful fallbacks and clear user guidance
- Caches permission state for better performance
- Supports both Android and iOS platforms

## Permission Architecture

### Core Components

1. **PermissionService** (`lib/core/services/permission_service.dart`)
   - Low-level permission handling
   - Platform-specific permission checks
   - User-friendly permission dialogs

2. **PermissionManager** (`lib/core/services/permission_manager.dart`)
   - High-level permission management
   - State persistence with SharedPreferences
   - Caching for performance optimization
   - Tracks permission denial count

3. **Native Integration**
   - Android: `MainActivity.kt` handles native file operations
   - iOS: Configured via `Info.plist`

## Android Permissions

### Permission Requirements by API Level

#### Android 10 and below (API 29-)
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### Android 11-12 (API 30-32)
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

#### Android 13+ (API 33+)
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### Additional Permissions
```xml
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

## iOS Permissions

All required permissions are configured in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photos library to analyze image files and help you manage storage space.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save photos to your library.</string>

<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to analyze audio files and help you manage storage space.</string>

<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to your documents folder to analyze files and help you manage storage space.</string>
```

## Permission Flow

### 1. Initial App Launch
```dart
// In main.dart
await PermissionManager().initialize();
```

### 2. Dashboard Loading
```dart
// Dashboard checks permissions with caching
final hasPermission = await _permissionManager.hasPermission();
if (!hasPermission) {
  final granted = await _permissionManager.requestPermission(context: context);
}
```

### 3. Permission States

#### Granted
- User has approved storage access
- App can scan and analyze files
- State is cached for 5 minutes

#### Denied
- User declined permission
- App shows permission rationale
- Empty data is displayed

#### Permanently Denied
- User selected "Don't ask again"
- App shows settings navigation dialog
- Tracks denial count for analytics

## Implementation Details

### Permission Caching
```dart
// Check cached state (valid for 5 minutes)
final hasPermission = await _permissionManager.hasPermission();

// Force fresh check
final hasPermission = await _permissionManager.hasPermission(forceCheck: true);
```

### Permission Persistence
```dart
// Automatically saved to SharedPreferences
- permission_granted: bool
- permission_last_checked: timestamp
- permission_denied_count: int
```

### Error Handling
```dart
try {
  final granted = await _permissionManager.requestPermission(context: context);
  if (!granted) {
    throw StoragePermissionException(
      message: 'Storage permission required',
    );
  }
} catch (e) {
  // Handle permission error
}
```

## UI/UX Guidelines

### Permission Dialogs
1. **First Request**: Simple explanation of why permission is needed
2. **After 2 Denials**: Show detailed rationale
3. **Permanently Denied**: Guide to app settings

### Visual Feedback
- Loading states during permission checks
- Clear error messages with action buttons
- Automatic reload when permission granted

### Best Practices
1. Request permissions contextually (when needed)
2. Explain value before requesting
3. Provide fallback UI for denied state
4. Never block app usage completely

## Testing Permissions

### Android Testing
```bash
# Reset permissions
adb shell pm clear com.smarttools.storageanalyzer

# Grant permissions via ADB
adb shell pm grant com.smarttools.storageanalyzer android.permission.READ_EXTERNAL_STORAGE

# Check granted permissions
adb shell dumpsys package com.smarttools.storageanalyzer | grep permission
```

### iOS Testing
1. Delete app to reset permissions
2. Use Settings > Privacy to manage permissions
3. Test with different permission combinations

## Troubleshooting

### Common Issues

1. **Permission dialog not showing**
   - Check if permanently denied
   - Verify AndroidManifest.xml entries
   - Ensure context is valid

2. **Files not showing after permission granted**
   - App lifecycle state may need refresh
   - Check native file scanner implementation
   - Verify permission for specific API level

3. **iOS permissions not working**
   - Ensure Info.plist descriptions are present
   - Check for typos in permission keys
   - Test on real device (not simulator)

### Debug Mode
In debug mode, permission checks are bypassed:
```dart
if (kDebugMode) {
  Logger.info('Debug mode: Skipping permission check');
  return true;
}
```

## Migration Guide

### From PermissionService to PermissionManager
```dart
// Old
final hasPermission = await _permissionService.hasStoragePermission();

// New
final hasPermission = await _permissionManager.hasPermission();
```

### Benefits of Migration
- Automatic state persistence
- Performance optimization with caching
- Better error tracking
- Unified permission handling

## Future Enhancements

1. **Permission Analytics**
   - Track grant/denial rates
   - Monitor permission-related crashes
   - A/B test permission request timing

2. **Granular Permissions**
   - Request only needed permissions
   - Progressive permission escalation
   - Feature-based permission groups

3. **Cross-Platform Support**
   - Windows file access
   - macOS sandbox permissions
   - Web storage API integration

## Resources

- [Android Storage Permissions](https://developer.android.com/training/data-storage/shared/media)
- [iOS File Access](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [Flutter Permission Handler](https://pub.dev/packages/permission_handler)
- [Android 13 Permission Changes](https://developer.android.com/about/versions/13/behavior-changes-13)

---

For questions or issues, please check the [GitHub Issues](https://github.com/smarttools/storage-analyzer/issues) page.