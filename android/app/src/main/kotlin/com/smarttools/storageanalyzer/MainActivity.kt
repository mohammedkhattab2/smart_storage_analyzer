package com.smarttools.storageanalyzer

import android.app.AppOpsManager
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import androidx.work.*
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    companion object {
        // Primary channel for storage operations
        private const val STORAGE_CHANNEL = "com.smarttools.imagecompressor/native"
        // Legacy channel for other operations
        private const val LEGACY_CHANNEL = "com.smartstorage/native"
        
        // File size threshold for large files (50MB)
        private const val LARGE_FILE_THRESHOLD = 50 * 1024 * 1024L
        
        // Age threshold for old files (30 days)
        private const val OLD_FILE_DAYS = 30
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
    }
    
    private lateinit var storageAnalyzer: StorageAnalyzer
    private lateinit var fileOperations: FileOperations

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize storage analyzer and file operations
        storageAnalyzer = StorageAnalyzer(this)
        fileOperations = FileOperations(this)
        
        // Storage channel handler (MVVM compliant)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getTotalStorage" -> {
                        result.success(getTotalStorage())
                    }
                    "getFreeStorage" -> {
                        result.success(getFreeStorage())
                    }
                    "getUsedStorage" -> {
                        result.success(getUsedStorage())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                result.error("STORAGE_ERROR", "Failed to get storage info: ${e.message}", null)
            }
        }

        // Legacy channel handler (for existing features)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LEGACY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    result.success(checkUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                "getStorageInfo" -> {
                    result.success(getStorageInfo())
                }
                "getAllFiles" -> {
                    result.success(getAllFiles())
                }
                "getFilesByCategory" -> {
                    val category = call.argument<String>("category") ?: "all"
                    result.success(getFilesByCategory(category))
                }
                "deleteFiles" -> {
                    val filePaths = call.argument<List<String>>("paths") ?: listOf()
                    result.success(deleteFiles(filePaths))
                }
                "analyzeStorage" -> {
                    val analysisResult = analyzeStorage()
                    result.success(analysisResult)
                }
                "openFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath != null) {
                        val success = fileOperations.openFile(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                    }
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath != null) {
                        val success = fileOperations.shareFile(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                    }
                }
                "shareFiles" -> {
                    val filePaths = call.argument<List<String>>("paths")
                    if (filePaths != null && filePaths.isNotEmpty()) {
                        val success = fileOperations.shareFiles(filePaths)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File paths are required", null)
                    }
                }
                "scheduleNotifications" -> {
                    scheduleNotifications()
                    result.success(true)
                }
                "cancelNotifications" -> {
                    cancelNotifications()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Get total storage space in bytes
     */
    private fun getTotalStorage(): Long {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            stat.blockSizeLong * stat.blockCountLong
        } catch (e: Exception) {
            0L
        }
    }

    /**
     * Get free storage space in bytes
     */
    private fun getFreeStorage(): Long {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            stat.blockSizeLong * stat.availableBlocksLong
        } catch (e: Exception) {
            0L
        }
    }

    /**
     * Get used storage space in bytes
     */
    private fun getUsedStorage(): Long {
        return try {
            val total = getTotalStorage()
            val free = getFreeStorage()
            if (total > 0 && free >= 0) total - free else 0L
        } catch (e: Exception) {
            0L
        }
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun getStorageInfo(): Map<String, Long> {
        val stat = StatFs(Environment.getExternalStorageDirectory().path)
        val blockSize = stat.blockSizeLong
        val totalBlocks = stat.blockCountLong
        val availableBlocks = stat.availableBlocksLong
        
        val totalSpace = totalBlocks * blockSize
        val availableSpace = availableBlocks * blockSize
        val usedSpace = totalSpace - availableSpace

        return mapOf(
            "totalSpace" to totalSpace,
            "availableSpace" to availableSpace,
            "usedSpace" to usedSpace
        )
    }

    private fun getAllFiles(): List<Map<String, Any>> {
        return getFilesByCategory("all")
    }
    
    /**
     * Main method to get files by category
     * Uses MediaStore for media files and file system scanning for others
     */
    private fun getFilesByCategory(category: String): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
        
        try {
            when (category) {
                "all" -> {
                    // Get all file types
                    getMediaFiles("images", fileMap)
                    getMediaFiles("videos", fileMap)
                    getMediaFiles("audio", fileMap)
                    getDocumentFiles(fileMap)
                    getAppFiles(fileMap)
                    getOtherFiles(fileMap)
                }
                "images" -> getMediaFiles("images", fileMap)
                "videos" -> getMediaFiles("videos", fileMap)
                "audio" -> getMediaFiles("audio", fileMap)
                "documents" -> getDocumentFiles(fileMap)
                "apps" -> getAppFiles(fileMap)
                "others" -> getOtherFiles(fileMap)
                "large" -> {
                    // Get all files and filter by size
                    getMediaFiles("all", fileMap)
                    getDocumentFiles(fileMap)
                    getAppFiles(fileMap)
                    getOtherFiles(fileMap)
                    fileMap.values.filter { (it["size"] as Long) > LARGE_FILE_THRESHOLD }
                        .forEach { filesList.add(it) }
                    fileMap.clear()
                }
                "old" -> {
                    // Get all files and filter by age
                    val threshold = System.currentTimeMillis() - OLD_FILE_THRESHOLD
                    getMediaFiles("all", fileMap)
                    getDocumentFiles(fileMap)
                    getAppFiles(fileMap)
                    getOtherFiles(fileMap)
                    fileMap.values.filter { (it["lastModified"] as Long) < threshold }
                        .forEach { filesList.add(it) }
                    fileMap.clear()
                }
                "duplicates" -> {
                    // Basic duplicate detection by name and size
                    getDuplicateFiles(fileMap)
                }
            }
            
            // Convert map to list if not already done
            if (filesList.isEmpty() && fileMap.isNotEmpty()) {
                filesList.addAll(fileMap.values)
            }
            
            // Sort by size (largest first)
            filesList.sortByDescending { (it["size"] as? Long) ?: 0 }
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return filesList
    }
    
    /**
     * Get media files using MediaStore API
     */
    private fun getMediaFiles(type: String, fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        val contentResolver: ContentResolver = contentResolver
        
        val mediaUris = when (type) {
            "images" -> listOf(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            "videos" -> listOf(MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
            "audio" -> listOf(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI)
            else -> listOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            )
        }
        
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.MIME_TYPE
        )
        
        for (uri in mediaUris) {
            var cursor: Cursor? = null
            try {
                cursor = contentResolver.query(
                    uri,
                    projection,
                    null,
                    null,
                    "${MediaStore.MediaColumns.SIZE} DESC"
                )
                
                cursor?.use {
                    val idColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val nameColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                    val pathColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                    val sizeColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                    val dateColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                    val mimeColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
                    
                    while (it.moveToNext()) {
                        val id = it.getLong(idColumn)
                        val name = it.getString(nameColumn) ?: "Unknown"
                        val path = it.getString(pathColumn) ?: ""
                        val size = it.getLong(sizeColumn)
                        val dateModified = it.getLong(dateColumn) * 1000 // Convert to milliseconds
                        val mimeType = it.getString(mimeColumn) ?: "application/octet-stream"
                        
                        // Skip if file doesn't exist or size is 0
                        if (path.isEmpty() || size <= 0) continue
                        
                        val fileInfo = mapOf(
                            "id" to id.toString(),
                            "name" to name,
                            "path" to path,
                            "size" to size,
                            "lastModified" to dateModified,
                            "extension" to getExtensionFromPath(path),
                            "mimeType" to mimeType
                        )
                        
                        fileMap[path] = fileInfo
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Get document files by scanning specific directories
     */
    private fun getDocumentFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        val documentExtensions = setOf(
            ".pdf", ".doc", ".docx", ".txt", ".odt", ".xls", 
            ".xlsx", ".ppt", ".pptx", ".csv", ".rtf"
        )
        
        val dirsToScan = getDirectoriesToScan()
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForFiles(dir, fileMap, documentExtensions, 0)
            }
        }
    }
    
    /**
     * Get APK files
     */
    private fun getAppFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        val appExtensions = setOf(".apk", ".xapk", ".aab")
        val dirsToScan = getDirectoriesToScan()
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForFiles(dir, fileMap, appExtensions, 0)
            }
        }
    }
    
    /**
     * Get other files (non-categorized)
     */
    private fun getOtherFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        // Define extensions for known categories to exclude
        val knownExtensions = setOf(
            // Images
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico", ".tiff", ".heic",
            // Videos
            ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpg", ".3gp",
            // Audio
            ".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".opus", ".amr",
            // Documents
            ".pdf", ".doc", ".docx", ".txt", ".odt", ".xls", ".xlsx", ".ppt", ".pptx", ".csv", ".rtf",
            // Apps
            ".apk", ".xapk", ".aab"
        )
        
        val dirsToScan = listOf(
            File(Environment.getExternalStorageDirectory(), "Download"),
            File(Environment.getExternalStorageDirectory(), "Downloads")
        )
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForOtherFiles(dir, fileMap, knownExtensions, 0)
            }
        }
    }
    
    /**
     * Get duplicate files (basic implementation)
     */
    private fun getDuplicateFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        val allFiles = ConcurrentHashMap<String, Map<String, Any>>()
        
        // Collect all files
        getMediaFiles("all", allFiles)
        getDocumentFiles(allFiles)
        getAppFiles(allFiles)
        getOtherFiles(allFiles)
        
        // Group by name and size
        val groupedFiles = allFiles.values.groupBy { 
            "${it["name"]}_${it["size"]}"
        }
        
        // Find duplicates
        for ((key, files) in groupedFiles) {
            if (files.size > 1) {
                // Add all duplicates except the first one
                files.drop(1).forEach { file ->
                    fileMap[file["path"] as String] = file
                }
            }
        }
    }
    
    /**
     * Scan directory for specific file types
     */
    private fun scanDirectoryForFiles(
        directory: File,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        extensions: Set<String>,
        depth: Int
    ) {
        if (depth > 3) return
        
        val skipDirs = listOf(".", "..", ".android", ".thumbnails", "Android/data", "Android/obb")
        if (skipDirs.any { directory.absolutePath.contains(it) }) return
        
        try {
            val files = directory.listFiles() ?: return
            
            for (file in files) {
                if (file.isFile && !file.isHidden) {
                    val extension = getExtensionFromPath(file.name)
                    if (extensions.contains(extension.lowercase())) {
                        // Skip if already in map
                        if (fileMap.containsKey(file.absolutePath)) continue
                        
                        val fileInfo = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "path" to file.absolutePath,
                            "name" to file.name,
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to extension,
                            "mimeType" to getMimeTypeFromExtension(extension)
                        )
                        fileMap[file.absolutePath] = fileInfo
                    }
                } else if (file.isDirectory && !file.isHidden && file.canRead()) {
                    scanDirectoryForFiles(file, fileMap, extensions, depth + 1)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Scan directory for other files (non-categorized)
     */
    private fun scanDirectoryForOtherFiles(
        directory: File,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        knownExtensions: Set<String>,
        depth: Int
    ) {
        if (depth > 3) return
        
        val skipDirs = listOf(".", "..", ".android", ".thumbnails", "Android/data", "Android/obb")
        if (skipDirs.any { directory.absolutePath.contains(it) }) return
        
        try {
            val files = directory.listFiles() ?: return
            
            for (file in files) {
                if (file.isFile && !file.isHidden) {
                    val extension = getExtensionFromPath(file.name)
                    if (!knownExtensions.contains(extension.lowercase())) {
                        // Skip if already in map
                        if (fileMap.containsKey(file.absolutePath)) continue
                        
                        val fileInfo = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "path" to file.absolutePath,
                            "name" to file.name,
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to extension,
                            "mimeType" to "application/octet-stream"
                        )
                        fileMap[file.absolutePath] = fileInfo
                    }
                } else if (file.isDirectory && !file.isHidden && file.canRead()) {
                    scanDirectoryForOtherFiles(file, fileMap, knownExtensions, depth + 1)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Get directories to scan
     */
    private fun getDirectoriesToScan(): List<File> {
        val dirs = mutableListOf<File>()
        
        val externalDir = Environment.getExternalStorageDirectory()
        
        // Common user directories
        dirs.add(File(externalDir, "Download"))
        dirs.add(File(externalDir, "Downloads"))
        dirs.add(File(externalDir, "DCIM"))
        dirs.add(File(externalDir, "Pictures"))
        dirs.add(File(externalDir, "Movies"))
        dirs.add(File(externalDir, "Music"))
        dirs.add(File(externalDir, "Documents"))
        dirs.add(File(externalDir, "WhatsApp"))
        dirs.add(File(externalDir, "WhatsApp/Media"))
        dirs.add(File(externalDir, "Telegram"))
        dirs.add(File(externalDir, "Telegram/Telegram Documents"))
        dirs.add(File(externalDir, "Android/media"))
        
        return dirs.filter { it.exists() }
    }
    
    /**
     * Get file extension from path
     */
    private fun getExtensionFromPath(path: String): String {
        val lastDot = path.lastIndexOf('.')
        return if (lastDot > 0) path.substring(lastDot) else ""
    }
    
    /**
     * Get MIME type from extension
     */
    private fun getMimeTypeFromExtension(extension: String): String {
        return when (extension.lowercase()) {
            ".jpg", ".jpeg" -> "image/jpeg"
            ".png" -> "image/png"
            ".gif" -> "image/gif"
            ".bmp" -> "image/bmp"
            ".webp" -> "image/webp"
            ".mp4" -> "video/mp4"
            ".avi" -> "video/x-msvideo"
            ".mkv" -> "video/x-matroska"
            ".mov" -> "video/quicktime"
            ".mp3" -> "audio/mpeg"
            ".wav" -> "audio/wav"
            ".flac" -> "audio/flac"
            ".aac" -> "audio/aac"
            ".pdf" -> "application/pdf"
            ".doc" -> "application/msword"
            ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ".txt" -> "text/plain"
            ".apk" -> "application/vnd.android.package-archive"
            ".zip" -> "application/zip"
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Delete multiple files
     */
    private fun deleteFiles(filePaths: List<String>): Int {
        var deletedCount = 0
        
        for (path in filePaths) {
            try {
                // Try to delete using MediaStore first for media files
                val deleted = deleteMediaFile(path) || deleteRegularFile(path)
                if (deleted) {
                    deletedCount++
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        return deletedCount
    }
    
    /**
     * Delete media file using MediaStore
     */
    private fun deleteMediaFile(path: String): Boolean {
        try {
            val uri = MediaStore.Files.getContentUri("external")
            val selection = "${MediaStore.MediaColumns.DATA} = ?"
            val selectionArgs = arrayOf(path)
            
            val deleted = contentResolver.delete(uri, selection, selectionArgs)
            return deleted > 0
        } catch (e: Exception) {
            return false
        }
    }
    
    /**
     * Delete regular file using File API
     */
    private fun deleteRegularFile(path: String): Boolean {
        return try {
            val file = File(path)
            if (file.exists() && file.canWrite()) {
                file.delete()
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Perform deep storage analysis
     */
    private fun analyzeStorage(): Map<String, Any> {
        try {
            val analysis = storageAnalyzer.analyzeStorage()
            
            return mapOf(
                "totalFilesScanned" to analysis.totalFilesScanned,
                "totalSpaceUsed" to analysis.totalSpaceUsed,
                "totalSpaceAvailable" to analysis.totalSpaceAvailable,
                "cacheFiles" to analysis.cacheFiles,
                "temporaryFiles" to analysis.temporaryFiles,
                "largeOldFiles" to analysis.largeOldFiles,
                "duplicateFiles" to analysis.duplicateFiles,
                "thumbnails" to analysis.thumbnails,
                "totalCleanupPotential" to analysis.totalCleanupPotential
            )
        } catch (e: Exception) {
            e.printStackTrace()
            // Return empty results on error
            return mapOf(
                "totalFilesScanned" to 0,
                "totalSpaceUsed" to 0L,
                "totalSpaceAvailable" to 0L,
                "cacheFiles" to emptyList<Map<String, Any>>(),
                "temporaryFiles" to emptyList<Map<String, Any>>(),
                "largeOldFiles" to emptyList<Map<String, Any>>(),
                "duplicateFiles" to emptyList<Map<String, Any>>(),
                "thumbnails" to emptyList<Map<String, Any>>(),
                "totalCleanupPotential" to 0L
            )
        }
    }

    /**
     * Schedule periodic notifications using WorkManager
     */
    private fun scheduleNotifications() {
        try {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                .setRequiresBatteryNotLow(true)
                .build()

            val notificationWork = PeriodicWorkRequestBuilder<NotificationWorker>(
                2, TimeUnit.HOURS,  // Repeat every 2 hours
                15, TimeUnit.MINUTES  // Flex interval of 15 minutes
            )
                .setConstraints(constraints)
                .addTag("storage_notification")
                .build()

            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "storage_notification_work",
                ExistingPeriodicWorkPolicy.REPLACE,
                notificationWork
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Cancel scheduled notifications
     */
    private fun cancelNotifications() {
        try {
            WorkManager.getInstance(this).cancelUniqueWork("storage_notification_work")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}