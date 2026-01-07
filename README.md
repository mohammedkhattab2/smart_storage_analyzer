# Smart Storage Analyzer

A powerful Flutter application for Android that helps users analyze and manage their device storage efficiently.

## Features

- **Storage Analysis**: Deep scan to identify large files, duplicates, cache files, and temporary files
- **Category Management**: Organize files by type (Images, Videos, Audio, Documents, Apps, Others)
- **File Manager**: Browse, select, and delete files with multi-selection support
- **Media Viewer**: Built-in viewer for images, videos, and audio files
- **Statistics**: Track storage usage trends and patterns
- **Dark/Light Theme**: System-aware theme switching
- **Notifications**: Optional reminders to check storage (every 2 hours)

## Technical Stack

- **Flutter**: Cross-platform UI framework
- **Architecture**: MVVM + Clean Architecture
- **State Management**: Cubit (flutter_bloc)
- **Native Integration**: MethodChannel for Android-specific features
- **Material Design 3**: Modern UI components

## Requirements

- Android 6.0 (API 23) or higher
- Storage permissions for file access
- Notification permissions (optional, for reminders)

## Build & Installation

1. Ensure Flutter is installed and configured
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Connect an Android device or start an emulator
5. Run `flutter run` to build and install

## Release Build

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

## Permissions

The app requires the following permissions:
- **Storage Access**: To analyze and manage files
- **Usage Stats** (optional): For advanced app size analysis
- **Notifications** (optional): For storage check reminders

## Privacy & Security

- No user data is collected or transmitted
- All analysis is performed locally on device
- No ads, analytics, or tracking
- Files are only accessed with user permission

## License

Copyright © 2024 Smart Tools. All rights reserved.
