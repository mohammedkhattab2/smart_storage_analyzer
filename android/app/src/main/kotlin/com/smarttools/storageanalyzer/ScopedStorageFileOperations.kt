package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * File operations that work with Scoped Storage
 * No MANAGE_EXTERNAL_STORAGE permission required
 */
class ScopedStorageFileOperations(private val context: Context) {
    
    /**
     * Delete files using content URIs
     */
    suspend fun deleteFiles(filePaths: List<String>): Int = withContext(Dispatchers.IO) {
        var deletedCount = 0
        val contentResolver = context.contentResolver
        
        for (path in filePaths) {
            try {
                android.util.Log.d("ScopedStorageFileOperations", "Attempting to delete file: $path")
                
                // Check if it's a content URI or a virtual path
                val deleted = when {
                    path.startsWith("content://") -> deleteByContentUri(path, contentResolver)
                    path.startsWith("image://") || path.startsWith("video://") ||
                    path.startsWith("audio://") || path.startsWith("document://") -> deleteByVirtualPath(path, contentResolver)
                    else -> {
                        // Try multiple deletion methods for regular paths
                        var success = false
                        
                        // First try MediaStore deletion (works for media files)
                        success = deleteFromMediaStore(path, contentResolver)
                        android.util.Log.d("ScopedStorageFileOperations", "MediaStore deletion for $path: $success")
                        
                        // If MediaStore fails and we're on older Android, try direct file deletion
                        if (!success && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                            success = deleteDirectFile(path)
                            android.util.Log.d("ScopedStorageFileOperations", "Direct file deletion for $path: $success")
                        }
                        
                        // If still failed, try finding the file via content resolver
                        if (!success) {
                            success = deleteViaContentResolver(path, contentResolver)
                            android.util.Log.d("ScopedStorageFileOperations", "Content resolver deletion for $path: $success")
                        }
                        
                        success
                    }
                }
                
                if (deleted) {
                    deletedCount++
                    android.util.Log.d("ScopedStorageFileOperations", "Successfully deleted: $path")
                } else {
                    android.util.Log.e("ScopedStorageFileOperations", "Failed to delete: $path")
                }
            } catch (e: Exception) {
                android.util.Log.e("ScopedStorageFileOperations", "Error deleting file $path: ${e.message}")
                e.printStackTrace()
            }
        }
        
        android.util.Log.d("ScopedStorageFileOperations", "Deleted $deletedCount out of ${filePaths.size} files")
        deletedCount
    }
    
    /**
     * Delete file by content URI
     */
    private suspend fun deleteByContentUri(uriString: String, contentResolver: ContentResolver): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            contentResolver.delete(uri, null, null) > 0
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Delete file by virtual path (from our scanner)
     */
    private suspend fun deleteByVirtualPath(virtualPath: String, contentResolver: ContentResolver): Boolean {
        // Extract the ID from the virtual path
        val id = extractIdFromVirtualPath(virtualPath) ?: return false
        
        val uri = when {
            virtualPath.startsWith("image://") -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            virtualPath.startsWith("video://") -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
            virtualPath.startsWith("audio://") -> ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            else -> ContentUris.withAppendedId(MediaStore.Files.getContentUri("external"), id)
        }
        
        return try {
            contentResolver.delete(uri, null, null) > 0
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Delete file by path (for backward compatibility)
     */
    private suspend fun deleteByPath(path: String, contentResolver: ContentResolver): Boolean {
        // For API < 29, we might have actual file paths
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return try {
                val file = java.io.File(path)
                if (file.exists() && file.canWrite()) {
                    file.delete()
                } else {
                    false
                }
            } catch (e: Exception) {
                false
            }
        }
        
        // For API 29+, try to find the file in MediaStore
        return deleteFromMediaStore(path, contentResolver)
    }
    
    /**
     * Delete file from MediaStore by path
     */
    private suspend fun deleteFromMediaStore(path: String, contentResolver: ContentResolver): Boolean {
        try {
            // First, try to find the file in the MediaStore using different approaches
            
            // Try Images MediaStore
            val imageDeleted = deleteFromSpecificMediaStore(
                path,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentResolver
            )
            if (imageDeleted) return true
            
            // Try Videos MediaStore
            val videoDeleted = deleteFromSpecificMediaStore(
                path,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                contentResolver
            )
            if (videoDeleted) return true
            
            // Try Audio MediaStore
            val audioDeleted = deleteFromSpecificMediaStore(
                path,
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                contentResolver
            )
            if (audioDeleted) return true
            
            // Try general Files MediaStore
            val filesDeleted = deleteFromSpecificMediaStore(
                path,
                MediaStore.Files.getContentUri("external"),
                contentResolver
            )
            if (filesDeleted) return true
            
            // For Android 10+, try using relative path instead of DATA column
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                return deleteUsingRelativePath(path, contentResolver)
            }
            
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileOperations", "Error in deleteFromMediaStore: ${e.message}")
        }
        
        return false
    }
    
