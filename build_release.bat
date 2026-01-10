@echo off
echo ========================================
echo Smart Storage Analyzer - Release Builder
echo ========================================
echo.

echo [1/5] Cleaning previous builds...
call flutter clean
if errorlevel 1 goto error

echo.
echo [2/5] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error

echo.
echo [3/5] Building release APK...
call flutter build apk --release
if errorlevel 1 goto error

echo.
echo [4/5] Building release App Bundle (AAB)...
call flutter build appbundle --release
if errorlevel 1 goto error

echo.
echo [5/5] Building split APKs (optional)...
call flutter build apk --split-per-abi --release
if errorlevel 1 goto error

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.
echo Release outputs:
echo - APK: build\app\outputs\flutter-apk\app-release.apk
echo - AAB: build\app\outputs\bundle\release\app-release.aab
echo - Split APKs: build\app\outputs\flutter-apk\app-*-release.apk
echo - Mapping: build\app\outputs\mapping\release\mapping.txt
echo.
echo Next steps:
echo 1. Test the APK on a real device
echo 2. Upload AAB to Google Play Console
echo 3. Keep mapping.txt for crash report analysis
echo.
pause
exit /b 0

:error
echo.
echo ========================================
echo BUILD FAILED!
echo ========================================
echo Please check the error messages above.
pause
exit /b 1