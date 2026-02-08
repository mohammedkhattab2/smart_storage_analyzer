package com.smarttools.storageanalyzer

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.*

/**
 * SAF-based Media Scanner for policy-compliant media file access.
 * 
 * This scanner uses Storage Access Framework (SAF) to scan user-selected folders
 * for media files without requiring READ_MEDIA_* permissions.
 * 
 * Compliant with Google Play Photo and Video Permissions policy.
 */
class SafMediaScanner(
    private val activity: Activity,
    private val context: Context
) {
    companion object {
        private const val TAG = "SafMediaScanner"
        
        // Request codes for different media types
        private const val REQUEST_CODE_IMAGES_FOLDER = 100
        private const val REQUEST_CODE_VIDEOS_FOLDER = 101
        private const val REQUEST_CODE_AUDIO_FOLDER = 102
        private const val REQUEST_CODE_GENERAL_FOLDER = 103
        
        // Image extensions
        private val IMAGE_EXTENSIONS = setOf(
            "jpg", "jpeg", "png", "gif", "bmp", "webp", "heic", "heif",
            "raw", "cr2", "nef", "orf", "sr2", "tiff", "tif", "svg", "ico"
        )
        
        // Video extensions
        private val VIDEO_EXTENSIONS = setOf(
            "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v",
            "mpg", "mpeg", "3gp", "3g2", "mts", "m2ts", "ts", "vob"
        )
        
        // Audio extensions
        private val AUDIO_EXTENSIONS = setOf(
            "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a", "opus",
            "amr", "ape", "aiff", "alac", "mid", "midi"
        )
        
        // Shared preferences key for persisted URIs
        private const val PREFS_NAME = "saf_media_scanner_prefs"
        private const val KEY_IMAGES_URI = "images_folder_uri"
        private const val KEY_VIDEOS_URI = "videos_folder_uri"
        private const val KEY_AUDIO_URI = "audio_folder_uri"
    }
    
    private var pendingResult: MethodChannel.Result? = null
    private var pendingMediaType: String? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    /**
     * Handle method calls from Flutter
     */
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "selectMediaFolder" -> {
                val mediaType = call.argument<String>("mediaType") ?: "images"
                selectMediaFolder(mediaType, result)
            }
            "scanMediaFolder" -> {
                val uriString = call.argument<String>("uri")
                val mediaType = call.argument<String>("mediaType") ?: "images"
                if (uriString != null) {
                    scanMediaFolder(uriString, mediaType, result)
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }
            "getPersistedMediaUri" -> {
                val mediaType = call.argument<String>("mediaType") ?: "images"
                getPersistedMediaUri(mediaType, result)
            }
            "clearPersistedMediaUri" -> {
                val mediaType = call.argument<String>("mediaType") ?: "images"
                clearPersistedMediaUri(mediaType, result)
            }
            "validateMediaUri" -> {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    validateMediaUri(uriString, result)
                } else {
                    result.success(false)
                }
            }
            "selectFolder" -> {
                selectGeneralFolder(result)
            }
            "scanFolderForFiles" -> {
                val uriString = call.argument<String>("uri")
                val recursive = call.argument<Boolean>("recursive") ?: true
                if (uriString != null) {
                    scanFolderForAllFiles(uriString, recursive, result)
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }
    
    /**
     * Open folder picker for media type selection
     */
    private fun selectMediaFolder(mediaType: String, result: MethodChannel.Result) {
        pendingResult = result
        pendingMediaType = mediaType
        
        val requestCode = when (mediaType) {
            "images" -> REQUEST_CODE_IMAGES_FOLDER
            "videos" -> REQUEST_CODE_VIDEOS_FOLDER
            "audio" -> REQUEST_CODE_AUDIO_FOLDER
            else -> REQUEST_CODE_IMAGES_FOLDER
        }
        
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            
            // Set initial directory hint based on media type (Android 8.0+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val initialUri = when (mediaType) {
                    "images" -> "content://com.android.externalstorage.documents/document/primary:DCIM"
                    "videos" -> "content://com.android.externalstorage.documents/document/primary:Movies"
                    "audio" -> "content://com.android.externalstorage.documents/document/primary:Music"
                    else -> "content://com.android.externalstorage.documents/document/primary:DCIM"
                }
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(initialUri))
            }
        }
        
        try {
            activity.startActivityForResult(intent, requestCode)
            Log.d(TAG, "Opened folder picker for media type: $mediaType")
        } catch (e: Exception) {
            Log.e(TAG, "Error opening folder picker", e)
            result.error("SAF_ERROR", "Failed to open folder picker: ${e.message}", null)
            pendingResult = null
            pendingMediaType = null
        }
    }
    
    /**
     * Handle activity result from folder picker
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val validRequestCodes = listOf(
            REQUEST_CODE_IMAGES_FOLDER,
            REQUEST_CODE_VIDEOS_FOLDER,
            REQUEST_CODE_AUDIO_FOLDER,
            REQUEST_CODE_GENERAL_FOLDER
        )
        
        if (requestCode !in validRequestCodes) return false
        
        val result = pendingResult
        val mediaType = pendingMediaType
        pendingResult = null
        pendingMediaType = null
        
        if (resultCode == Activity.RESULT_OK && data != null) {
            val treeUri = data.data
            if (treeUri != null) {
                try {
                    // Take persistent permission
                    val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    context.contentResolver.takePersistableUriPermission(treeUri, takeFlags)
                    
                    // Get folder info
                    val docFile = DocumentFile.fromTreeUri(context, treeUri)
                    val folderName = docFile?.name ?: "Selected Folder"
                    
                    // Persist the URI for this media type
                    if (mediaType != null) {
                        persistMediaUri(mediaType, treeUri.toString())
                    }
                    
                    Log.d(TAG, "Folder selected for $mediaType: $folderName")
                    Log.d(TAG, "URI: $treeUri")
                    
                    result?.success(mapOf(
                        "uri" to treeUri.toString(),
                        "name" to folderName,
                        "mediaType" to mediaType,
                        "canRead" to (docFile?.canRead() ?: false)
                    ))
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing selected folder", e)
                    result?.error("SAF_ERROR", "Failed to process selected folder: ${e.message}", null)
                }
            } else {
                result?.error("SAF_ERROR", "No folder selected", null)
            }
        } else {
            // User cancelled
            result?.success(null)
        }
        
        return true
    }
    
    /**
     * Scan media folder for files of specified type
     */
    private fun scanMediaFolder(uriString: String, mediaType: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                val uri = Uri.parse(uriString)
                val mediaFiles = mutableListOf<Map<String, Any>>()
                var totalSize: Long = 0
                
                Log.d(TAG, "Starting $mediaType scan for URI: $uri")
                
                val extensions = when (mediaType) {
                    "images" -> IMAGE_EXTENSIONS
                    "videos" -> VIDEO_EXTENSIONS
                    "audio" -> AUDIO_EXTENSIONS
                    else -> IMAGE_EXTENSIONS
                }
                
                // Use DocumentFile for recursive scanning
                val rootDoc = DocumentFile.fromTreeUri(context, uri)
                if (rootDoc != null && rootDoc.exists() && rootDoc.canRead()) {
                    scanMediaFilesRecursively(rootDoc, mediaFiles, extensions, mediaType)
                    totalSize = mediaFiles.sumOf { (it["size"] as? Long) ?: 0L }
                }
                
                // Sort by size (largest first)
                val sortedFiles = mediaFiles.sortedByDescending { (it["size"] as? Long) ?: 0L }
                
                Log.d(TAG, "$mediaType scan complete. Found ${sortedFiles.size} files, total size: $totalSize")
                
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "files" to sortedFiles,
                        "totalSize" to totalSize,
                        "fileCount" to sortedFiles.size,
                        "mediaType" to mediaType,
                        "folderUri" to uriString
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning $mediaType folder", e)
                withContext(Dispatchers.Main) {
                    result.error("SCAN_ERROR", "Failed to scan $mediaType folder: ${e.message}", null)
                }
            }
        }
    }
    
    /**
     * Recursively scan for media files
     */
    private suspend fun scanMediaFilesRecursively(
        documentFile: DocumentFile,
        files: MutableList<Map<String, Any>>,
        extensions: Set<String>,
        mediaType: String,
        depth: Int = 0,
        maxDepth: Int = 10
    ): Unit = withContext(Dispatchers.IO) {
        if (depth > maxDepth) return@withContext
        
        try {
            if (documentFile.isDirectory) {
                val children = documentFile.listFiles()
                for (child in children) {
                    // Yield periodically to prevent blocking
                    if (files.size % 50 == 0) {
                        yield()
                    }
                    scanMediaFilesRecursively(child, files, extensions, mediaType, depth + 1, maxDepth)
                }
            } else if (documentFile.isFile) {
                val name = documentFile.name ?: return@withContext
                val extension = getFileExtension(name).lowercase()
                
                if (extension in extensions) {
                    val fileSize = documentFile.length()
                    val lastModified = documentFile.lastModified()
                    val mimeType = documentFile.type ?: getMimeTypeForMedia(extension, mediaType)
                    
                    val fileMap = mapOf(
                        "id" to documentFile.uri.toString().hashCode().toString(),
                        "name" to name,
                        "path" to (documentFile.uri.path ?: ""),
                        "uri" to documentFile.uri.toString(),
                        "size" to fileSize,
                        "lastModified" to lastModified,
                        "extension" to ".$extension",
                        "mimeType" to mimeType,
                        "mediaType" to mediaType,
                        "canRead" to documentFile.canRead()
                    )
                    
                    files.add(fileMap)
                    
                    // Log progress periodically
                    if (files.size % 100 == 0) {
                        Log.d(TAG, "Found ${files.size} $mediaType files so far...")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning file: ${documentFile.name}", e)
        }
    }
    
    /**
     * Get persisted URI for media type
     */
    private fun getPersistedMediaUri(mediaType: String, result: MethodChannel.Result) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val key = when (mediaType) {
                "images" -> KEY_IMAGES_URI
                "videos" -> KEY_VIDEOS_URI
                "audio" -> KEY_AUDIO_URI
                else -> KEY_IMAGES_URI
            }
            
            val uriString = prefs.getString(key, null)
            
            if (uriString != null) {
                // Validate the URI still has permission
                val uri = Uri.parse(uriString)
                val persistedUris = context.contentResolver.persistedUriPermissions
                val hasPermission = persistedUris.any { it.uri == uri && it.isReadPermission }
                
                if (hasPermission) {
                    val docFile = DocumentFile.fromTreeUri(context, uri)
                    if (docFile != null && docFile.exists() && docFile.canRead()) {
                        result.success(mapOf(
                            "uri" to uriString,
                            "name" to (docFile.name ?: "Selected Folder"),
                            "mediaType" to mediaType,
                            "isValid" to true
                        ))
                        return
                    }
                }
                
                // URI is no longer valid, clear it
                clearPersistedMediaUriInternal(mediaType)
            }
            
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting persisted URI", e)
            result.success(null)
        }
    }
    
    /**
     * Clear persisted URI for media type
     */
    private fun clearPersistedMediaUri(mediaType: String, result: MethodChannel.Result) {
        try {
            clearPersistedMediaUriInternal(mediaType)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing persisted URI", e)
            result.success(false)
        }
    }
    
    private fun clearPersistedMediaUriInternal(mediaType: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = when (mediaType) {
            "images" -> KEY_IMAGES_URI
            "videos" -> KEY_VIDEOS_URI
            "audio" -> KEY_AUDIO_URI
            else -> KEY_IMAGES_URI
        }
        
        // Get the URI before clearing
        val uriString = prefs.getString(key, null)
        if (uriString != null) {
            try {
                val uri = Uri.parse(uriString)
                context.contentResolver.releasePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing URI permission", e)
            }
        }
        
        prefs.edit().remove(key).apply()
        Log.d(TAG, "Cleared persisted URI for $mediaType")
    }
    
    /**
     * Persist URI for media type
     */
    private fun persistMediaUri(mediaType: String, uriString: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = when (mediaType) {
            "images" -> KEY_IMAGES_URI
            "videos" -> KEY_VIDEOS_URI
            "audio" -> KEY_AUDIO_URI
            else -> KEY_IMAGES_URI
        }
        
        prefs.edit().putString(key, uriString).apply()
        Log.d(TAG, "Persisted URI for $mediaType: $uriString")
    }
    
    /**
     * Validate if URI is still accessible
     */
    private fun validateMediaUri(uriString: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(uriString)
            val persistedUris = context.contentResolver.persistedUriPermissions
            val hasPermission = persistedUris.any { it.uri == uri && it.isReadPermission }
            
            if (hasPermission) {
                val docFile = DocumentFile.fromTreeUri(context, uri)
                result.success(docFile != null && docFile.exists() && docFile.canRead())
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error validating URI", e)
            result.success(false)
        }
    }
    
    /**
     * Get file extension from filename
     */
    private fun getFileExtension(filename: String): String {
        val lastDot = filename.lastIndexOf('.')
        return if (lastDot > 0 && lastDot < filename.length - 1) {
            filename.substring(lastDot + 1)
        } else {
            ""
        }
    }
    
    /**
     * Get MIME type for media file
     */
    private fun getMimeTypeForMedia(extension: String, mediaType: String): String {
        return when (mediaType) {
            "images" -> when (extension) {
                "jpg", "jpeg" -> "image/jpeg"
                "png" -> "image/png"
                "gif" -> "image/gif"
                "bmp" -> "image/bmp"
                "webp" -> "image/webp"
                "heic", "heif" -> "image/heif"
                "svg" -> "image/svg+xml"
                "tiff", "tif" -> "image/tiff"
                else -> "image/*"
            }
            "videos" -> when (extension) {
                "mp4" -> "video/mp4"
                "mkv" -> "video/x-matroska"
                "avi" -> "video/x-msvideo"
                "mov" -> "video/quicktime"
                "wmv" -> "video/x-ms-wmv"
                "flv" -> "video/x-flv"
                "webm" -> "video/webm"
                "3gp" -> "video/3gpp"
                else -> "video/*"
            }
            "audio" -> when (extension) {
                "mp3" -> "audio/mpeg"
                "wav" -> "audio/wav"
                "flac" -> "audio/flac"
                "aac" -> "audio/aac"
                "ogg" -> "audio/ogg"
                "wma" -> "audio/x-ms-wma"
                "m4a" -> "audio/mp4"
                "opus" -> "audio/opus"
                else -> "audio/*"
            }
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Open general folder picker (not media-specific)
     */
    private fun selectGeneralFolder(result: MethodChannel.Result) {
        pendingResult = result
        pendingMediaType = "general"
        
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        
        try {
            activity.startActivityForResult(intent, REQUEST_CODE_GENERAL_FOLDER)
            Log.d(TAG, "Opened general folder picker")
        } catch (e: Exception) {
            Log.e(TAG, "Error opening folder picker", e)
            result.error("SAF_ERROR", "Failed to open folder picker: ${e.message}", null)
            pendingResult = null
            pendingMediaType = null
        }
    }
    
    /**
     * Scan folder for all files (not just media)
     */
    private fun scanFolderForAllFiles(uriString: String, recursive: Boolean, result: MethodChannel.Result) {
        scope.launch {
            try {
                val uri = Uri.parse(uriString)
                val allFiles = mutableListOf<Map<String, Any>>()
                var totalSize: Long = 0
                
                Log.d(TAG, "Starting general file scan for URI: $uri")
                
                val rootDoc = DocumentFile.fromTreeUri(context, uri)
                if (rootDoc != null && rootDoc.exists() && rootDoc.canRead()) {
                    scanAllFilesRecursively(rootDoc, allFiles, recursive, 0, if (recursive) 10 else 1)
                    totalSize = allFiles.sumOf { (it["size"] as? Long) ?: 0L }
                }
                
                // Sort by size (largest first)
                val sortedFiles = allFiles.sortedByDescending { (it["size"] as? Long) ?: 0L }
                
                Log.d(TAG, "General file scan complete. Found ${sortedFiles.size} files, total size: $totalSize")
                
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "files" to sortedFiles,
                        "totalSize" to totalSize,
                        "fileCount" to sortedFiles.size,
                        "folderUri" to uriString
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning folder for files", e)
                withContext(Dispatchers.Main) {
                    result.error("SCAN_ERROR", "Failed to scan folder: ${e.message}", null)
                }
            }
        }
    }
    
    /**
     * Recursively scan for all files
     */
    private suspend fun scanAllFilesRecursively(
        documentFile: DocumentFile,
        files: MutableList<Map<String, Any>>,
        recursive: Boolean,
        depth: Int,
        maxDepth: Int
    ): Unit = withContext(Dispatchers.IO) {
        if (depth > maxDepth) return@withContext
        
        try {
            if (documentFile.isDirectory) {
                if (recursive || depth == 0) {
                    val children = documentFile.listFiles()
                    for (child in children) {
                        if (files.size % 50 == 0) {
                            yield()
                        }
                        scanAllFilesRecursively(child, files, recursive, depth + 1, maxDepth)
                    }
                }
            } else if (documentFile.isFile) {
                val name = documentFile.name ?: return@withContext
                val fileSize = documentFile.length()
                val lastModified = documentFile.lastModified()
                val extension = getFileExtension(name).lowercase()
                val mimeType = documentFile.type ?: "application/octet-stream"
                
                val fileMap = mapOf(
                    "id" to documentFile.uri.toString().hashCode().toString(),
                    "name" to name,
                    "path" to (documentFile.uri.path ?: ""),
                    "uri" to documentFile.uri.toString(),
                    "size" to fileSize,
                    "lastModified" to lastModified,
                    "extension" to if (extension.isNotEmpty()) ".$extension" else "",
                    "mimeType" to mimeType,
                    "canRead" to documentFile.canRead()
                )
                
                files.add(fileMap)
                
                if (files.size % 100 == 0) {
                    Log.d(TAG, "Found ${files.size} files so far...")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning file: ${documentFile.name}", e)
        }
    }
    
    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
    }
}