# Storage Access Framework (SAF) Document Scanner Implementation

## Overview
This implementation provides a Google Play-compliant solution for document scanning on Android 10+ using the Storage Access Framework (SAF). It allows users to manually select a folder and scan document files within it, bypassing Scoped Storage limitations without requiring MANAGE_EXTERNAL_STORAGE permission.

## Architecture

### MVVM Pattern
- **Model**: Document data entities and services
- **View**: DocumentScannerScreen (UI)
- **ViewModel**: DocumentScanCubit (State management)

### Key Components

#### 1. Android Platform Code
- **DocumentSAFHandler.kt**: Core SAF operations
  - Handles folder selection via ACTION_OPEN_DOCUMENT_TREE
  - Implements takePersistableUriPermission for persistent access
  - Recursively scans selected folder for documents
  - Returns document metadata (name, size, MIME type, URI)

- **MainActivity.kt**: Flutter method channel integration
  - Channel: `com.smarttools.storageanalyzer/native`
  - Methods: `selectDocumentFolder`, `scanDocuments`
  - Handles activity results from folder picker

#### 2. Flutter Service Layer
- **DocumentScannerService**: 
  - Manages platform communication
  - Handles URI persistence via SharedPreferences
  - Provides document scanning API

#### 3. State Management (BLoC/Cubit)
- **DocumentScanCubit**: Business logic and state management
  - States: DocumentScanNoFolder, DocumentScanLoading, DocumentScanSuccess
  - Methods: checkSavedFolder(), selectDocumentFolder(), clearSavedFolder()

#### 4. UI Components
- **DocumentScannerScreen**: Main UI with three distinct states
  - No Folder Selected: Shows explanation and folder selection button
  - Loading: Displays progress during scanning
  - Success: Shows scanned documents in a list

## Supported Document Types
- PDF (.pdf)
- Microsoft Word (.doc, .docx)
- Microsoft Excel (.xls, .xlsx)
- Microsoft PowerPoint (.ppt, .pptx)
- Text Files (.txt)
- Additional types can be added via MIME type filtering

## Permissions and Compliance

### Required Permissions
```xml
<!-- No dangerous permissions required -->
<!-- SAF handles permissions internally -->
```

### Google Play Compliance
✅ No MANAGE_EXTERNAL_STORAGE permission
✅ Uses official Android SAF APIs
✅ Read-only access to user-selected folders
✅ Persistent URI permissions for better UX
✅ Clear user consent via system folder picker

## Navigation Flow
1. User taps "Documents" category in dashboard
2. App navigates to DocumentScannerScreen
3. If no folder selected:
   - Shows explanation about Android restrictions
   - User taps "Select Documents Folder"
   - System folder picker opens
   - User grants access to a folder
4. App scans folder recursively
5. Documents displayed in list with metadata
6. URI permission persisted for future use

## Implementation Details

### Flutter-Android Communication
```dart
// Flutter side
static const _channel = MethodChannel('com.smarttools.storageanalyzer/native');

// Select folder
final result = await _channel.invokeMethod('selectDocumentFolder');

// Scan documents
final documents = await _channel.invokeMethod('scanDocuments');
```

### URI Persistence
```dart
// Save URI for future use
final prefs = await SharedPreferences.getInstance();
await prefs.setString('document_folder_uri', uri);

// Restore on app restart
final savedUri = prefs.getString('document_folder_uri');
if (savedUri != null) {
  // Use saved URI without asking again
}
```

### State Management
```dart
// Three clear states
sealed class DocumentScanState extends Equatable {
  const DocumentScanState();
}

class DocumentScanNoFolder extends DocumentScanState {}
class DocumentScanLoading extends DocumentScanState {}
class DocumentScanSuccess extends DocumentScanState {
  final List<DocumentFile> documents;
  // ...
}
```

## Testing Instructions

### Manual Testing
1. Build and install the app on Android 10+ device
2. Navigate to Dashboard
3. Tap on "Documents" category
4. Verify "No Folder Selected" state appears
5. Tap "Select Documents Folder"
6. Choose a folder (e.g., Downloads or Documents)
7. Verify documents are scanned and displayed
8. Force close and reopen app
9. Navigate back to Documents
10. Verify folder access is retained (no prompt)

### Edge Cases to Test
- Empty folders
- Folders with mixed content (documents + other files)
- Deep folder hierarchies
- Large number of documents (1000+)
- Permission denial scenarios
- Folder access revocation

## Performance Considerations
- Scanning is performed on background thread
- Results are batched for UI updates
- Large folders may take time (progress shown)
- Memory-efficient document metadata only (no file content loaded)

## Security & Privacy
- Read-only access to user-selected folders
- No automatic folder scanning
- Clear user consent required
- Permissions can be revoked in system settings
- No file content is accessed, only metadata

## Troubleshooting

### Common Issues
1. **Documents not appearing**: Ensure selected folder contains supported document types
2. **Permission denied**: User may have revoked access in system settings
3. **Slow scanning**: Large folders with many files may take time
4. **App crash on scan**: Check for memory issues with very large folders

### Debug Commands
```bash
# Check if DocumentFile dependency is included
./gradlew :app:dependencies | grep documentfile

# Verify AndroidManifest doesn't have MANAGE_EXTERNAL_STORAGE
grep -r "MANAGE_EXTERNAL_STORAGE" android/

# Test on specific Android version
flutter run -d emulator-5554 # Android 10+
```

## Future Enhancements
- Add file preview functionality
- Implement document search/filter
- Support for cloud storage providers
- Batch operations on documents
- Export document list feature
- Document type statistics

## Compliance Checklist
✅ Android Scoped Storage compliant
✅ Google Play Store policy compliant
✅ GDPR/Privacy compliant (user consent)
✅ No dangerous permissions required
✅ Transparent permission model
✅ User can revoke access anytime

## Developer Notes
- The implementation uses `androidx.documentfile:documentfile:1.0.1`
- Minimum Android API level: 21 (Android 5.0)
- Target Android SDK: 34 (Android 14)
- Flutter SDK: >=3.0.0 <4.0.0
- The system folder picker is a trusted UI component
- URI permissions survive app updates but not uninstalls

## Related Files
- `/android/app/src/main/kotlin/.../DocumentSAFHandler.kt`
- `/android/app/src/main/kotlin/.../MainActivity.kt`
- `/lib/core/services/document_scanner_service.dart`
- `/lib/presentation/cubits/document_scan/*`
- `/lib/presentation/screens/document_scanner/*`
- `/lib/presentation/widgets/dashboard/dashboard_content.dart`

## Support
For issues or questions about this implementation:
1. Check the troubleshooting section above
2. Review Android SAF documentation
3. Test on different Android versions (10, 11, 12, 13, 14)
4. Ensure all dependencies are properly included