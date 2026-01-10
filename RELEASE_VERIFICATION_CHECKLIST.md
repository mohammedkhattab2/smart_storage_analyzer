# Smart Storage Analyzer - Release Verification Checklist

## Pre-Installation Verification

### 1. APK/AAB Inspection
```bash
# Check APK size (should be reasonable, typically < 50MB)
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Verify APK is signed
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check AAB contents
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=test.apks --mode=universal
unzip -l test.apks
```

### 2. Permissions Verification
Use `aapt` to verify permissions:
```bash
# Check permissions in APK
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Expected permissions (NO restricted permissions):
- ✓ android.permission.READ_EXTERNAL_STORAGE
- ✓ android.permission.WRITE_EXTERNAL_STORAGE (maxSdkVersion="29")
- ✓ android.permission.READ_MEDIA_IMAGES
- ✓ android.permission.READ_MEDIA_VIDEO
- ✓ android.permission.READ_MEDIA_AUDIO
- ✓ android.permission.ACCESS_MEDIA_LOCATION
- ✓ android.permission.POST_NOTIFICATIONS

Should NOT have:
- ❌ android.permission.MANAGE_EXTERNAL_STORAGE
- ❌ android.permission.QUERY_ALL_PACKAGES

## Installation Testing

### 1. Clean Installation
```bash
# Uninstall any existing version
adb uninstall com.smarttools.storageanalyzer

# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or for AAB testing
bundletool install-apks --apks=test.apks
```

### 2. Device Testing Matrix

Test on these Android versions:
- [ ] Android 10 (API 29) - Legacy storage behavior
- [ ] Android 11 (API 30) - Scoped storage enforcement
- [ ] Android 12 (API 31) - New splash screen
- [ ] Android 13 (API 33) - Granular media permissions
- [ ] Android 14 (API 34) - Latest version

## Functional Verification

### 1. Initial Launch
- [ ] App launches without crash
- [ ] Splash screen displays correctly
- [ ] No permission errors on startup

### 2. Permission Flow
- [ ] Permission rationale dialog shows before request
- [ ] Media permissions requested properly
- [ ] App handles permission denial gracefully
- [ ] Re-request flow works correctly

### 3. Core Features Testing

#### Dashboard Screen
- [ ] Storage circle displays correct total/used/free space
- [ ] All category cards show with proper icons and sizes
- [ ] Analyze button works
- [ ] Deep Storage Analyze navigates correctly
- [ ] No duplicate loading or flickering

#### All Categories Screen
- [ ] All categories listed
- [ ] Tap on category navigates to details
- [ ] Category sizes match dashboard
- [ ] Back navigation works

#### Category Details Screen
- [ ] Files load correctly (no duplicates)
- [ ] File selection works (checkbox functionality)
- [ ] Multi-select shows action bar
- [ ] Share functionality works with selected files
- [ ] Delete functionality works (with confirmation)
- [ ] File preview/open works
- [ ] No loading issues or repeated API calls

#### File Manager Screen
- [ ] Tabs for different file types work
- [ ] Files displayed correctly in each tab
- [ ] Sorting/filtering works
- [ ] File operations work

#### Deep Storage Analysis
- [ ] Analysis runs without blocking UI
- [ ] Progress shown correctly
- [ ] Results accurate
- [ ] Can navigate to cleanup

#### Cleanup Results
- [ ] Shows analysis results
- [ ] Selection works
- [ ] Cleanup executes properly
- [ ] Space freed is accurate

### 4. Performance Verification
- [ ] App launches in < 3 seconds
- [ ] No UI freezes or jank
- [ ] Smooth scrolling in file lists
- [ ] Memory usage reasonable (< 200MB typically)
- [ ] No ANRs (Application Not Responding)

### 5. Edge Cases
- [ ] App works with empty storage
- [ ] Handles large file lists (1000+ files)
- [ ] Works offline
- [ ] Handles device rotation
- [ ] Background/foreground transitions

### 6. Settings & Pro Features
- [ ] Theme switching works
- [ ] Settings persist after app restart
- [ ] Pro features properly gated
- [ ] About/Privacy/Terms pages load

## Release Build Specific Checks

### 1. ProGuard/R8 Verification
- [ ] No crashes from obfuscated code
- [ ] All features work (nothing broken by minification)
- [ ] App size reduced compared to debug build

### 2. Signing Verification
- [ ] APK is signed with release key (not debug)
- [ ] Certificate details correct

### 3. No Debug Artifacts
- [ ] No debug logs in logcat
- [ ] No development URLs or keys
- [ ] No test data

## Google Play Store Readiness

### 1. Content Rating
- [ ] App content appropriate for all ages
- [ ] No violent, sexual, or inappropriate content
- [ ] Storage utility category appropriate

### 2. Privacy Policy
- [ ] Privacy policy URL accessible
- [ ] Policy covers data collection and usage
- [ ] No personal data collected without consent

### 3. App Description Ready
- [ ] Clear app description
- [ ] Feature list
- [ ] Screenshots prepared (phone & tablet)
- [ ] App icon meets guidelines

### 4. Technical Requirements
- [ ] Target API level 33 or higher ✓
- [ ] 64-bit support included ✓
- [ ] App Bundle format (.aab) generated ✓

## Post-Release Monitoring

### 1. Crash Reporting Setup
- [ ] ProGuard mapping file saved: `build/app/outputs/mapping/release/mapping.txt`
- [ ] Ready to upload to Play Console for deobfuscation

### 2. Initial Metrics to Monitor
- [ ] Crash rate < 1%
- [ ] ANR rate < 0.47%
- [ ] User ratings
- [ ] Install/uninstall rates

## Sign-off Checklist

**Technical Lead:**
- [ ] Code review completed
- [ ] Security review passed
- [ ] Performance benchmarks met

**QA Lead:**
- [ ] All test cases passed
- [ ] No critical bugs
- [ ] User experience validated

**Product Owner:**
- [ ] Features match requirements
- [ ] Ready for public release
- [ ] Store listing approved

---

**Release Candidate Status:** ⬜ NOT READY / ✅ READY

**Notes/Issues:**
_Add any specific issues or notes here_