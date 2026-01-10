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
                // Check if it's a content URI or a virtual path
                val deleted = when {
                    path.startsWith("content://") -> deleteByContentUri(path, contentResolver)
                    path.startsWith("image://") || path.startsWith("video://") || 
                    path.startsWith("audio://") || path.startsWith("document://") -> deleteByVirtualPath(path, contentResolver)
                    else -> deleteByPath(path, contentResolver)
                }
                
                if (deleted) {
                    deletedCount++
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
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
        // Try to find the file in MediaStore
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.MediaColumns.DATA} = ?"
        val selectionArgs = arrayOf(path)
        
        val uri = MediaStore.Files.getContentUri("external")
        
        contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val id = cursor.getLong(idColumn)
                val deleteUri = ContentUris.withAppendedId(uri, id)
                
                return try {
                    contentResolver.delete(deleteUri, null, null) > 0
                } catch (e: Exception) {
                    false
                }
            }
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