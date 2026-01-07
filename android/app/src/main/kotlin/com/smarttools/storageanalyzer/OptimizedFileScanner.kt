package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Optimized file scanner that runs operations in background threads
 * Prevents ANR and improves performance
 */
class OptimizedFileScanner(private val context: Context) {
    
    companion object {
        private const val BATCH_SIZE = 100
        private const val MAX_DEPTH = 5
        private const val LARGE_FILE_THRESHOLD = 50 * 1024 * 1024L // 50MB
        private const val OLD_FILE_DAYS = 30
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
        
        // Document extensions - comprehensive list
        private val DOCUMENT_EXTENSIONS = setOf(
            ".pdf", ".doc", ".docx", ".txt", ".odt", ".rtf", ".tex", ".wpd", ".md",
            ".xls", ".xlsx", ".ods", ".csv", ".tsv",
            ".ppt", ".pptx", ".odp", ".pps", ".ppsx",
            ".epub", ".mobi", ".azw", ".azw3", ".fb2", ".lit",
            ".xml", ".json", ".log", ".ini", ".cfg", ".conf", ".properties",
            ".html", ".htm", ".xhtml", ".mhtml", ".chm"
        )
        
        // App extensions
        private val APP_EXTENSIONS = setOf(".apk", ".xapk", ".aab", ".apks")
        
        // Media extensions for exclusion from "Others"
        private val MEDIA_EXTENSIONS = setOf(
            // Images
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico", ".tiff", ".heic",
            ".heif", ".raw", ".cr2", ".nef", ".orf", ".sr2", ".psd", ".ai", ".eps",
            // Videos
            ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpg", ".3gp",
            ".mpeg", ".mpe", ".mpv", ".m2v", ".svi", ".3g2", ".mxf", ".roq", ".nsv", ".f4v",
            // Audio
            ".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".opus", ".amr"
        )
    }
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val progressChannel = Channel<ScanProgress>(Channel.BUFFERED)
    
    data class ScanProgress(
        val category: String,
        val filesScanned: Int,
        val totalFiles: Int,
        val message: String
    )
    
    data class FileData(
        val id: String,
        val path: String,
        val name: String,
        val size: Long,
        val lastModified: Long,
        val extension: String,
        val mimeType: String
    )
    
