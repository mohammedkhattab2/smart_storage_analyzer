package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap

/**
 * Scoped Storage compliant file scanner that doesn't require MANAGE_EXTERNAL_STORAGE
 * Uses MediaStore APIs and other compliant methods for file access
 */
class ScopedStorageFileScanner(private val context: Context) {
    
    companion object {
        private const val BATCH_SIZE = 100
        private const val LARGE_FILE_THRESHOLD = 50 * 1024 * 1024L // 50MB
        private const val OLD_FILE_DAYS = 30
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
    }
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    /**
     * Scan files by category using Scoped Storage compliant methods
     */
    suspend fun scanFilesByCategory(category: String): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        when (category) {
            "all" -> scanAllFiles()
            "images" -> scanMediaFiles(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image")
            "videos" -> scanMediaFiles(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "video")
            "audio" -> scanMediaFiles(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, "audio")
            "documents" -> scanDocumentsViaMediaStore()
            "apps" -> scanInstalledApps()
            "others" -> scanOtherFiles()
            "large" -> scanLargeFiles()
            "old" -> scanOldFiles()
            "duplicates" -> scanDuplicates()
            else -> emptyList()
        }
    }
    
    /**
     * Scan all files using MediaStore
     */
    private suspend fun scanAllFiles(): List<Map<String, Any>> = coroutineScope {
        val allFiles = ConcurrentHashMap<String, Map<String, Any>>()
        
        // Launch parallel scans for each media type
        val jobs = listOf(
            async { scanMediaFilesInternal(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image", allFiles) },
            async { scanMediaFilesInternal(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "video", allFiles) },
            async { scanMediaFilesInternal(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, "audio", allFiles) },
            async { scanDocumentsViaMediaStoreInternal(allFiles) },
            async { scanInstalledAppsInternal(allFiles) }
        )
        
        jobs.awaitAll()
        allFiles.values.sortedByDescending { (it["size"] as Long) }
    }
    
    /**
     * Scan media files using MediaStore
     */
    private suspend fun scanMediaFiles(uri: Uri, type: String): List<Map<String, Any>> {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        
        // For audio files, also scan by extension to catch all audio formats
        if (type == "audio") {
            scanMediaFilesInternal(uri, type, files)
            scanAudioByExtension(files)
        } else {
            scanMediaFilesInternal(uri, type, files)
        }
        
        return files.values.sortedByDescending { (it["size"] as Long) }
    }
    
    /**
     * Scan audio files by extension to catch all formats
     * Includes: mp3, wav, aac, ogg, opus, m4a, flac
     */
    private suspend fun scanAudioByExtension(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        val audioExtensions = listOf(
            ".mp3", ".wav", ".aac", ".ogg", ".opus", ".m4a", ".flac",
            ".wma", ".amr", ".3gpp", ".3gp", ".webm", ".ac3", ".aiff",
            ".alac", ".ape", ".dts", ".mka", ".mp2", ".mpc", ".ra", ".tta", ".wv"
        )
        
        audioExtensions.forEach { ext ->
            try {
                val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    arrayOf(
                        MediaStore.Files.FileColumns._ID,
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        MediaStore.Files.FileColumns.RELATIVE_PATH,
                        MediaStore.Files.FileColumns.SIZE,
                        MediaStore.Files.FileColumns.DATE_MODIFIED,
                        MediaStore.Files.FileColumns.MIME_TYPE
                    )
                } else {
                    arrayOf(
                        MediaStore.Files.FileColumns._ID,
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        MediaStore.Files.FileColumns.DATA,
                        MediaStore.Files.FileColumns.SIZE,
                        MediaStore.Files.FileColumns.DATE_MODIFIED,
                        MediaStore.Files.FileColumns.MIME_TYPE
                    )
                }
                
                val selection = "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"
                val selectionArgs = arrayOf("%$ext")
                
                context.contentResolver.query(
                    MediaStore.Files.getContentUri("external"),
                    projection,
                    selection,
                    selectionArgs,
                    null
                )?.use { cursor ->
                    processCursor(cursor, fileMap, "audio")
                }
            } catch (e: Exception) {
                android.util.Log.e("ScopedStorageFileScanner", "Error scanning $ext audio files: ${e.message}")
            }
        }
    }
    
    private suspend fun scanMediaFilesInternal(
        uri: Uri,
        type: String,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.RELATIVE_PATH,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.MIME_TYPE
            )
        } else {
            arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.DATA,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.MIME_TYPE
            )
        }
        
        context.contentResolver.query(
            uri,
            projection,
            null,
            null,
            "${MediaStore.MediaColumns.SIZE} DESC"
        )?.use { cursor ->
            processCursor(cursor, fileMap, type)
        }
    }
    
    /**
     * Scan documents using MediaStore.Files and extension-based search
     */
    private suspend fun scanDocumentsViaMediaStore(): List<Map<String, Any>> {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        
        android.util.Log.d("ScopedStorageFileScanner", "Starting comprehensive document scan...")
        
        try {
            // Try multiple scanning approaches
            scanDocumentsViaMediaStoreInternal(files)
            android.util.Log.d("ScopedStorageFileScanner", "MIME scan found ${files.size} documents")
            
            scanDocumentsByExtension(files)
            android.util.Log.d("ScopedStorageFileScanner", "Extension scan total: ${files.size} documents")
            
            scanDownloadsForDocuments(files)
            android.util.Log.d("ScopedStorageFileScanner", "After Downloads scan: ${files.size} documents")
            
            // Scan all files and filter for document extensions
            scanAllFilesForDocuments(files)
            android.util.Log.d("ScopedStorageFileScanner", "After comprehensive scan: ${files.size} documents")
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "Error during document scan: ${e.message}", e)
        }
        
        val result = files.values.sortedByDescending { (it["size"] as? Long) ?: 0L }
        android.util.Log.d("ScopedStorageFileScanner", "Returning ${result.size} total documents")
        
        return result
    }
    
    /**
     * Comprehensive scan for all document files
     */
    private suspend fun scanAllFilesForDocuments(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        android.util.Log.d("ScopedStorageFileScanner", "=== COMPREHENSIVE DOCUMENT SCAN START ===")
        
        // All document extensions we want to find
        val documentExtensions = setOf(
            // Common documents
            "pdf", "doc", "docx", "txt",
            // Spreadsheets
            "xls", "xlsx", "csv", "ods",
            // Presentations
            "ppt", "pptx", "odp",
            // E-books and reading
            "epub", "mobi", "azw", "fb2",
            // Rich text
            "rtf", "odt",
            // Web documents
            "html", "htm", "xml", "mhtml",
            // Data files
            "json", "sql", "db",
            // Config and logs
            "log", "ini", "cfg", "conf",
            // Code files
            "java", "kt", "dart", "js", "ts", "py", "cpp", "c", "h",
            // Notes and markdown
            "md", "markdown", "note",
            // Other office formats
            "wpd", "wps", "tex"
        )
        
        android.util.Log.d("ScopedStorageFileScanner", "Looking for extensions: ${documentExtensions.joinToString()}")
        
        try {
            // Query ALL files from MediaStore
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Files.getContentUri("external")
            }
            
            android.util.Log.d("ScopedStorageFileScanner", "Using URI: $uri")
            val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.RELATIVE_PATH,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.DATE_MODIFIED,
                    MediaStore.Files.FileColumns.MIME_TYPE
                )
            } else {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.DATA,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.DATE_MODIFIED,
                    MediaStore.Files.FileColumns.MIME_TYPE
                )
            }
            
            // Query all files without any filters
            android.util.Log.d("ScopedStorageFileScanner", "Executing MediaStore query...")
            val cursor = context.contentResolver.query(
                uri,
                projection,
                null, // No filter - get ALL files
                null,
                null  // No sort order limit
            )
            
            android.util.Log.d("ScopedStorageFileScanner", "=== QUERY RESULT: ${cursor?.count ?: 0} total files in MediaStore ===")
            
            if (cursor == null) {
                android.util.Log.e("ScopedStorageFileScanner", "ERROR: Cursor is null! MediaStore query failed.")
                return@withContext
            }
            
            cursor.use { cursor ->
                android.util.Log.d("ScopedStorageFileScanner", "Processing cursor with ${cursor.count} files...")
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
                val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
                
                val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
                } else {
                    cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
                }
                
                var scannedCount = 0
                var totalScanned = 0
                var debugLogCount = 0
                
                while (cursor.moveToNext()) {
                    totalScanned++
                    
                    try {
                        val name = cursor.getString(nameColumn) ?: continue
                        val size = cursor.getLong(sizeColumn)
                        
                        // Log first few files for debugging
                        if (debugLogCount < 10) {
                            android.util.Log.d("ScopedStorageFileScanner", "File #$totalScanned: $name (size: $size)")
                            debugLogCount++
                        }
                        
                        // Skip empty files
                        if (size <= 0) continue
                        
                        // Get extension without the dot
                        val extension = if (name.contains(".")) {
                            name.substringAfterLast(".").lowercase()
                        } else {
                            ""
                        }
                        
                        // Check if this is a document
                        if (extension in documentExtensions || isDocumentByName(name)) {
                            val id = cursor.getLong(idColumn)
                            
                            // Skip if already in map
                            if (fileMap.containsKey(id.toString())) {
                                android.util.Log.d("ScopedStorageFileScanner", "Skipping duplicate: $name")
                                continue
                            }
                            
                            val dateModified = cursor.getLong(dateColumn) * 1000
                            val mimeType = cursor.getString(mimeColumn) ?: getMimeTypeForExtension(".$extension")
                            
                            // Use content URI as the path for API 29+
                            val contentUri = getContentUriForFile("document", id)
                            val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                contentUri
                            } else {
                                cursor.getString(pathColumn) ?: contentUri
                            }
                            
                            android.util.Log.d("ScopedStorageFileScanner", "✓ FOUND DOCUMENT: $name (ext: .$extension, size: $size bytes)")
                            
                            fileMap[id.toString()] = mapOf(
                                "id" to id.toString(),
                                "name" to name,
                                "path" to path,
                                "size" to size,
                                "lastModified" to dateModified,
                                "extension" to ".$extension",
                                "mimeType" to mimeType,
                                "contentUri" to contentUri
                            )
                            
                            scannedCount++
                            if (scannedCount % 5 == 0) {
                                android.util.Log.d("ScopedStorageFileScanner", "=== Found $scannedCount documents so far ===")
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("ScopedStorageFileScanner", "Error processing file at position $totalScanned: ${e.message}")
                    }
                    
                    // Yield periodically
                    if (cursor.position % 100 == 0) {
                        yield()
                    }
                }
                
                android.util.Log.d("ScopedStorageFileScanner", "=== SCAN COMPLETE: Checked $totalScanned files, found $scannedCount documents ===")
            }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "ERROR in comprehensive scan: ${e.message}", e)
            e.printStackTrace()
        }
        
        android.util.Log.d("ScopedStorageFileScanner", "=== COMPREHENSIVE DOCUMENT SCAN END: ${fileMap.size} documents in map ===")
    }
    
    /**
     * Get MIME type for extension
     */
    private fun getMimeTypeForExtension(extension: String): String {
        return when (extension) {
            ".pdf" -> "application/pdf"
            ".doc" -> "application/msword"
            ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ".xls" -> "application/vnd.ms-excel"
            ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            ".ppt" -> "application/vnd.ms-powerpoint"
            ".pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            ".txt" -> "text/plain"
            ".csv" -> "text/csv"
            ".xml" -> "text/xml"
            ".html", ".htm" -> "text/html"
            ".json" -> "application/json"
            ".rtf" -> "application/rtf"
            ".odt" -> "application/vnd.oasis.opendocument.text"
            ".ods" -> "application/vnd.oasis.opendocument.spreadsheet"
            ".odp" -> "application/vnd.oasis.opendocument.presentation"
            else -> "application/octet-stream"
        }
    }
    
    
    private suspend fun scanDocumentsViaMediaStoreInternal(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        // Expanded list of document MIME types
        val documentMimeTypes = arrayOf(
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-powerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "text/plain",
            "text/csv",
            "text/xml",
            "text/html",
            "text/rtf",
            "application/rtf",
            "application/vnd.oasis.opendocument.text",
            "application/vnd.oasis.opendocument.spreadsheet",
            "application/vnd.oasis.opendocument.presentation",
            "application/epub+zip",
            "application/x-mobipocket-ebook"
        )
        
        val selection = documentMimeTypes.joinToString(" OR ") {
            "${MediaStore.Files.FileColumns.MIME_TYPE} = ?"
        }
        
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.RELATIVE_PATH,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        } else {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        }
        
        context.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            documentMimeTypes,
            "${MediaStore.Files.FileColumns.SIZE} DESC"
        )?.use { cursor ->
            processCursor(cursor, fileMap, "document")
        }
    }
    
    /**
     * Scan documents by file extension as fallback
     * This catches documents that aren't registered in MediaStore
     */
    private suspend fun scanDocumentsByExtension(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        android.util.Log.d("ScopedStorageFileScanner", "Scanning popular document extensions...")
        
        // Focus on most common document extensions for quick scan
        val commonExtensions = listOf(
            ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx", ".ppt", ".pptx",
            ".csv", ".rtf", ".odt"
        )
        
        commonExtensions.forEach { ext ->
            try {
                val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    arrayOf(
                        MediaStore.Files.FileColumns._ID,
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        MediaStore.Files.FileColumns.RELATIVE_PATH,
                        MediaStore.Files.FileColumns.SIZE,
                        MediaStore.Files.FileColumns.DATE_MODIFIED,
                        MediaStore.Files.FileColumns.MIME_TYPE
                    )
                } else {
                    arrayOf(
                        MediaStore.Files.FileColumns._ID,
                        MediaStore.Files.FileColumns.DISPLAY_NAME,
                        MediaStore.Files.FileColumns.DATA,
                        MediaStore.Files.FileColumns.SIZE,
                        MediaStore.Files.FileColumns.DATE_MODIFIED,
                        MediaStore.Files.FileColumns.MIME_TYPE
                    )
                }
                
                val selection = "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"
                val selectionArgs = arrayOf("%$ext")
                
                context.contentResolver.query(
                    MediaStore.Files.getContentUri("external"),
                    projection,
                    selection,
                    selectionArgs,
                    null // No limit, get all files
                )?.use { cursor ->
                    val countBefore = fileMap.size
                    processCursorWithDuplicateCheck(cursor, fileMap, "document")
                    val countAfter = fileMap.size
                    if (countAfter > countBefore) {
                        android.util.Log.d("ScopedStorageFileScanner", "Found ${countAfter - countBefore} $ext files")
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("ScopedStorageFileScanner", "Error scanning $ext: ${e.message}")
            }
        }
    }
    
    /**
     * Specifically scan Downloads folder for documents
     */
    private suspend fun scanDownloadsForDocuments(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        android.util.Log.d("ScopedStorageFileScanner", "Scanning Downloads folder for documents...")
        
        try {
            // Query all files in Downloads folder
            val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.RELATIVE_PATH,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.DATE_MODIFIED,
                    MediaStore.Files.FileColumns.MIME_TYPE
                )
            } else {
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.DATA,
                    MediaStore.Files.FileColumns.SIZE,
                    MediaStore.Files.FileColumns.DATE_MODIFIED,
                    MediaStore.Files.FileColumns.MIME_TYPE
                )
            }
            
            // Look for files in Download directory
            val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                "${MediaStore.Files.FileColumns.RELATIVE_PATH} LIKE ?"
            } else {
                "${MediaStore.Files.FileColumns.DATA} LIKE ?"
            }
            
            val selectionArgs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf("Download%")
            } else {
                arrayOf("%/Download%")
            }
            
            context.contentResolver.query(
                MediaStore.Files.getContentUri("external"),
                projection,
                selection,
                selectionArgs,
                "${MediaStore.Files.FileColumns.SIZE} DESC"
            )?.use { cursor ->
                val countBefore = fileMap.size
                
                // Process all files from Downloads and filter for documents
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                
                val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
                } else {
                    cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                }
                
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val name = cursor.getString(nameColumn) ?: "Unknown"
                    val size = cursor.getLong(sizeColumn)
                    
                    if (fileMap.containsKey(id.toString()) || size <= 0) continue
                    
                    val extension = getExtension(name).lowercase()
                    
                    // Check if it's a document
                    if (extension in listOf(
                        ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx",
                        ".ppt", ".pptx", ".csv", ".rtf", ".odt", ".ods", ".odp"
                    )) {
                        val dateModified = cursor.getLong(dateColumn) * 1000
                        val mimeType = cursor.getString(mimeColumn) ?: "application/octet-stream"
                        
                        // Use content URI as the path for API 29+
                        val contentUri = getContentUriForFile("document", id)
                        val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            contentUri
                        } else {
                            cursor.getString(pathColumn) ?: contentUri
                        }
                        
                        fileMap[id.toString()] = mapOf(
                            "id" to id.toString(),
                            "name" to name,
                            "path" to path,
                            "size" to size,
                            "lastModified" to dateModified,
                            "extension" to extension,
                            "mimeType" to mimeType,
                            "contentUri" to contentUri
                        )
                    }
                }
                
                val countAfter = fileMap.size
                android.util.Log.d("ScopedStorageFileScanner", "Found ${countAfter - countBefore} documents in Downloads")
            }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "Error scanning Downloads: ${e.message}")
        }
    }
    
    /**
     * Process cursor with duplicate checking
     */
    private suspend fun processCursorWithDuplicateCheck(
        cursor: Cursor,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        type: String
    ) = withContext(Dispatchers.IO) {
        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
        val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
        val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
        val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
        val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
        
        // Handle path differently for API 29+
        val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
        } else {
            cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
        }
        
        while (cursor.moveToNext()) {
            val id = cursor.getLong(idColumn)
            val name = cursor.getString(nameColumn) ?: "Unknown"
            val size = cursor.getLong(sizeColumn)
            
            // Skip if already in map (avoid duplicates)
            if (fileMap.containsKey(id.toString())) continue
            
            val dateModified = cursor.getLong(dateColumn) * 1000
            val mimeType = cursor.getString(mimeColumn) ?: "application/octet-stream"
            
            if (size <= 0) continue
            
            // For API 29+, use content URI as the path
            val contentUri = getContentUriForFile(type, id)
            val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Use content URI as the path for API 29+
                contentUri
            } else {
                // For older versions, use the actual file path
                cursor.getString(pathColumn) ?: contentUri
            }
            
            // Check if it's actually a document by extension
            val extension = getExtension(name).lowercase()
            val isDocument = extension in listOf(
                ".pdf", ".doc", ".docx", ".txt", ".odt", ".rtf", ".tex", ".wpd", ".md",
                ".xls", ".xlsx", ".ods", ".csv", ".tsv",
                ".ppt", ".pptx", ".odp", ".pps", ".ppsx",
                ".epub", ".mobi", ".azw", ".azw3", ".fb2", ".lit",
                ".xml", ".json", ".log", ".ini", ".cfg", ".conf", ".properties",
                ".html", ".htm", ".xhtml", ".mhtml", ".chm"
            )
            
            if (isDocument) {
                val fileInfo = mapOf(
                    "id" to id.toString(),
                    "name" to name,
                    "path" to path,
                    "size" to size,
                    "lastModified" to dateModified,
                    "extension" to getExtension(name),
                    "mimeType" to mimeType,
                    "contentUri" to contentUri // Store content URI for operations
                )
                
                fileMap[id.toString()] = fileInfo
            }
            
            // Yield periodically
            if (fileMap.size % BATCH_SIZE == 0) {
                yield()
            }
        }
    }
    
    /**
     * Process cursor data
     */
    private suspend fun processCursor(
        cursor: Cursor,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        type: String
    ) = withContext(Dispatchers.IO) {
        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
        val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
        val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
        val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
        val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
        
        // Handle path differently for API 29+
        val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
        } else {
            cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
        }
        
        while (cursor.moveToNext()) {
            val id = cursor.getLong(idColumn)
            val name = cursor.getString(nameColumn) ?: "Unknown"
            val size = cursor.getLong(sizeColumn)
            val dateModified = cursor.getLong(dateColumn) * 1000
            val mimeType = cursor.getString(mimeColumn) ?: "application/octet-stream"
            
            if (size <= 0) continue
            
            // For API 29+, use content URI as the path
            val contentUri = getContentUriForFile(type, id)
            val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Use content URI as the path for API 29+
                contentUri
            } else {
                // For older versions, use the actual file path
                cursor.getString(pathColumn) ?: contentUri
            }
            
            val fileInfo = mapOf(
                "id" to id.toString(),
                "name" to name,
                "path" to path,
                "size" to size,
                "lastModified" to dateModified,
                "extension" to getExtension(name),
                "mimeType" to mimeType,
                "contentUri" to contentUri // Store content URI for operations
            )
            
            fileMap[id.toString()] = fileInfo
            
            // Yield periodically
            if (fileMap.size % BATCH_SIZE == 0) {
                yield()
            }
        }
    }
    
    /**
     * Get content URI for file operations
     */
    private fun getContentUriForFile(type: String, id: Long): String {
        val contentUri = when (type) {
            "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> MediaStore.Files.getContentUri("external")
        }
        return Uri.withAppendedPath(contentUri, id.toString()).toString()
    }
    
    /**
     * Scan installed apps
     */
    private suspend fun scanInstalledApps(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val apps = mutableListOf<Map<String, Any>>()
        val packageManager = context.packageManager
        
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledApplications(0)
        }
        
        packages.forEach { appInfo ->
            try {
                // Include user-installed apps and updated system apps
                if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
                    (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0) {
                    
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val apkPath = appInfo.sourceDir
                    val apkFile = java.io.File(apkPath)
                    
                    if (apkFile.exists()) {
                        apps.add(mapOf(
                            "id" to appInfo.packageName,
                            "name" to "$appName.apk",
                            "path" to "app://${appInfo.packageName}", // Virtual path
                            "size" to apkFile.length(),
                            "lastModified" to apkFile.lastModified(),
                            "extension" to ".apk",
                            "mimeType" to "application/vnd.android.package-archive",
                            "packageName" to appInfo.packageName
                        ))
                    }
                }
            } catch (e: Exception) {
                // Skip problematic apps
            }
        }
        
        apps.sortedByDescending { (it["size"] as Long) }
    }
    
    private suspend fun scanInstalledAppsInternal(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) {
        scanInstalledApps().forEach { app ->
            fileMap[app["id"] as String] = app
        }
    }
    
    /**
     * Scan other files using MediaStore.Files
     */
    private suspend fun scanOtherFiles(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        
        // Query for files that don't match common media/document types
        val excludedMimeTypes = arrayOf(
            "image/%", "video/%", "audio/%",
            "application/pdf", "application/msword",
            "application/vnd.openxmlformats-officedocument%",
            "application/vnd.ms-%", "text/%"
        )
        
        val selection = excludedMimeTypes.joinToString(" AND ") {
            "${MediaStore.Files.FileColumns.MIME_TYPE} NOT LIKE ?"
        }
        
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.RELATIVE_PATH,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        } else {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        }
        
        context.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            excludedMimeTypes,
            "${MediaStore.Files.FileColumns.SIZE} DESC"
        )?.use { cursor ->
            processCursor(cursor, files, "other")
        }
        
        files.values.sortedByDescending { (it["size"] as Long) }
    }
    
    /**
     * Scan large files
     */
    private suspend fun scanLargeFiles(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val files = mutableListOf<Map<String, Any>>()
        
        // Query MediaStore for large files
        val selection = "${MediaStore.Files.FileColumns.SIZE} > ?"
        val selectionArgs = arrayOf(LARGE_FILE_THRESHOLD.toString())
        
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.RELATIVE_PATH,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        } else {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        }
        
        context.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Files.FileColumns.SIZE} DESC"
        )?.use { cursor ->
            val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
            processCursor(cursor, fileMap, "file")
            files.addAll(fileMap.values)
        }
        
        files
    }
    
    /**
     * Scan old files
     */
    private suspend fun scanOldFiles(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val files = mutableListOf<Map<String, Any>>()
        val threshold = System.currentTimeMillis() - OLD_FILE_THRESHOLD
        
        val selection = "${MediaStore.Files.FileColumns.DATE_MODIFIED} < ?"
        val selectionArgs = arrayOf((threshold / 1000).toString())
        
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.RELATIVE_PATH,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        } else {
            arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
            )
        }
        
        context.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Files.FileColumns.SIZE} DESC"
        )?.use { cursor ->
            val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
            processCursor(cursor, fileMap, "file")
            files.addAll(fileMap.values)
        }
        
        files
    }
    
    /**
     * Scan duplicate files using content-based hashing for accuracy
     */
    private suspend fun scanDuplicates(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        android.util.Log.d("ScopedStorageFileScanner", "Starting comprehensive duplicate scan...")
        
        val allFiles = scanAllFiles()
        val duplicates = mutableListOf<Map<String, Any>>()
        
        if (allFiles.isEmpty()) {
            android.util.Log.d("ScopedStorageFileScanner", "No files found for duplicate scanning")
            return@withContext emptyList()
        }

        // Filter files for duplicate checking (skip very small files)
        val filesToCheck = allFiles.filter { file ->
            val size = file["size"] as? Long ?: 0L
            size > 1024 // Skip files smaller than 1KB
        }
        
        android.util.Log.d("ScopedStorageFileScanner", "Checking ${filesToCheck.size} files for duplicates")
        
        // Step 1: Group files by size (fast initial filter)
        val sizeGroups = filesToCheck.groupBy { it["size"] as Long }
            .filter { it.value.size > 1 }
        
        android.util.Log.d("ScopedStorageFileScanner", "Found ${sizeGroups.size} size groups with potential duplicates")
        
        // Step 2: For files with same size, check content hash
        for ((size, files) in sizeGroups) {
            if (files.size < 2) continue
            
            // Use quick hash for initial grouping (first 4KB)
            val quickHashGroups = mutableMapOf<String, MutableList<Map<String, Any>>>()
            
            for (file in files) {
                val contentUri = file["contentUri"] as? String ?: continue
                val quickHash = calculateQuickHashFromUri(contentUri)
                if (quickHash != null) {
                    quickHashGroups.getOrPut(quickHash) { mutableListOf() }.add(file)
                }
            }
            
            // For files with same quick hash, do full MD5 hash
            for ((_, quickGroup) in quickHashGroups) {
                if (quickGroup.size < 2) continue
                
                val fullHashGroups = mutableMapOf<String, MutableList<Map<String, Any>>>()
                
                for (file in quickGroup) {
                    val contentUri = file["contentUri"] as? String ?: continue
                    val size = file["size"] as? Long ?: 0L
                    val fullHash = calculateFileHashFromUri(contentUri, size)
                    if (fullHash != null) {
                        fullHashGroups.getOrPut(fullHash) { mutableListOf() }.add(file)
                    }
                }
                
                // Mark actual duplicates
                for ((hash, duplicateGroup) in fullHashGroups) {
                    if (duplicateGroup.size > 1) {
                        // Sort to keep original in preferred locations
                        duplicateGroup.sortWith(compareBy(
                            { !(it["path"] as String).contains("/DCIM/", ignoreCase = true) },
                            { !(it["path"] as String).contains("/Pictures/", ignoreCase = true) },
                            { !(it["path"] as String).contains("/Download/", ignoreCase = true) },
                            { it["lastModified"] as? Long ?: 0L } // Oldest first
                        ))
                        
                        // Add all except the first as duplicates
                        duplicates.addAll(duplicateGroup.drop(1))
                        
                        android.util.Log.d("ScopedStorageFileScanner",
                            "Found ${duplicateGroup.size - 1} duplicates of ${duplicateGroup[0]["name"]}")
                    }
                }
            }
        }
        
        android.util.Log.d("ScopedStorageFileScanner", "Total duplicates found: ${duplicates.size}")
        duplicates.sortedByDescending { (it["size"] as Long) }
    }
    
    /**
     * Calculate quick hash of first 4KB of file using ContentResolver
     */
    private fun calculateQuickHashFromUri(contentUriString: String): String? {
        return try {
            val uri = Uri.parse(contentUriString)
            val digest = java.security.MessageDigest.getInstance("MD5")
            
            context.contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArray(4096) // Only read first 4KB
                val bytesRead = input.read(buffer)
                if (bytesRead > 0) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "Error calculating quick hash for $contentUriString: ${e.message}")
            null
        }
    }
    
    /**
     * Calculate full MD5 hash of file using ContentResolver
     */
    private fun calculateFileHashFromUri(contentUriString: String, fileSize: Long): String? {
        // Skip very large files (> 500MB) for performance
        if (fileSize > 500L * 1024 * 1024) {
            // For large files, use combined hash of beginning, middle, and end
            return calculateLargeFileHashFromUri(contentUriString, fileSize)
        }
        
        return try {
            val uri = Uri.parse(contentUriString)
            val digest = java.security.MessageDigest.getInstance("MD5")
            
            context.contentResolver.openInputStream(uri)?.buffered(8192)?.use { input ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                while (input.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "Error calculating file hash for $contentUriString: ${e.message}")
            null
        }
    }
    
    /**
     * Calculate hash for large files by sampling different parts using ContentResolver
     */
    private fun calculateLargeFileHashFromUri(contentUriString: String, fileSize: Long): String? {
        return try {
            val uri = Uri.parse(contentUriString)
            val digest = java.security.MessageDigest.getInstance("MD5")
            
            // Read in three chunks: beginning, middle, end
            context.contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArray(4096)
                
                // Read beginning
                val bytesRead1 = input.read(buffer)
                if (bytesRead1 > 0) {
                    digest.update(buffer, 0, bytesRead1)
                }
                
                // Skip to middle (skip requires mark support, so we read and discard)
                val skipToMiddle = (fileSize / 2) - 4096
                if (skipToMiddle > 0) {
                    var skipped = 0L
                    val skipBuffer = ByteArray(8192)
                    while (skipped < skipToMiddle) {
                        val toSkip = minOf(skipBuffer.size.toLong(), skipToMiddle - skipped)
                        val read = input.read(skipBuffer, 0, toSkip.toInt())
                        if (read <= 0) break
                        skipped += read
                    }
                }
                
                // Read middle
                val bytesRead2 = input.read(buffer)
                if (bytesRead2 > 0) {
                    digest.update(buffer, 0, bytesRead2)
                }
                
                // Skip to near end
                val skipToEnd = maxOf(0, fileSize - (fileSize / 2 + 4096) - 4096)
                if (skipToEnd > 0) {
                    var skipped = 0L
                    val skipBuffer = ByteArray(8192)
                    while (skipped < skipToEnd) {
                        val toSkip = minOf(skipBuffer.size.toLong(), skipToEnd - skipped)
                        val read = input.read(skipBuffer, 0, toSkip.toInt())
                        if (read <= 0) break
                        skipped += read
                    }
                }
                
                // Read end
                val bytesRead3 = input.read(buffer)
                if (bytesRead3 > 0) {
                    digest.update(buffer, 0, bytesRead3)
                }
                
                // Add file size to hash for additional uniqueness
                digest.update(fileSize.toString().toByteArray())
            }
            
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            android.util.Log.e("ScopedStorageFileScanner", "Error calculating large file hash for $contentUriString: ${e.message}")
            null
        }
    }
    
    /**
     * Check if file is a document by name pattern
     */
    private fun isDocumentByName(name: String): Boolean {
        val lowerName = name.lowercase()
        return lowerName.contains("document") ||
               lowerName.contains("report") ||
               lowerName.contains("invoice") ||
               lowerName.contains("receipt") ||
               lowerName.contains("contract") ||
               lowerName.contains("resume") ||
               lowerName.contains("cv") ||
               lowerName.contains("letter") ||
               lowerName.contains("certificate")
    }
    
    private fun getExtension(name: String): String {
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0 && lastDot < name.length - 1) {
            name.substring(lastDot).lowercase()
        } else ""
    }
    
    fun cleanup() {
        scope.cancel()
    }
}