    /**
     * Delete from specific MediaStore collection
     */
    private fun deleteFromSpecificMediaStore(
        path: String,
        collectionUri: Uri,
        contentResolver: ContentResolver
    ): Boolean {
        return try {
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            
            // For Android 10+ avoid using DATA column
            val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
            } else {
                "${MediaStore.MediaColumns.DATA} = ?"
            }
            
            val selectionArgs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Extract filename from path
                arrayOf(java.io.File(path).name)
            } else {
                arrayOf(path)
            }
            
            contentResolver.query(collectionUri, projection, selection, selectionArgs, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val id = cursor.getLong(idColumn)
                    val deleteUri = ContentUris.withAppendedId(collectionUri, id)
                    
                    val deletedRows = contentResolver.delete(deleteUri, null, null)
                    if (deletedRows > 0) {
                        android.util.Log.d("ScopedStorageFileOperations", "Deleted from MediaStore: $path")
                        return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileOperations", "Error deleting from specific MediaStore: ${e.message}")
            false
        }
    }
    
    /**
     * Delete using relative path for Android 10+
     */
    private fun deleteUsingRelativePath(path: String, contentResolver: ContentResolver): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        
        try {
            val file = java.io.File(path)
            val fileName = file.name
            val parentPath = file.parent?.replace("/storage/emulated/0/", "") ?: ""
            
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?"
            val selectionArgs = arrayOf(fileName, "$parentPath/")
            
            val uri = MediaStore.Files.getContentUri("external")
            
            contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val id = cursor.getLong(idColumn)
                    val deleteUri = ContentUris.withAppendedId(uri, id)
                    
                    val deletedRows = contentResolver.delete(deleteUri, null, null)
                    if (deletedRows > 0) {
                        android.util.Log.d("ScopedStorageFileOperations", "Deleted using relative path: $path")
                        return true
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileOperations", "Error in deleteUsingRelativePath: ${e.message}")
        }
        
        return false
    }
    
    /**
     * Direct file deletion for older Android versions
     */
    private fun deleteDirectFile(path: String): Boolean {
        return try {
            val file = java.io.File(path)
            if (file.exists() && file.canWrite()) {
                val deleted = file.delete()
                if (deleted) {
                    android.util.Log.d("ScopedStorageFileOperations", "Direct file deletion successful: $path")
                }
                deleted
            } else {
                android.util.Log.d("ScopedStorageFileOperations", "File doesn't exist or can't write: $path")
                false
            }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileOperations", "Error in direct file deletion: ${e.message}")
            false
        }
    }
    
    /**
     * Delete via content resolver by querying all possible locations
     */
    private fun deleteViaContentResolver(path: String, contentResolver: ContentResolver): Boolean {
        try {
            // Extract filename
            val fileName = java.io.File(path).name
            
            // Try to find the file by display name across all media stores
            val collections = listOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Files.getContentUri("external")
            )
            
            for (collection in collections) {
                val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DISPLAY_NAME)
                val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
                val selectionArgs = arrayOf(fileName)
                
                contentResolver.query(collection, projection, selection, selectionArgs, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                        val id = cursor.getLong(idColumn)
                        val deleteUri = ContentUris.withAppendedId(collection, id)
                        
                        val deletedRows = contentResolver.delete(deleteUri, null, null)
                        if (deletedRows > 0) {
                            android.util.Log.d("ScopedStorageFileOperations", "Deleted via content resolver: $path from $collection")
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileOperations", "Error in deleteViaContentResolver: ${e.message}")
        }
        
        return false
    }
    
    /**
     * Extract ID from virtual path
     */
    private fun extractIdFromVirtualPath(virtualPath: String): Long? {
        // Virtual paths are in format: "type://relative/path/filename"
        // The ID is stored in our file data, but for now we'll need to query MediaStore
        // In a real implementation, we'd store the ID mapping
        return null
    }
    
    /**
     * Share files using content URIs
     */
    fun shareFiles(contentUris: List<String>): Boolean {
        return try {
            val fileOperations = FileOperations(context)
            
            // If we have content URIs, share them directly
            val uris = contentUris.mapNotNull { uriString ->
                try {
                    Uri.parse(uriString)
                } catch (e: Exception) {
                    null
                }
            }
            
            if (uris.isEmpty()) return false
            
            // Use existing share functionality with URIs
            val intent = android.content.Intent(android.content.Intent.ACTION_SEND_MULTIPLE).apply {
                type = "*/*"
                putParcelableArrayListExtra(android.content.Intent.EXTRA_STREAM, ArrayList(uris))
                flags = android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            
            val chooserIntent = android.content.Intent.createChooser(intent, "Share files")
            chooserIntent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(chooserIntent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    /**
     * Open file using content URI
     */
    fun openFile(contentUri: String): Boolean {
        return try {
            val uri = Uri.parse(contentUri)
            val intent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
                setDataAndType(uri, context.contentResolver.getType(uri))
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or 
                       android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                true
            } else {
                // Try with chooser
                val chooserIntent = android.content.Intent.createChooser(intent, "Open with")
                chooserIntent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(chooserIntent)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}