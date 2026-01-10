# Document Scanner Implementation with Storage Access Framework (SAF)

## Overview
This implementation provides a **Google Play compliant** document scanning solution for Android 10+ using Storage Access Framework (SAF). It allows users to manually select a folder (e.g., Documents or Downloads) and scan document files inside it without requiring dangerous permissions like `MANAGE_EXTERNAL_STORAGE`.

## Key Features
✅ **Google Play Compliant** - No MANAGE_EXTERNAL_STORAGE permission needed  
✅ **Android Scoped Storage Compatible** - Works with Android 10+ restrictions  
✅ **Persistent Folder Access** - Remembers selected folder after app restart  
✅ **Clean MVVM Architecture** - Using Cubit for state management  
✅ **Document Type Support** - PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, and more  
✅ **Cached Results** - Fast access to previously scanned documents  
✅ **Search Functionality** - Filter documents by name, extension, or type  
✅ **Document Categories** - Automatic categorization by file type  

## Technical Requirements
- ✅ Flutter (stable channel)
- ✅ Android targetSdk 34
- ✅ No MANAGE_EXTERNAL_STORAGE permission
- ✅ Uses ACTION_OPEN_DOCUMENT_TREE
- ✅ Persist URI permission with takePersistableUriPermission
- ✅ Read-only access

## Architecture Components

### Android Platform (Kotlin)

#### 1. **DocumentSAFHandler.kt**
- Handles Storage Access Framework operations
- Opens document tree picker
- Takes persistable URI permissions
- Scans documents recursively
- Returns document metadata (name, size, URI, MIME type)

#### 2. **MainActivity.kt Integration**
- Registers DocumentSAFHandler
- Handles method channel calls
- Processes activity results from folder picker
- Manages lifecycle cleanup

### Flutter Side (Dart)

#### 1. **DocumentScannerService**
- Central service for document operations
- Manages persistent URI storage using SharedPreferences
- Caches scanned documents
- Provides document categorization
- Handles folder selection and validation

#### 2. **DocumentScanCubit & State**
- State management using flutter_bloc
- States: Initial, Loading, Selecting, Scanning, NoAccess, Loaded, Empty, Error
- Handles background refresh
- Search functionality
- Document statistics

#### 3. **UI Components**
- **DocumentScannerScreen**: Main UI screen
- Clean Material Design 3 interface
- Folder selection dialog
- Document list with search
- Category chips for filtering
- Document properties viewer

## File Structure
```
android/app/src/main/kotlin/com/smarttools/storageanalyzer/
├── DocumentSAFHandler.kt      # SAF implementation
└── MainActivity.kt            # Platform channel integration

lib/
├── core/
│   ├── services/
│   │   └── document_scanner_service.dart  # Document scanning service
│   ├── service_locator/
│   │   └── service_locator.dart          # Dependency injection
│   └── utils/
│       └── file_size_formatter.dart      # File size utilities
├── presentation/
│   ├── cubits/
│   │   └── document_scan/
│   │       ├── document_scan_cubit.dart  # Business logic
│   │       └── document_scan_state.dart  # State definitions
│   └── screens/
│       └── document_scanner/
│           ├── document_scanner_screen.dart        # Main UI
│           └── document_scanner_integration.dart   # Integration examples
```

## Usage Example

### 1. Add to your routes
```dart
import 'package:smart_storage_analyzer/presentation/screens/document_scanner/document_scanner_integration.dart';

// In your app routes
'/document-scanner': (context) => DocumentScannerIntegration.route(),
```

