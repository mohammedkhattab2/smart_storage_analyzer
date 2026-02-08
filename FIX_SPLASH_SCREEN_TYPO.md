# Fix Splash Screen Filename Typo

## Issue
The splash screen asset files have a typo in their filenames:
- `splach_screen` should be `splash_screen`

## Affected Files
```
assets/2.0x/splach_screen@2x.png  ❌ (typo)
assets/3.0x/splach_screen@3x.png  ❌ (typo)
```

## Solution

### Option 1: Using Command Line (Recommended)

#### Windows (PowerShell/Command Prompt)
```bash
# Navigate to your project root
cd "e:\flutter project\smart_storage_analyzer"

# Rename the files
rename "assets\2.0x\splach_screen@2x.png" "splash_screen@2x.png"
rename "assets\3.0x\splach_screen@3x.png" "splash_screen@3x.png"
```

#### macOS/Linux (Terminal)
```bash
# Navigate to your project root
cd /path/to/smart_storage_analyzer

# Rename the files
mv assets/2.0x/splach_screen@2x.png assets/2.0x/splash_screen@2x.png
mv assets/3.0x/splach_screen@3x.png assets/3.0x/splash_screen@3x.png
```

### Option 2: Using VS Code

1. Open the Explorer panel in VS Code
2. Navigate to `assets/2.0x/`
3. Right-click on `splach_screen@2x.png`
4. Select "Rename" 
5. Change to `splash_screen@2x.png`
6. Repeat for `assets/3.0x/splach_screen@3x.png`

### Option 3: Using File Explorer/Finder

1. Navigate to your project folder
2. Go to `assets/2.0x/`
3. Rename `splach_screen@2x.png` to `splash_screen@2x.png`
4. Go to `assets/3.0x/`
5. Rename `splach_screen@3x.png` to `splash_screen@3x.png`

## Verification Steps

After renaming, verify the fix:

1. **Check file structure:**
   ```
   assets/
   ├── app_image_icon.png         ✅ (app icon)
   ├── splash_screen.png          ✅ (already correct)
   ├── 2.0x/
   │   └── splash_screen@2x.png   ✅ (fixed)
   └── 3.0x/
       └── splash_screen@3x.png   ✅ (fixed)
   ```

2. **Clear Flutter cache and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Test on different screen densities:**
   - Test on devices with different screen densities to ensure proper splash screen display
   - The Flutter framework will automatically select the appropriate resolution variant

## Why This Matters

Flutter uses a resolution-aware asset system. When you reference `assets/splash_screen.png`, Flutter automatically looks for:
- `assets/splash_screen.png` (1x - baseline)
- `assets/2.0x/splash_screen@2x.png` (2x - high resolution)
- `assets/3.0x/splash_screen@3x.png` (3x - extra high resolution)

With the typo, Flutter cannot find the high-resolution variants, so it will fall back to the baseline image, which may appear blurry on high-density screens.

## Additional Notes

- **No code changes required**: The Flutter code references the base asset name correctly
- **No pubspec.yaml changes required**: The assets folder is already included
- **Capital 'S' in main file**: Note that the main file is `Splash_screen.png` with capital 'S'. While this works, for consistency you might want to rename it to `splash_screen.png` (lowercase)

## Post-Fix Checklist

- [ ] Renamed `splach_screen@2x.png` to `splash_screen@2x.png`
- [ ] Renamed `splach_screen@3x.png` to `splash_screen@3x.png`
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Test app on different screen densities
- [ ] Commit changes to version control

## Optional: Fix Capitalization

For better consistency, you may also want to rename the main splash screen file:
```bash
# Windows
rename "assets\Splash_screen.png" "splash_screen.png"

# macOS/Linux
mv assets/Splash_screen.png assets/splash_screen.png
```

This ensures all splash screen files follow the same naming convention.