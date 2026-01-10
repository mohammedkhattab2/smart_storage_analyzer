# Smart Storage Analyzer - Release Build Guide

## Prerequisites

1. **Flutter SDK**: Ensure Flutter is installed and configured
2. **Android SDK**: Android Studio with SDK tools
3. **Java JDK**: JDK 17 or higher (for signing)

## Step 1: Generate Release Keystore

If you don't have a keystore yet, create one:

```bash
# Navigate to android directory
cd android

# Create keystore directory
mkdir keystore

# Generate keystore (run from android directory)
keytool -genkey -v -keystore keystore/smart_storage_analyzer.jks -keyalg RSA -keysize 2048 -validity 10000 -alias smart_storage_analyzer
```

**Important**: Remember your keystore password, key password, and alias. Store them securely!

## Step 2: Configure Signing

### Option A: Using Environment Variables (Recommended for CI/CD)

Set these environment variables:
```bash
# Windows PowerShell
$env:KEY_ALIAS="smart_storage_analyzer"
$env:KEY_PASSWORD="your_key_password"
$env:KEY_STORE="../keystore/smart_storage_analyzer.jks"
$env:STORE_PASSWORD="your_store_password"

# Windows CMD
set KEY_ALIAS=smart_storage_analyzer
set KEY_PASSWORD=your_key_password
set KEY_STORE=../keystore/smart_storage_analyzer.jks
set STORE_PASSWORD=your_store_password

# Linux/macOS
export KEY_ALIAS="smart_storage_analyzer"
export KEY_PASSWORD="your_key_password"
export KEY_STORE="../keystore/smart_storage_analyzer.jks"
export STORE_PASSWORD="your_store_password"
```

### Option B: Create key.properties file (Local Development)

Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=smart_storage_analyzer
storeFile=../keystore/smart_storage_analyzer.jks
```

Then update `android/app/build.gradle.kts` to use key.properties:
```kotlin
// Add at the top
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Update signingConfigs
signingConfigs {
    release {
        keyAlias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
        keyPassword = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
        storeFile = file(keystoreProperties.getProperty("storeFile") ?: System.getenv("KEY_STORE") ?: "../keystore/smart_storage_analyzer.jks")
        storePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD")
    }
}
```

**⚠️ IMPORTANT**: Never commit `key.properties` or your keystore to version control!

## Step 3: Build Release APK

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# The APK will be generated at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Step 4: Build Release App Bundle (AAB)

For Google Play Store submission:

```bash
# Build release App Bundle
flutter build appbundle --release

# The AAB will be generated at:
# build/app/outputs/bundle/release/app-release.aab
```

## Step 5: Build with Split APKs (Optional)

For smaller APK sizes per architecture:

```bash
# Build split APKs by ABI
flutter build apk --split-per-abi --release

# This generates:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## Build Output Locations

- **Universal APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
- **Split APKs**: `build/app/outputs/flutter-apk/app-<arch>-release.apk`
- **Mapping file**: `build/app/outputs/mapping/release/mapping.txt` (for crash reports)

## Quick Build Script

Create `build_release.sh` (Linux/macOS) or `build_release.bat` (Windows):

### Windows (build_release.bat)
```batch
@echo off
echo Building Smart Storage Analyzer Release...
echo.

echo Step 1: Cleaning project...
call flutter clean

echo Step 2: Getting dependencies...
call flutter pub get

echo Step 3: Building release APK...
call flutter build apk --release

echo Step 4: Building release AAB...
call flutter build appbundle --release

echo.
echo Build complete!
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
pause
```

### Linux/macOS (build_release.sh)
```bash
#!/bin/bash
echo "Building Smart Storage Analyzer Release..."
echo

echo "Step 1: Cleaning project..."
flutter clean

echo "Step 2: Getting dependencies..."
flutter pub get

echo "Step 3: Building release APK..."
flutter build apk --release

echo "Step 4: Building release AAB..."
flutter build appbundle --release

echo
echo "Build complete!"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
```

Make it executable:
```bash
chmod +x build_release.sh
```

## Troubleshooting

### Error: Keystore file not found
- Ensure the keystore path in build.gradle.kts is correct
- Use absolute path if relative path doesn't work

### Error: Wrong keystore password
- Double-check your passwords
- Ensure no extra spaces in environment variables or key.properties

### Error: Duplicate class found
- Run `flutter clean` before building
- Delete `build` and `.gradle` folders manually if needed

### ProGuard warnings
- Check `android/app/proguard-rules.pro` for missing rules
- Add `-dontwarn` rules for specific warnings if safe

## Pre-release Checklist

- [ ] Version number updated in `pubspec.yaml`
- [ ] Keystore generated and stored securely
- [ ] Signing configuration verified
- [ ] ProGuard rules tested
- [ ] All debug code removed
- [ ] Permissions verified (no restricted permissions)
- [ ] App tested on multiple devices
- [ ] Release notes prepared