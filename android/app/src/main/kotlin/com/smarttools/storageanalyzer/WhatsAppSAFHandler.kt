package com.smarttools.storageanalyzer

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.util.*

/**
 * High-performance Storage Access Framework (SAF) & MediaStore Handler for WhatsApp Media.
 * Uses direct ContentResolver Cursor batching for sub-second scanning across 10,000+ files.
 */
class WhatsAppSAFHandler(
    private val activity: Activity,
    private val context: Context
) {
    companion object {
        private const val TAG = "WhatsAppSAFHandler"
        const val REQUEST_CODE_WHATSAPP_TREE = 104

        // Extension sets
        private val IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "webp", "heic")
        private val VIDEO_EXTENSIONS = setOf("mp4", "mkv", "3gp", "mov", "webm")
        private val AUDIO_EXTENSIONS = setOf("opus", "m4a", "aac", "mp3", "ogg", "wav", "amr")
        private val DOCUMENT_EXTENSIONS = setOf("pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "zip", "rar", "apk")
    }

    private var pendingResult: MethodChannel.Result? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /**
     * Handle method calls from Flutter
     */
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "selectWhatsAppFolder" -> selectWhatsAppFolder(result)
            "scanWhatsAppMedia" -> scanWhatsAppMedia(call, result)
            "deleteWhatsAppFiles" -> deleteWhatsAppFiles(call, result)
            "validateWhatsAppUri" -> validateWhatsAppUri(call, result)
            "tryDirectScan" -> tryDirectScan(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Try scanning WhatsApp directly via MediaStore and Direct Paths
     */
    private fun tryDirectScan(result: MethodChannel.Result) {
        scope.launch {
            try {
                val items = mutableListOf<Map<String, Any>>()
                val seenKeys = mutableSetOf<String>()

                // 1. Query MediaStore
                queryMediaStoreForWhatsApp(items, seenKeys)

                // 2. Query Direct Filesystem if accessible
                val directDir = findDirectWhatsAppDirectory()
                if (directDir != null && directDir.exists() && directDir.canRead()) {
                    scanDirectDirectory(directDir, "", items, seenKeys, 0, 4)
                }

                if (items.isNotEmpty()) {
                    Log.d(TAG, "Direct scan found ${items.size} WhatsApp files")
                    withContext(Dispatchers.Main) {
                        result.success(mapOf(
                            "path" to (directDir?.absolutePath ?: "mediastore://whatsapp"),
                            "items" to items
                        ))
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        result.success(null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in tryDirectScan", e)
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            }
        }
    }

    private fun findDirectWhatsAppDirectory(): File? {
        val root = Environment.getExternalStorageDirectory()
        val candidatePaths = listOf(
            File(root, "Android/media/com.whatsapp/WhatsApp/Media"),
            File(root, "Android/media/com.whatsapp/WhatsApp"),
            File(root, "Android/media/com.whatsapp"),
            File(root, "WhatsApp/Media"),
            File(root, "WhatsApp"),
            File(root, "Android/media/com.whatsapp.w4b/WhatsApp Business/Media"),
            File(root, "Android/media/com.whatsapp.w4b")
        )

        for (candidate in candidatePaths) {
            if (candidate.exists() && candidate.canRead()) {
                val files = candidate.listFiles()
                if (files != null && files.isNotEmpty()) {
                    return candidate
                }
            }
        }
        return null
    }

    private fun scanDirectDirectory(
        dir: File,
        currentPath: String,
        items: MutableList<Map<String, Any>>,
        seenKeys: MutableSet<String>,
        depth: Int = 0,
        maxDepth: Int = 4
    ) {
        if (depth > maxDepth) return
        try {
            val files = dir.listFiles() ?: return
            for (file in files) {
                val name = file.name
                val lowerName = name.lowercase()

                if (file.isDirectory) {
                    if (lowerName == "backups" || lowerName == "databases" || lowerName == ".trash" || lowerName.startsWith("backup")) {
                        continue
                    }
                    val relativePath = if (currentPath.isEmpty()) name else "$currentPath/$name"
                    scanDirectDirectory(file, relativePath, items, seenKeys, depth + 1, maxDepth)
                } else if (file.isFile) {
                    val key = name + "_" + file.length()
                    if (seenKeys.contains(key) || seenKeys.contains(file.absolutePath)) continue

                    val ext = getFileExtension(name).lowercase()
                    val relativePath = if (currentPath.isEmpty()) name else "$currentPath/$name"
                    val categoryInfo = categorizeWhatsAppFile(relativePath, name, ext)

                    if (categoryInfo != null) {
                        val (category, isSent, isVoiceNote) = categoryInfo
                        items.add(mapOf(
                            "id" to file.absolutePath,
                            "name" to name,
                            "path" to file.absolutePath,
                            "uri" to Uri.fromFile(file).toString(),
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to ".$ext",
                            "mimeType" to getMimeType(ext),
                            "category" to category,
                            "isSent" to isSent,
                            "isVoiceNote" to isVoiceNote
                        ))
                        seenKeys.add(key)
                        seenKeys.add(file.absolutePath)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning direct directory: ${dir.absolutePath}", e)
        }
    }

    /**
     * Fast query to Android MediaStore for indexed WhatsApp files (Images, Video, Audio)
     */
    private fun queryMediaStoreForWhatsApp(
        items: MutableList<Map<String, Any>>,
        seenKeys: MutableSet<String>
    ) {
        try {
            val collections = listOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            )

            val projection = arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.DATA,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.MIME_TYPE
            )

            val selection = "${MediaStore.MediaColumns.DATA} LIKE ? OR ${MediaStore.MediaColumns.DATA} LIKE ?"
            val selectionArgs = arrayOf(
                "%com.whatsapp%",
                "%/WhatsApp/%"
            )

            for (collection in collections) {
                try {
                    context.contentResolver.query(collection, projection, selection, selectionArgs, null)?.use { cursor ->
                        val idCol = cursor.getColumnIndex(MediaStore.MediaColumns._ID)
                        val nameCol = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                        val dataCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                        val sizeCol = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                        val dateCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED)
                        val mimeCol = cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE)

                        if (idCol == -1 || dataCol == -1) return@use

                        while (cursor.moveToNext()) {
                            val id = cursor.getLong(idCol)
                            val path = cursor.getString(dataCol) ?: continue
                            val name = if (nameCol != -1) cursor.getString(nameCol) ?: File(path).name else File(path).name
                            val size = if (sizeCol != -1) cursor.getLong(sizeCol) else 0L
                            val dateModified = if (dateCol != -1) cursor.getLong(dateCol) * 1000L else System.currentTimeMillis()
                            val mimeType = if (mimeCol != -1) cursor.getString(mimeCol) ?: "" else ""
                            val contentUri = ContentUris.withAppendedId(collection, id).toString()

                            val key = name + "_" + size
                            if (seenKeys.contains(key) || seenKeys.contains(path) || seenKeys.contains(contentUri)) continue

                            val ext = getFileExtension(name).lowercase()
                            val categoryInfo = categorizeWhatsAppFile(path, name, ext)

                            if (categoryInfo != null) {
                                val (category, isSent, isVoiceNote) = categoryInfo
                                items.add(mapOf(
                                    "id" to contentUri,
                                    "name" to name,
                                    "path" to path,
                                    "uri" to contentUri,
                                    "size" to size,
                                    "lastModified" to dateModified,
                                    "extension" to ".$ext",
                                    "mimeType" to (mimeType.ifEmpty { getMimeType(ext) }),
                                    "category" to category,
                                    "isSent" to isSent,
                                    "isVoiceNote" to isVoiceNote
                                ))
                                seenKeys.add(key)
                                seenKeys.add(path)
                                seenKeys.add(contentUri)
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Error querying collection $collection", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in queryMediaStoreForWhatsApp", e)
        }
    }

    /**
     * Open document tree picker for WhatsApp folder selection
     */
    private fun selectWhatsAppFolder(result: MethodChannel.Result) {
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    val initialDocUri = DocumentsContract.buildDocumentUri(
                        "com.android.externalstorage.documents",
                        "primary:Android/media/com.whatsapp"
                    )
                    putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialDocUri)
                } catch (e: Exception) {
                    Log.w(TAG, "Could not build initial URI hint", e)
                }
            }
        }

        try {
            activity.startActivityForResult(intent, REQUEST_CODE_WHATSAPP_TREE)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening WhatsApp document tree picker", e)
            result.error("SAF_ERROR", "Failed to open folder picker: ${e.message}", null)
            pendingResult = null
        }
    }

    /**
     * Handle activity result for WhatsApp folder selection
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_WHATSAPP_TREE) return false

        val result = pendingResult
        pendingResult = null

        if (resultCode == Activity.RESULT_OK && data != null) {
            val treeUri = data.data
            if (treeUri != null) {
                try {
                    val takeFlags = (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    context.contentResolver.takePersistableUriPermission(treeUri, takeFlags)

                    val docFile = DocumentFile.fromTreeUri(context, treeUri)
                    val folderName = docFile?.name ?: "WhatsApp"

                    Log.d(TAG, "WhatsApp Folder selected: $folderName, URI: $treeUri")

                    result?.success(mapOf(
                        "uri" to treeUri.toString(),
                        "name" to folderName,
                        "canRead" to (docFile?.canRead() ?: false),
                        "canWrite" to (docFile?.canWrite() ?: false)
                    ))
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing selected WhatsApp folder", e)
                    result?.error("SAF_ERROR", "Failed to persist WhatsApp folder permission: ${e.message}", null)
                }
            } else {
                result?.error("SAF_ERROR", "No folder selected", null)
            }
        } else {
            result?.success(null)
        }

        return true
    }

    /**
     * Validate whether a stored URI still has read/write permission
     */
    private fun validateWhatsAppUri(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.success(false)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            if (uri.scheme == "file" || uri.scheme == "mediastore") {
                result.success(true)
                return
            }
            val docFile = DocumentFile.fromTreeUri(context, uri)
            val isValid = docFile != null && docFile.exists() && docFile.canRead()
            result.success(isValid)
        } catch (e: Exception) {
            Log.e(TAG, "Error validating WhatsApp URI: $uriString", e)
            result.success(false)
        }
    }

    /**
     * Ultra-fast WhatsApp media scan combining batch SAF Cursor queries and MediaStore
     */
    private fun scanWhatsAppMedia(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.error("INVALID_ARGUMENT", "Folder URI is required", null)
            return
        }

        scope.launch {
            try {
                val uri = Uri.parse(uriString)
                val items = mutableListOf<Map<String, Any>>()
                val seenKeys = mutableSetOf<String>()

                // 1. First batch query MediaStore (Extremely fast, usually 50-100ms)
                queryMediaStoreForWhatsApp(items, seenKeys)

                // 2. High-speed Direct Cursor SAF query (Batch queries, avoids IPC overhead of DocumentFile)
                if (uri.scheme == "content") {
                    try {
                        val rootDocId = DocumentsContract.getTreeDocumentId(uri)
                        scanFastSAF(uri, rootDocId, "", items, seenKeys, 0, 5)
                    } catch (e: Exception) {
                        Log.w(TAG, "Fast SAF query fallback to DocumentFile", e)
                        val rootDoc = DocumentFile.fromTreeUri(context, uri)
                        if (rootDoc != null && rootDoc.exists() && rootDoc.canRead()) {
                            scanDocumentFileFallback(rootDoc, "", items, seenKeys, 0, 3)
                        }
                    }
                }

                // 3. Query Direct Filesystem if candidate exists
                val directDir = findDirectWhatsAppDirectory()
                if (directDir != null && directDir.exists() && directDir.canRead()) {
                    scanDirectDirectory(directDir, "", items, seenKeys, 0, 4)
                }

                Log.d(TAG, "WhatsApp media scan completed successfully! Total items: ${items.size}")
                withContext(Dispatchers.Main) {
                    result.success(items)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning WhatsApp media", e)
                withContext(Dispatchers.Main) {
                    result.error("SCAN_ERROR", "Failed to scan WhatsApp media: ${e.message}", null)
                }
            }
        }
    }

    /**
     * High-speed batch ContentResolver cursor query for SAF trees.
     * Executes in 1 single SQL query per directory instead of 6 IPC roundtrips per file!
     */
    private suspend fun scanFastSAF(
        treeUri: Uri,
        parentDocId: String,
        currentPath: String,
        items: MutableList<Map<String, Any>>,
        seenKeys: MutableSet<String>,
        depth: Int = 0,
        maxDepth: Int = 5
    ): Unit = withContext(Dispatchers.IO) {
        if (depth > maxDepth) return@withContext

        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )

        val subDirectories = mutableListOf<Pair<String, String>>()

        try {
            context.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                val idIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                val modIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

                while (cursor.moveToNext()) {
                    val docId = cursor.getString(idIndex) ?: continue
                    val name = cursor.getString(nameIndex) ?: continue
                    val mimeType = cursor.getString(mimeIndex) ?: ""
                    val size = if (sizeIndex != -1) cursor.getLong(sizeIndex) else 0L
                    val lastModified = if (modIndex != -1) cursor.getLong(modIndex) else 0L

                    val isDirectory = mimeType == DocumentsContract.Document.MIME_TYPE_DIR
                    val lowerName = name.lowercase()

                    if (isDirectory) {
                        if (lowerName != "backups" && lowerName != "databases" && lowerName != ".trash" && !lowerName.startsWith("backup")) {
                            val relPath = if (currentPath.isEmpty()) name else "$currentPath/$name"
                            subDirectories.add(Pair(docId, relPath))
                        }
                    } else {
                        val fileDocUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                        val ext = getFileExtension(name).lowercase()
                        val relPath = if (currentPath.isEmpty()) name else "$currentPath/$name"
                        val key = name + "_" + size

                        if (!seenKeys.contains(key) && !seenKeys.contains(fileDocUri.toString())) {
                            val categoryInfo = categorizeWhatsAppFile(relPath, name, ext)
                            if (categoryInfo != null) {
                                val (category, isSent, isVoiceNote) = categoryInfo
                                items.add(mapOf(
                                    "id" to fileDocUri.toString(),
                                    "name" to name,
                                    "path" to relPath,
                                    "uri" to fileDocUri.toString(),
                                    "size" to size,
                                    "lastModified" to lastModified,
                                    "extension" to ".$ext",
                                    "mimeType" to (mimeType.ifEmpty { getMimeType(ext) }),
                                    "category" to category,
                                    "isSent" to isSent,
                                    "isVoiceNote" to isVoiceNote
                                ))
                                seenKeys.add(key)
                                seenKeys.add(fileDocUri.toString())
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fast querying SAF cursor for docId: $parentDocId", e)
        }

        // Recursively traverse subdirectories
        for ((subDocId, subPath) in subDirectories) {
            scanFastSAF(treeUri, subDocId, subPath, items, seenKeys, depth + 1, maxDepth)
        }
    }

    /**
     * Fallback DocumentFile scanner with strict depth
     */
    private suspend fun scanDocumentFileFallback(
        dir: DocumentFile,
        currentPath: String,
        items: MutableList<Map<String, Any>>,
        seenKeys: MutableSet<String>,
        depth: Int = 0,
        maxDepth: Int = 3
    ): Unit = withContext(Dispatchers.IO) {
        if (depth > maxDepth) return@withContext
        try {
            val children = dir.listFiles()
            for (child in children) {
                val childName = child.name ?: continue
                val lowerName = childName.lowercase()

                if (child.isDirectory) {
                    if (lowerName == "backups" || lowerName == "databases" || lowerName == ".trash" || lowerName.startsWith("backup")) {
                        continue
                    }
                    val relativePath = if (currentPath.isEmpty()) childName else "$currentPath/$childName"
                    yield()
                    scanDocumentFileFallback(child, relativePath, items, seenKeys, depth + 1, maxDepth)
                } else if (child.isFile) {
                    val key = childName + "_" + child.length()
                    if (seenKeys.contains(key) || seenKeys.contains(child.uri.toString())) continue

                    val ext = getFileExtension(childName).lowercase()
                    val relativePath = if (currentPath.isEmpty()) childName else "$currentPath/$childName"
                    val categoryInfo = categorizeWhatsAppFile(relativePath, childName, ext)

                    if (categoryInfo != null) {
                        val (category, isSent, isVoiceNote) = categoryInfo
                        items.add(mapOf(
                            "id" to child.uri.toString(),
                            "name" to childName,
                            "path" to (child.uri.path ?: relativePath),
                            "uri" to child.uri.toString(),
                            "size" to child.length(),
                            "lastModified" to child.lastModified(),
                            "extension" to ".$ext",
                            "mimeType" to (child.type ?: getMimeType(ext)),
                            "category" to category,
                            "isSent" to isSent,
                            "isVoiceNote" to isVoiceNote
                        ))
                        seenKeys.add(key)
                        seenKeys.add(child.uri.toString())
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in DocumentFile fallback scan", e)
        }
    }

    /**
     * Categorize a file based on its relative path, file name, and extension
     */
    private fun categorizeWhatsAppFile(
        path: String,
        name: String,
        ext: String
    ): Triple<String, Boolean, Boolean>? {
        val lowerPath = path.lowercase().replace('\\', '/')
        val lowerName = name.lowercase()
        val isSent = lowerPath.contains("/sent") || lowerPath.contains("sent/") || lowerName.startsWith("sent_")

        // 1. Statuses
        if (lowerPath.contains(".statuses") || lowerPath.contains("statuses")) {
            return if (ext in IMAGE_EXTENSIONS || ext in VIDEO_EXTENSIONS) {
                Triple("statuses", false, false)
            } else null
        }

        // 2. Voice Notes (.opus or .m4a or audio inside Voice Notes / PTT)
        if (lowerPath.contains("voice notes") || lowerPath.contains("voice") || ext == "opus" || lowerName.startsWith("ptt-") || lowerPath.contains("ptt-")) {
            return Triple("voiceNotes", isSent, true)
        }

        // 3. Animated GIFs
        if (lowerPath.contains("animated gifs") || lowerPath.contains("gifs") || ext == "gif") {
            return Triple("animatedGifs", isSent, false)
        }

        // 4. Stickers
        if (lowerPath.contains("stickers") || (ext == "webp" && (lowerPath.contains("whatsapp") || lowerName.startsWith("stk-")))) {
            return Triple("stickers", isSent, false)
        }

        // 5. Video
        if (lowerPath.contains("video") || ext in VIDEO_EXTENSIONS || lowerName.startsWith("vid-") || lowerName.contains("whatsapp video")) {
            return Triple("videos", isSent, false)
        }

        // 6. Images / Photos
        if (lowerPath.contains("images") || lowerPath.contains("image") || ext in IMAGE_EXTENSIONS || lowerName.startsWith("img-") || lowerName.contains("whatsapp image")) {
            return Triple("images", isSent, false)
        }

        // 7. Audio (Music/Recordings other than Voice Notes)
        if (lowerPath.contains("audio") || ext in AUDIO_EXTENSIONS || lowerName.startsWith("aud-")) {
            return Triple("audio", isSent, false)
        }

        // 8. Documents
        if (lowerPath.contains("documents") || ext in DOCUMENT_EXTENSIONS || lowerName.startsWith("doc-")) {
            return Triple("documents", isSent, false)
        }

        // Fallback for known extensions in WhatsApp directory
        if (ext in IMAGE_EXTENSIONS) return Triple("images", isSent, false)
        if (ext in VIDEO_EXTENSIONS) return Triple("videos", isSent, false)
        if (ext in AUDIO_EXTENSIONS) return Triple("audio", isSent, false)
        if (ext in DOCUMENT_EXTENSIONS) return Triple("documents", isSent, false)

        return null
    }

    /**
     * Delete files by their SAF URIs or content URIs or file paths
     */
    private fun deleteWhatsAppFiles(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.argument<List<String>>("uris")
        if (uris == null || uris.isEmpty()) {
            result.success(0)
            return
        }

        scope.launch {
            var deletedCount = 0
            for (uriString in uris) {
                try {
                    var success = false
                    val uri = Uri.parse(uriString)

                    if (uri.scheme == "content") {
                        // 1. Try DocumentsContract.deleteDocument
                        try {
                            if (DocumentsContract.isDocumentUri(context, uri) || uriString.contains("/document/")) {
                                success = DocumentsContract.deleteDocument(context.contentResolver, uri)
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "DocumentsContract delete failed for $uriString", e)
                        }

                        // 2. Try DocumentFile delete
                        if (!success) {
                            try {
                                val docFile = DocumentFile.fromSingleUri(context, uri)
                                if (docFile != null && docFile.exists()) {
                                    success = docFile.delete()
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "DocumentFile delete failed for $uriString", e)
                            }
                        }

                        // 3. Try ContentResolver delete (MediaStore content://media/external/...)
                        if (!success) {
                            try {
                                val rows = context.contentResolver.delete(uri, null, null)
                                success = rows > 0
                            } catch (e: Exception) {
                                Log.w(TAG, "ContentResolver delete failed for $uriString", e)
                            }
                        }
                    } else {
                        // Physical file path or file:// URI
                        val filePath = if (uri.scheme == "file") uri.path ?: "" else uriString
                        val file = File(filePath)
                        if (file.exists()) {
                            success = file.delete()
                        }
                    }

                    if (success) {
                        deletedCount++
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to delete WhatsApp file: $uriString", e)
                }
            }

            Log.d(TAG, "Deleted $deletedCount of ${uris.size} WhatsApp files successfully")
            withContext(Dispatchers.Main) {
                result.success(deletedCount)
            }
        }
    }

    private fun getFileExtension(fileName: String): String {
        val lastDotIndex = fileName.lastIndexOf('.')
        return if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
            fileName.substring(lastDotIndex + 1)
        } else {
            ""
        }
    }

    private fun getMimeType(ext: String): String {
        return when (ext) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            "mp4" -> "video/mp4"
            "mkv" -> "video/x-matroska"
            "opus" -> "audio/opus"
            "m4a" -> "audio/mp4"
            "mp3" -> "audio/mpeg"
            "pdf" -> "application/pdf"
            "apk" -> "application/vnd.android.package-archive"
            else -> "application/octet-stream"
        }
    }

    fun cleanup() {
        scope.cancel()
    }
}
