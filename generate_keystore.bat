@echo off
echo ============================================
echo SMART STORAGE ANALYZER - KEYSTORE GENERATOR
echo ============================================
echo.

echo This script will generate a new release keystore for your app.
echo IMPORTANT: Use strong, unique passwords (16+ characters)
echo.

set /p KEY_ALIAS="Enter key alias (default: upload): "
if "%KEY_ALIAS%"=="" set KEY_ALIAS=upload

echo.
echo Generating keystore with alias: %KEY_ALIAS%
echo.
echo You will be prompted for:
echo 1. Keystore password (remember this!)
echo 2. Key password (can be same as keystore password)
echo 3. Your name and organization details
echo.

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias %KEY_ALIAS%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo SUCCESS! Keystore created: upload-keystore.jks
    echo ============================================
    echo.
    echo NEXT STEPS:
    echo 1. Move upload-keystore.jks to a secure location
    echo 2. Update android/key.properties with:
    echo    - Your keystore password
    echo    - Your key password
    echo    - Path to upload-keystore.jks
    echo    - Key alias: %KEY_ALIAS%
    echo.
    echo 3. NEVER commit key.properties or the keystore to version control
    echo 4. Keep backups of your keystore in a secure location
    echo.
    echo IMPORTANT: You cannot update your app without this keystore!
    echo.
) else (
    echo.
    echo ERROR: Keystore generation failed.
    echo Please check that Java/keytool is installed and try again.
    echo.
)

pause