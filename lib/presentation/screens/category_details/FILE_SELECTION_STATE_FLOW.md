# Category Files Screen - File Selection State Flow Documentation

## Overview
This document explains the state flow for file selection in the Category Files screen, following MVVM architecture with Flutter Bloc/Cubit.

## Architecture Components

### 1. State Management (CategoryDetailsState)
Located in: `lib/presentation/cubits/category_details/category_details_state.dart`

The state includes:
- `isSelectionMode`: Boolean indicating if selection mode is active
- `selectedFileIds`: Set<String> containing IDs of selected files
- Helper getters:
  - `hasSelection`: Returns true if any files are selected
  - `selectedCount`: Number of selected files
  - `selectedFiles`: List of FileItem objects that are selected
  - `selectedSize`: Total size of selected files in bytes

### 2. Business Logic (CategoryDetailsCubit)
Located in: `lib/presentation/cubits/category_details/category_details_cubit.dart`

Key methods:
- `toggleSelectionMode()`: Enters/exits selection mode
- `selectFile(String fileId)`: Toggles selection of a specific file
- `selectAllFiles()`: Selects all files in the current view
- `clearSelection()`: Clears all selections and exits selection mode
- `toggleAllFiles()`: Toggles between select all and deselect all
- `deleteSelectedFiles()`: Deletes all selected files
- `getSelectedFiles()`: Returns list of selected FileItem objects

### 3. UI Layer (CategoryDetailsScreen)
Located in: `lib/presentation/screens/category_details/category_details_screen.dart`

## State Flow Sequences

### 1. Entering Selection Mode
```
User Action: Long press on any file item OR tap selection mode button
     ↓
UI: Calls cubit.toggleSelectionMode() and cubit.selectFile(fileId)
     ↓
Cubit: Updates state with isSelectionMode = true
     ↓
State: Emits new CategoryDetailsLoaded with selection mode active
     ↓
UI: Rebuilds showing:
    - Selection info bar
    - Share & Delete icons in AppBar
    - Checkboxes on file items
```

### 2. Selecting/Deselecting Files
```
User Action: Tap on file item while in selection mode
     ↓
UI: Calls cubit.selectFile(fileId)
     ↓
Cubit: Toggles file ID in selectedFileIds set
     ↓
State: Emits updated CategoryDetailsLoaded
     ↓
UI: Updates checkbox state and selection count
```

### 3. Sharing Selected Files
```
User Action: Tap share icon in AppBar
     ↓
UI: Calls _shareSelectedFiles()
     ↓
UI: Gets selected files via cubit.getSelectedFiles()
     ↓
UI: Uses Share.shareXFiles() to share
     ↓
On Success: cubit.clearSelection() to exit selection mode
     ↓
UI: Returns to normal mode
```

### 4. Deleting Selected Files
```
User Action: Tap delete icon in AppBar
     ↓
UI: Shows confirmation dialog
     ↓
User Confirms: UI calls cubit.deleteSelectedFiles()
     ↓
Cubit: Calls deleteFilesUseCase.execute(selectedIds)
     ↓
Cubit: Updates file list removing deleted files
     ↓
Cubit: Exits selection mode automatically
     ↓
UI: Shows success/error feedback
```

### 5. Select All / Deselect All
```
User Action: Tap "Select All" button in selection bar
     ↓
UI: Calls cubit.toggleAllFiles()
     ↓
Cubit: If all selected → clear selection
        If not all selected → select all files
     ↓
State: Updates with new selection set
     ↓
UI: Updates all checkboxes accordingly
```

### 6. Exiting Selection Mode
```
Triggers:
- User taps selection mode button while active
- User deselects all files
- After successful delete operation
- After successful share operation (optional)
     ↓
Cubit: Sets isSelectionMode = false, clears selectedFileIds
     ↓
UI: Hides selection bar, removes checkboxes, hides action buttons
```

## Best Practices

1. **State Immutability**: Always use copyWith() when updating state
2. **UI Reactivity**: UI only reacts to state changes, never manages selection directly
3. **Business Logic Separation**: All selection logic is in the Cubit, not in UI
4. **Error Handling**: Delete operations handle errors gracefully with UI feedback
5. **User Feedback**: Every action provides visual feedback (haptic, snackbars)

## Key Design Decisions

1. **No Individual File Actions in Selection Mode**: Share/Delete icons removed from file items to avoid confusion
2. **Auto-Exit on Empty Selection**: Selection mode automatically exits when no files are selected
3. **Batch Operations Only**: Share and Delete operate on all selected files at once
4. **Clear Visual Indicators**: Selected files show checkboxes, selection count displayed prominently
5. **Native-like UX**: Behavior mimics native file managers for familiarity