### 2. Add button to navigate to scanner
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DocumentScanCubit>(),
          child: const DocumentScannerScreen(),
        ),
      ),
    );
  },
  icon: const Icon(Icons.folder),
  label: const Text('Scan Documents'),
)
```

### 3. Initialize service locator
```dart
// In your main.dart before runApp
await setupServiceLocator();
```

## Supported Document Types

### Documents
- PDF (.pdf)
- Microsoft Word (.doc, .docx)
- OpenDocument Text (.odt)
- Rich Text Format (.rtf)
- Plain Text (.txt)
- Markdown (.md)

### Spreadsheets
- Microsoft Excel (.xls, .xlsx)
- OpenDocument Spreadsheet (.ods)
- CSV (.csv)

### Presentations
- Microsoft PowerPoint (.ppt, .pptx)
- OpenDocument Presentation (.odp)

### E-books
- EPUB (.epub)
- MOBI (.mobi)
- AZW/AZW3 (.azw, .azw3)
- FB2 (.fb2)

### Data/Config
- JSON (.json)
- XML (.xml)
- YAML (.yaml, .yml)
- INI (.ini, .conf, .cfg)

### Web
- HTML (.html, .htm)
- CSS (.css)
- JavaScript (.js, .ts)

## Permissions

### AndroidManifest.xml
No additional permissions needed for SAF. The system handles permissions through the folder picker dialog.

### Runtime Permissions
The user grants access to a specific folder through the system folder picker. This permission is:
- **Scoped**: Only to the selected folder
- **Persistent**: Survives app restarts
- **Revocable**: User can revoke through system settings

## How It Works

### 1. Initial Setup
- User opens Document Scanner screen
- App checks for existing folder permissions
- If no permission, shows explanation and "Select Folder" button

### 2. Folder Selection
- User taps "Select Documents Folder"
- System folder picker opens (ACTION_OPEN_DOCUMENT_TREE)
- User selects a folder (e.g., Documents or Downloads)
- App takes persistent URI permission

### 3. Document Scanning
- App recursively scans selected folder using DocumentFile API
- Filters for supported document extensions
- Returns document metadata (name, size, URI, MIME type)
- Results are cached for quick access

### 4. Data Persistence
- Selected folder URI is saved to SharedPreferences
- Documents are cached in memory
- Permission persists across app restarts

### 5. Document Access
- Documents are accessed via content:// URIs
- No direct file path access (Scoped Storage compliant)
- Operations use ContentResolver for file access

## Privacy & Security

### Google Play Compliance
✅ **No dangerous permissions**: Doesn't require MANAGE_EXTERNAL_STORAGE  
✅ **User consent**: Explicit folder selection by user  
✅ **Scoped access**: Only selected folder is accessible  
✅ **Transparent**: Clear explanation why access is needed  

### Android Privacy Rules
The implementation follows Android's Scoped Storage guidelines:
- Uses Storage Access Framework (SAF)
- No direct file path access on Android 10+
- Content URIs for file operations
- Persistent permissions with user consent

## Testing Instructions

### 1. Basic Flow Test
1. Open app and navigate to Document Scanner
2. Tap "Select Documents Folder"
3. Choose a folder with documents
4. Verify documents are displayed
5. Test search functionality
6. Close and reopen app
7. Verify folder access persists

### 2. Edge Cases
- Empty folder selection
- Folder with no documents
- Folder with mixed file types
- Large folders (1000+ files)
- Permission revocation from system settings

### 3. UI/UX Tests
- Document categorization
- Search filters
- File size formatting
- Date formatting
- Error handling
- Loading states

## Troubleshooting

### Common Issues

1. **"No documents found"**
   - Ensure selected folder contains supported document types
   - Check if folder has read permissions

2. **"Folder access expired"**
   - User may have revoked permission from system settings
   - Select folder again to restore access

3. **Documents not showing after app restart**
   - Check SharedPreferences is properly initialized
   - Verify service locator setup

4. **Slow scanning on large folders**
   - Normal for folders with many files
   - Consider adding pagination or lazy loading

## Future Enhancements

### Potential Features
- [ ] Document preview
- [ ] Multiple folder selection
- [ ] Export document list
- [ ] Document sorting options
- [ ] File operations (delete, move, copy)
- [ ] Cloud storage integration
- [ ] OCR for scanned images
- [ ] Document metadata editing

### Performance Optimizations
- [ ] Pagination for large document lists
- [ ] Background scanning with progress updates
- [ ] Incremental scanning for changes
- [ ] Database caching for offline access

## Important Notes

⚠️ **Android Restriction**: Due to Android privacy rules, document access requires manual folder selection. This is not a limitation of the implementation but a requirement from Google Play for apps targeting Android 10+.

ℹ️ **User Education**: Always explain to users why manual folder selection is required. The implementation includes a clear message: "Due to Android privacy rules, document access requires manual folder selection."

✅ **Production Ready**: This implementation is production-ready and compliant with Google Play policies. It has been designed following Android best practices and Material Design guidelines.

## License
This implementation follows your project's existing license terms.

## Support
For issues or questions about this implementation, please refer to the inline documentation in the source code or create an issue in your project repository.