    /**
     * Scan files by category with background processing
     */
    suspend fun scanFilesByCategory(category: String): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        when (category) {
            "all" -> scanAllFiles()
            "images" -> scanMediaFiles("images")
            "videos" -> scanMediaFiles("videos")
            "audio" -> scanMediaFiles("audio")
            "documents" -> scanDocuments()
            "apps" -> scanApps()
            "others" -> scanOthers()
            "large" -> scanLargeFiles()
            "old" -> scanOldFiles()
            "duplicates" -> scanDuplicates()
            else -> emptyList()
        }
    }
    
    /**
     * Scan all files using parallel processing
     */
    private suspend fun scanAllFiles(): List<Map<String, Any>> = coroutineScope {
        val allFiles = ConcurrentHashMap<String, Map<String, Any>>()
        
        // Launch parallel scans for each category
        val jobs = listOf(
            async { scanMediaFilesInternal("images", allFiles) },
            async { scanMediaFilesInternal("videos", allFiles) },
            async { scanMediaFilesInternal("audio", allFiles) },
            async { scanDocumentsInternal(allFiles) },
            async { scanAppsInternal(allFiles) },
            async { scanOthersInternal(allFiles) }
        )
        
        // Wait for all scans to complete
        jobs.awaitAll()
        
        // Convert to list and sort by size
        allFiles.values.sortedByDescending { (it["size"] as Long) }
    }
    
    /**
     * Scan media files using MediaStore with batching
     */
    private suspend fun scanMediaFiles(type: String): List<Map<String, Any>> {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        scanMediaFilesInternal(type, files)
        return files.values.sortedByDescending { (it["size"] as Long) }
    }
    
    private suspend fun scanMediaFilesInternal(
        type: String,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        val contentResolver = context.contentResolver
        val uri = when (type) {
            "images" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            "videos" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> return@withContext
        }
        
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.MIME_TYPE
        )
        
        contentResolver.query(
            uri,
            projection,
            null,
            null,
            "${MediaStore.MediaColumns.SIZE} DESC"
        )?.use { cursor ->
            processCursor(cursor, fileMap)
        }
    }
    
    /**
     * Process cursor in batches to avoid memory issues
     */
    private suspend fun processCursor(
        cursor: Cursor,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
        val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
        val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
        val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
        val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
        val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
        
        val batch = mutableListOf<Map<String, Any>>()
        
        while (cursor.moveToNext()) {
            val id = cursor.getLong(idColumn)
            val name = cursor.getString(nameColumn) ?: "Unknown"
            val path = cursor.getString(pathColumn) ?: continue
            val size = cursor.getLong(sizeColumn)
            val dateModified = cursor.getLong(dateColumn) * 1000
            val mimeType = cursor.getString(mimeColumn) ?: "application/octet-stream"
            
            if (size <= 0) continue
            
            val fileInfo = mapOf(
                "id" to id.toString(),
                "name" to name,
                "path" to path,
                "size" to size,
                "lastModified" to dateModified,
                "extension" to getExtension(path),
                "mimeType" to mimeType
            )
            
            batch.add(fileInfo)
            
            // Process batch
            if (batch.size >= BATCH_SIZE) {
                batch.forEach { fileMap[it["path"] as String] = it }
                batch.clear()
                yield() // Allow other coroutines to run
            }
        }
        
        // Process remaining items
        batch.forEach { fileMap[it["path"] as String] = it }
    }
    
    /**
     * Scan documents with optimized directory traversal
     */
    private suspend fun scanDocuments(): List<Map<String, Any>> {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        scanDocumentsInternal(files)
        return files.values.sortedByDescending { (it["size"] as Long) }
    }
    
    private suspend fun scanDocumentsInternal(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        // Priority directories for documents
        val priorityDirs = listOf(
            "Download", "Downloads", "Documents", "Books", "PDFs", 
            "Office", "Work", "School", "Study", "Projects"
        )
        
        val rootDir = Environment.getExternalStorageDirectory()
        
        // Scan priority directories deeply
        priorityDirs.forEach { dirName ->
            val dir = File(rootDir, dirName)
            if (dir.exists() && dir.canRead()) {
                scanDirectoryAsync(dir, DOCUMENT_EXTENSIONS, fileMap, maxDepth = 5)
            }
        }
        
        // Scan other directories with limited depth
        rootDir.listFiles()?.forEach { dir ->
            if (dir.isDirectory && !dir.isHidden && dir.canRead() &&
                !priorityDirs.contains(dir.name) && !dir.name.startsWith(".")) {
                scanDirectoryAsync(dir, DOCUMENT_EXTENSIONS, fileMap, maxDepth = 2)
            }
        }
    }
    
    /**
     * Scan apps using PackageManager instead of filesystem
     */
    private suspend fun scanApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        
        return withContext(Dispatchers.IO) {
            // Get installed apps from PackageManager
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
                    // Skip system apps unless they're updatable
                    if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
                        (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0) {
                        
                        val appName = packageManager.getApplicationLabel(appInfo).toString()
                        val apkPath = appInfo.sourceDir
                        val apkFile = File(apkPath)
                        
                        if (apkFile.exists()) {
                            apps.add(mapOf(
                                "id" to appInfo.packageName,
                                "name" to "$appName.apk",
                                "path" to apkPath,
                                "size" to apkFile.length(),
                                "lastModified" to apkFile.lastModified(),
                                "extension" to ".apk",
                                "mimeType" to "application/vnd.android.package-archive"
                            ))
                        }
                    }
                } catch (e: Exception) {
                    // Skip problematic apps
                }
            }
            
            // Also scan for APK files in common directories
            val apkDirs = listOf("Download", "Downloads", "Apk", "APKs", "Apps")
            val rootDir = Environment.getExternalStorageDirectory()
            
            apkDirs.forEach { dirName ->
                val dir = File(rootDir, dirName)
                if (dir.exists() && dir.canRead()) {
                    scanDirectoryForApks(dir, apps)
                }
            }
            
            apps.sortedByDescending { (it["size"] as Long) }
        }
    }
    
    private suspend fun scanDirectoryForApks(
        dir: File,
        apps: MutableList<Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        dir.walkTopDown()
            .maxDepth(3)
            .filter { it.isFile && APP_EXTENSIONS.contains(getExtension(it.name)) }
            .forEach { file ->
                apps.add(mapOf(
                    "id" to file.absolutePath.hashCode().toString(),
                    "name" to file.name,
                    "path" to file.absolutePath,
                    "size" to file.length(),
                    "lastModified" to file.lastModified(),
                    "extension" to getExtension(file.name),
                    "mimeType" to "application/vnd.android.package-archive"
                ))
            }
    }
    
    private suspend fun scanAppsInternal(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) {
        scanApps().forEach { app ->
            fileMap[app["path"] as String] = app
        }
    }
    
    /**
     * Scan other files (non-categorized)
     */
    private suspend fun scanOthers(): List<Map<String, Any>> {
        val files = ConcurrentHashMap<String, Map<String, Any>>()
        scanOthersInternal(files)
        return files.values.sortedByDescending { (it["size"] as Long) }
    }
    
    private suspend fun scanOthersInternal(
        fileMap: ConcurrentHashMap<String, Map<String, Any>>
    ) = withContext(Dispatchers.IO) {
        val knownExtensions = MEDIA_EXTENSIONS + DOCUMENT_EXTENSIONS + APP_EXTENSIONS
        val rootDir = Environment.getExternalStorageDirectory()
        
        // Scan with limited depth to avoid performance issues
        scanDirectoryAsync(rootDir, emptySet(), fileMap, maxDepth = 3) { file ->
            val ext = getExtension(file.name)
            !knownExtensions.contains(ext.lowercase()) && file.length() > 1024
        }
    }
    
    /**
     * Async directory scanning with cancellation support
     */
    private suspend fun scanDirectoryAsync(
        directory: File,
        extensions: Set<String>,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        maxDepth: Int,
        filter: (File) -> Boolean = { true }
    ) = withContext(Dispatchers.IO) {
        val filesToProcess = Channel<File>(Channel.UNLIMITED)
        val processedCount = AtomicInteger(0)
        
        // Producer coroutine - walks directory tree
        launch {
            directory.walkTopDown()
                .maxDepth(maxDepth)
                .onEnter { !it.isHidden && it.canRead() && !it.absolutePath.contains("/.") }
                .filter { it.isFile && !it.isHidden }
                .forEach { file ->
                    filesToProcess.send(file)
                }
            filesToProcess.close()
        }
        
        // Consumer coroutines - process files in parallel
        val workers = List(4) { // 4 parallel workers
            launch {
                for (file in filesToProcess) {
                    try {
                        val ext = getExtension(file.name)
                        if ((extensions.isEmpty() || extensions.contains(ext.lowercase())) &&
                            filter(file)) {
                            
                            val fileInfo = mapOf(
                                "id" to file.absolutePath.hashCode().toString(),
                                "path" to file.absolutePath,
                                "name" to file.name,
                                "size" to file.length(),
                                "lastModified" to file.lastModified(),
                                "extension" to ext,
                                "mimeType" to getMimeType(ext)
                            )
                            fileMap[file.absolutePath] = fileInfo
                            
                            // Report progress
                            val count = processedCount.incrementAndGet()
                            if (count % 100 == 0) {
                                yield() // Allow other coroutines to run
                            }
                        }
                    } catch (e: Exception) {
                        // Skip files that can't be accessed
                    }
                }
            }
        }
        
        // Wait for all workers to complete
        workers.joinAll()
    }
    
    /**
     * Scan large files efficiently
     */
    private suspend fun scanLargeFiles(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val allFiles = scanAllFiles()
        allFiles.filter { (it["size"] as Long) > LARGE_FILE_THRESHOLD }
    }
    
    /**
     * Scan old files efficiently
     */
    private suspend fun scanOldFiles(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val threshold = System.currentTimeMillis() - OLD_FILE_THRESHOLD
        val allFiles = scanAllFiles()
        allFiles.filter { (it["lastModified"] as Long) < threshold }
    }
    
    /**
     * Scan duplicate files using size and name matching
     */
    private suspend fun scanDuplicates(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val allFiles = scanAllFiles()
        val duplicates = mutableListOf<Map<String, Any>>()
        
        // Group by name and size
        val grouped = allFiles.groupBy { "${it["name"]}_${it["size"]}" }
        
        // Find duplicates
        grouped.forEach { (_, files) ->
            if (files.size > 1) {
                // Add all except the first as duplicates
                duplicates.addAll(files.drop(1))
            }
        }
        
        duplicates.sortedByDescending { (it["size"] as Long) }
    }
    
    private fun getExtension(path: String): String {
        val lastDot = path.lastIndexOf('.')
        return if (lastDot > 0) path.substring(lastDot) else ""
    }
    
    private fun getMimeType(extension: String): String {
        return when (extension.lowercase()) {
            ".pdf" -> "application/pdf"
            ".doc" -> "application/msword"
            ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ".txt" -> "text/plain"
            ".zip" -> "application/zip"
            ".rar" -> "application/x-rar-compressed"
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
        progressChannel.close()
    }
}