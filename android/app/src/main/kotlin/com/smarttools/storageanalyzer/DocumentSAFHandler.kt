package com.smarttools.storageanalyzer

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.text.SimpleDateFormat
import java.util.*

/**
 * Handler for Storage Access Framework (SAF) operations
 * Provides document scanning capabilities using Android's SAF API
 */
class DocumentSAFHandler(
    private val activity: Activity,
    private val context: Context
) {
    companion object {
        private const val TAG = "DocumentSAFHandler"
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 42
        
        // Document extensions to scan for
        private val DOCUMENT_EXTENSIONS = setOf(
            // PDF
            "pdf",
            // Office documents
            "doc", "docx", "odt", "rtf",
            // Spreadsheets
            "xls", "xlsx", "ods", "csv",
            // Presentations
            "ppt", "pptx", "odp",
            // Text files
            "txt", "md", "markdown", "log",
            // E-books
            "epub", "mobi", "azw", "azw3", "fb2",
            // Data/Config
            "json", "xml", "yaml", "yml", "ini", "conf", "cfg",
            // Code files
            "java", "kt", "dart", "js", "ts", "jsx", "tsx",
            "py", "cpp", "c", "h", "hpp", "cs", "swift",
            "go", "rs", "php", "rb", "lua", "sh", "bat",
            // Web
            "html", "htm", "css", "scss", "sass",
            // Other documents
            "tex", "wpd", "wps", "sql"
        )
        
        // Other file extensions (APKs, archives, executables, etc.)
        private val OTHER_EXTENSIONS = setOf(
            // Android packages
            "apk", "aab", "apks", "xapk",
            // Archives
            "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "tgz", "tbz",
            "cab", "iso", "dmg", "pkg", "deb", "rpm",
            // Executables and installers
            "exe", "msi", "app", "jar", "run", "com",
            // Data files
            "db", "sqlite", "sqlite3", "mdb", "accdb",
            // Binary files
            "bin", "dat", "bak", "tmp",
            // Development
            "aar", "so", "dll", "dylib", "lib",
            // Torrents
            "torrent",
            // Other
            "ics", "vcf", "msg", "eml", "gpx", "kml", "kmz"
        )
    }
    
    private var pendingResult: MethodChannel.Result? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    /**
     * Handle method calls from Flutter
     */
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "selectDocumentFolder", "selectFolder" -> selectDocumentFolder(result)
            "scanDocuments" -> scanDocuments(call, result)
            "scanOthers" -> scanOthers(call, result)
            "validateUri" -> validateUri(call, result)
            "releaseUriPermission" -> releaseUriPermission(call, result)
            else -> result.notImplemented()
        }
    }
    
    /**
     * Open document tree picker for folder selection
     */
    private fun selectDocumentFolder(result: MethodChannel.Result) {
        pendingResult = result
        
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            // Add flags for persistent permissions
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            
            // Set initial directory hint (Android 11+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, 
                    Uri.parse("content://com.android.externalstorage.documents/document/primary:Documents"))
            }
        }
        
        try {
            activity.startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening document tree picker", e)
            result.error("SAF_ERROR", "Failed to open document tree picker: ${e.message}", null)
            pendingResult = null
        }
    }
    
    /**
     * Handle activity result for document tree selection
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_OPEN_DOCUMENT_TREE) return false
        
        val result = pendingResult
        pendingResult = null
        
        if (resultCode == Activity.RESULT_OK && data != null) {
            val treeUri = data.data
            if (treeUri != null) {
                try {
                    // Take persistent permission
                    val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    context.contentResolver.takePersistableUriPermission(treeUri, takeFlags)
                    
                    // Get folder name
                    val docFile = DocumentFile.fromTreeUri(context, treeUri)
                    val folderName = docFile?.name ?: "Documents"
                    
                    Log.d(TAG, "Folder selected: $folderName")
                    Log.d(TAG, "URI: $treeUri")
                    
                    result?.success(mapOf(
                        "uri" to treeUri.toString(),
                        "name" to folderName,
                        "canRead" to (docFile?.canRead() ?: false),
                        "canWrite" to false // We only request read permission
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
     * Scan documents in the selected folder
     */
    private fun scanDocuments(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.error("INVALID_ARGUMENT", "URI is required", null)
            return
        }
        
        scope.launch {
            try {
                val uri = Uri.parse(uriString)
                val documents = mutableListOf<Map<String, Any>>()
                
                Log.d(TAG, "Starting document scan for URI: $uri")
                
                // Use DocumentFile for recursive scanning
                val rootDoc = DocumentFile.fromTreeUri(context, uri)
                if (rootDoc != null && rootDoc.exists() && rootDoc.canRead()) {
                    scanDocumentFileRecursively(rootDoc, documents)
                }
                
                Log.d(TAG, "Document scan complete. Found ${documents.size} documents")
                
                withContext(Dispatchers.Main) {
                    result.success(documents)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning documents", e)
                withContext(Dispatchers.Main) {
                    result.error("SCAN_ERROR", "Failed to scan documents: ${e.message}", null)
                }
            }
        }
    }
    
    /**
     * Recursively scan DocumentFile for documents
     */
    private suspend fun scanDocumentFileRecursively(
        documentFile: DocumentFile,
        documents: MutableList<Map<String, Any>>
    ): Unit = withContext(Dispatchers.IO) {
        try {
            if (documentFile.isDirectory) {
                // Scan directory contents
                val files: Array<DocumentFile> = documentFile.listFiles()
                files.forEach { child: DocumentFile ->
                    // Yield periodically to prevent blocking
                    if (documents.size % 50 == 0) {
                        yield()
                    }
                    scanDocumentFileRecursively(child, documents)
                }
            } else if (documentFile.isFile) {
                // Check if it's a document
                val name = documentFile.name ?: return@withContext
                val extension = getFileExtension(name).lowercase()
                
                if (extension in DOCUMENT_EXTENSIONS) {
                    val documentMap = mapOf(
                        "name" to name,
                        "path" to documentFile.uri.path.orEmpty(),
                        "uri" to documentFile.uri.toString(),
                        "size" to documentFile.length(),
                        "mimeType" to (documentFile.type ?: getMimeTypeForExtension(extension)),
                        "lastModified" to documentFile.lastModified(),
                        "extension" to ".$extension",
                        "canRead" to documentFile.canRead(),
                        "canWrite" to documentFile.canWrite()
                    )
                    
                    documents.add(documentMap)
                    
                    // Log progress
                    if (documents.size % 10 == 0) {
                        Log.d(TAG, "Found ${documents.size} documents so far...")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning file: ${documentFile.name}", e)
        }
    }
    
    /**
     * Validate if the URI still has permission
     */
    private fun validateUri(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.success(false)
            return
        }
        
        try {
            val uri = Uri.parse(uriString)
            val persistedUris = context.contentResolver.persistedUriPermissions
            
            val hasPermission = persistedUris.any { 
                it.uri == uri && it.isReadPermission
            }
            
            if (hasPermission) {
                // Try to actually access the URI to make sure it's valid
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
     * Release URI permission
     */
    private fun releaseUriPermission(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.success(true)
            return
        }
        
        try {
            val uri = Uri.parse(uriString)
            val releaseFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            
            context.contentResolver.releasePersistableUriPermission(uri, releaseFlags)
            Log.d(TAG, "Released permission for URI: $uri")
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing URI permission", e)
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
     * Get MIME type for common document extensions
     */
    private fun getMimeTypeForExtension(extension: String): String {
        return when (extension) {
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "txt" -> "text/plain"
            "csv" -> "text/csv"
            "xml" -> "text/xml"
            "html", "htm" -> "text/html"
            "json" -> "application/json"
            "rtf" -> "application/rtf"
            "odt" -> "application/vnd.oasis.opendocument.text"
            "ods" -> "application/vnd.oasis.opendocument.spreadsheet"
            "odp" -> "application/vnd.oasis.opendocument.presentation"
            "epub" -> "application/epub+zip"
            "mobi" -> "application/x-mobipocket-ebook"
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Scan for other files (APKs, archives, etc.) in the selected folder
     */
    private fun scanOthers(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.error("INVALID_ARGUMENT", "URI is required", null)
            return
        }
        
        scope.launch {
            try {
                val uri = Uri.parse(uriString)
                val otherFiles = mutableListOf<Map<String, Any>>()
                
                Log.d(TAG, "Starting other files scan for URI: $uri")
                
                // Use DocumentFile for recursive scanning
                val rootDoc = DocumentFile.fromTreeUri(context, uri)
                if (rootDoc != null && rootDoc.exists() && rootDoc.canRead()) {
                    scanOtherFilesRecursively(rootDoc, otherFiles)
                }
                
                Log.d(TAG, "Other files scan complete. Found ${otherFiles.size} files")
                
                withContext(Dispatchers.Main) {
                    // Return the result in the same format as documents
                    result.success(mapOf(
                        "files" to otherFiles
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning other files", e)
                withContext(Dispatchers.Main) {
                    result.error("SCAN_ERROR", "Failed to scan other files: ${e.message}", null)
                }
            }
        }
    }
    
    /**
     * Recursively scan DocumentFile for other files (APKs, archives, etc.)
     */
    private suspend fun scanOtherFilesRecursively(
        documentFile: DocumentFile,
        files: MutableList<Map<String, Any>>
    ): Unit = withContext(Dispatchers.IO) {
        try {
            if (documentFile.isDirectory) {
                // Scan directory contents
                val childFiles: Array<DocumentFile> = documentFile.listFiles()
                childFiles.forEach { child: DocumentFile ->
                    // Yield periodically to prevent blocking
                    if (files.size % 50 == 0) {
                        yield()
                    }
                    scanOtherFilesRecursively(child, files)
                }
            } else if (documentFile.isFile) {
                // Check if it's an "other" file type
                val name = documentFile.name ?: return@withContext
                val extension = getFileExtension(name).lowercase()
                
                if (extension in OTHER_EXTENSIONS) {
                    val fileMap = mapOf(
                        "name" to name,
                        "path" to documentFile.uri.path.orEmpty(),
                        "uri" to documentFile.uri.toString(),
                        "size" to documentFile.length(),
                        "mimeType" to (documentFile.type ?: getMimeTypeForOtherExtension(extension)),
                        "lastModified" to documentFile.lastModified(),
                        "extension" to ".$extension",
                        "canRead" to documentFile.canRead(),
                        "canWrite" to documentFile.canWrite()
                    )
                    
                    files.add(fileMap)
                    
                    // Log progress
                    if (files.size % 10 == 0) {
                        Log.d(TAG, "Found ${files.size} other files so far...")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning file: ${documentFile.name}", e)
        }
    }
    
    /**
     * Get MIME type for other file extensions
     */
    private fun getMimeTypeForOtherExtension(extension: String): String {
        return when (extension) {
            "apk" -> "application/vnd.android.package-archive"
            "zip" -> "application/zip"
            "rar" -> "application/x-rar-compressed"
            "7z" -> "application/x-7z-compressed"
            "tar" -> "application/x-tar"
            "gz" -> "application/gzip"
            "bz2" -> "application/x-bzip2"
            "iso" -> "application/x-iso9660-image"
            "exe" -> "application/x-msdownload"
            "jar" -> "application/java-archive"
            "db", "sqlite", "sqlite3" -> "application/x-sqlite3"
            "torrent" -> "application/x-bittorrent"
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
    }
}