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
import kotlinx.coroutines.*

class MainActivity: FlutterActivity() {
    companion object {
        // Unified channel for all native operations
        private const val MAIN_CHANNEL = "com.smarttools.storageanalyzer/native"
        
        // File size threshold for large files (50MB)
        private const val LARGE_FILE_THRESHOLD = 50 * 1024 * 1024L
        
        // Age threshold for old files (30 days)
        private const val OLD_FILE_DAYS = 30
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
    }
    
    private lateinit var storageAnalyzer: StorageAnalyzer
    private lateinit var fileOperations: FileOperations
    private lateinit var optimizedFileScanner: OptimizedFileScanner
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize storage analyzer and file operations
        storageAnalyzer = StorageAnalyzer(this)
        fileOperations = FileOperations(this)
        optimizedFileScanner = OptimizedFileScanner(this)
        
        // Unified channel handler for all native operations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    // Storage operations
                    "getTotalStorage" -> {
                        result.success(getTotalStorage())
                    }
                    "getFreeStorage" -> {
                        result.success(getFreeStorage())
                    }
                    "getUsedStorage" -> {
                        result.success(getUsedStorage())
                    }
                    // Permission operations
                    "checkUsagePermission" -> {
                        result.success(checkUsageStatsPermission())
                    }
                    "requestUsagePermission" -> {
                        requestUsageStatsPermission()
                        result.success(true)
                    }
                    // Storage info operations
                    "getStorageInfo" -> {
                        result.success(getStorageInfo())
                    }
                    // File operations
                    "getAllFiles" -> {
                        result.success(getAllFiles())
                    }
                    "getFilesByCategory" -> {
                        val category = call.argument<String>("category") ?: "all"
                        // Use optimized scanner with coroutines
                        mainScope.launch {
                            try {
                                val files = optimizedFileScanner.scanFilesByCategory(category)
                                result.success(files)
                            } catch (e: Exception) {
                                result.error("SCAN_ERROR", "Failed to scan files: ${e.message}", null)
                            }
                        }
                    }
                    "deleteFiles" -> {
                        val filePaths = call.argument<List<String>>("paths") ?: listOf()
                        result.success(deleteFiles(filePaths))
                    }
                    // Analysis operations
                    "analyzeStorage" -> {
                        // Use coroutine for heavy analysis operation
                        mainScope.launch {
                            try {
                                val analysisResult = withContext(Dispatchers.IO) {
                                    val analysis = storageAnalyzer.analyzeStorage()
                                    mapOf(
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
                                }
                                result.success(analysisResult)
                            } catch (e: Exception) {
                                result.error("ANALYSIS_ERROR", "Storage analysis failed: ${e.message}", null)
                            }
                        }
                    }
                    // Get category sizes for dashboard
                    "getCategorySizes" -> {
                        mainScope.launch {
                            try {
                                val categorySizes = withContext(Dispatchers.IO) {
                                    getCategorySizes()
                                }
                                result.success(categorySizes)
                            } catch (e: Exception) {
                                result.error("CATEGORY_ERROR", "Failed to get category sizes: ${e.message}", null)
                            }
                        }
                    }
                    // File operations through native
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
                    // Notification operations
                    "scheduleNotifications" -> {
                        scheduleNotifications()
                        result.success(true)
                    }
                    "cancelNotifications" -> {
                        cancelNotifications()
                        result.success(true)
                    }
                    "areNotificationsEnabled" -> {
                        result.success(areNotificationsEnabled())
                    }
                    "requestNotificationPermission" -> {
                        result.success(requestNotificationPermission())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                result.error("PLATFORM_ERROR", "Error executing method ${call.method}: ${e.message}", null)
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
        // This method is now handled by the optimized scanner
        // Called through coroutines in the method channel handler
        return emptyList()
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
            // Text documents
            ".pdf", ".doc", ".docx", ".txt", ".odt", ".rtf", ".tex", ".wpd", ".md",
            // Spreadsheets
            ".xls", ".xlsx", ".ods", ".csv", ".tsv",
            // Presentations
            ".ppt", ".pptx", ".odp", ".pps", ".ppsx",
            // E-books
            ".epub", ".mobi", ".azw", ".azw3", ".fb2", ".lit",
            // Other documents
            ".xml", ".json", ".log", ".ini", ".cfg", ".conf", ".properties",
            ".html", ".htm", ".xhtml", ".mhtml", ".chm"
        )
        
        // Scan root storage and all subdirectories
        val rootDir = Environment.getExternalStorageDirectory()
        scanRootForDocuments(rootDir, fileMap, documentExtensions)
        
        // Also scan specific directories
        val dirsToScan = getExtendedDirectoriesToScan()
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForFiles(dir, fileMap, documentExtensions, 0, maxDepth = 5)
            }
        }
    }
    
    /**
     * Get APK files
     */
    private fun getAppFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        val appExtensions = setOf(".apk", ".xapk", ".aab", ".apks")
        
        // Scan root storage comprehensively
        val rootDir = Environment.getExternalStorageDirectory()
        scanRootForApps(rootDir, fileMap, appExtensions)
        
        // Also scan specific app-related directories
        val dirsToScan = getExtendedDirectoriesToScan()
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForFiles(dir, fileMap, appExtensions, 0, maxDepth = 5)
            }
        }
        
        // Additional APK locations
        val additionalDirs = listOf(
            File(rootDir, "Apk"),
            File(rootDir, "APKs"),
            File(rootDir, "Apps"),
            File(rootDir, "Applications"),
            File(rootDir, "backup"),
            File(rootDir, "Backups"),
            File(rootDir, "APKPure"),
            File(rootDir, "APKMirror")
        )
        
        for (dir in additionalDirs) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForFiles(dir, fileMap, appExtensions, 0, maxDepth = 3)
            }
        }
    }
    
    /**
     * Get other files (non-categorized)
     */
    private fun getOtherFiles(fileMap: ConcurrentHashMap<String, Map<String, Any>>) {
        // Define extensions for known categories to exclude (comprehensive list)
        val knownExtensions = setOf(
            // Images
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico", ".tiff", ".heic",
            ".heif", ".raw", ".cr2", ".nef", ".orf", ".sr2", ".psd", ".ai", ".eps",
            // Videos
            ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpg", ".3gp",
            ".mpeg", ".mpe", ".mpv", ".m2v", ".svi", ".3g2", ".mxf", ".roq", ".nsv", ".f4v",
            ".f4p", ".f4a", ".f4b", ".mod", ".vob", ".ogv", ".drc", ".mng", ".qt", ".yuv",
            ".rm", ".rmvb", ".asf", ".amv", ".m2ts", ".mts", ".m2t", ".ts", ".rec",
            // Audio
            ".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".opus", ".amr",
            ".ape", ".au", ".aiff", ".dss", ".dvf", ".m4b", ".m4p", ".mmf", ".mpc",
            ".msv", ".nmf", ".oga", ".mogg", ".ra", ".rf64", ".sln", ".tta", ".voc",
            ".vox", ".wv", ".8svx", ".cda",
            // Documents (expanded)
            ".pdf", ".doc", ".docx", ".txt", ".odt", ".xls", ".xlsx", ".ppt", ".pptx",
            ".csv", ".rtf", ".tex", ".wpd", ".md", ".ods", ".odp", ".pps", ".ppsx",
            ".epub", ".mobi", ".azw", ".azw3", ".fb2", ".lit", ".xml", ".json",
            ".log", ".ini", ".cfg", ".conf", ".properties", ".html", ".htm", ".xhtml",
            ".mhtml", ".chm", ".tsv",
            // Apps
            ".apk", ".xapk", ".aab", ".apks"
        )
        
        // Scan root directory comprehensively for other files
        val rootDir = Environment.getExternalStorageDirectory()
        
        // Scan root level
        rootDir.listFiles()?.forEach { file ->
            if (file.isFile && !file.isHidden) {
                val extension = getExtensionFromPath(file.name)
                if (!knownExtensions.contains(extension.lowercase()) && file.length() > 1024) {
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
            }
        }
        
        // Extended directories to scan for other files
        val dirsToScan = getExtendedDirectoriesToScan()
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForOtherFiles(dir, fileMap, knownExtensions, 0, maxDepth = 4)
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
     * Scan directory for specific file types with configurable max depth
     */
    private fun scanDirectoryForFiles(
        directory: File,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        extensions: Set<String>,
        depth: Int,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth) return
        
        // More selective skip list - allow Android/media for documents/apps
        val skipDirs = listOf(".", "..", ".thumbnails", "Android/data", "Android/obb", ".trash", ".Trash")
        if (skipDirs.any { directory.absolutePath.contains(it) }) return
        
        try {
            val files = directory.listFiles() ?: return
            
            for (file in files) {
                if (file.isFile && !file.isHidden) {
                    val extension = getExtensionFromPath(file.name)
                    if (extensions.contains(extension.lowercase())) {
                        // Skip if already in map
                        if (fileMap.containsKey(file.absolutePath)) continue
                        
                        // Skip very small files (< 1KB) as they're likely system files
                        if (file.length() < 1024) continue
                        
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
                    scanDirectoryForFiles(file, fileMap, extensions, depth + 1, maxDepth)
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
        depth: Int,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth) return
        
        val skipDirs = listOf(".", "..", ".android", ".thumbnails", "Android/data", "Android/obb", ".trash", ".Trash")
        if (skipDirs.any { directory.absolutePath.contains(it) }) return
        
        try {
            val files = directory.listFiles() ?: return
            
            for (file in files) {
                if (file.isFile && !file.isHidden) {
                    val extension = getExtensionFromPath(file.name)
                    if (!knownExtensions.contains(extension.lowercase())) {
                        // Skip if already in map
                        if (fileMap.containsKey(file.absolutePath)) continue
                        
                        // Skip very small files (< 1KB)
                        if (file.length() < 1024) continue
                        
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
                    scanDirectoryForOtherFiles(file, fileMap, knownExtensions, depth + 1, maxDepth)
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
     * Get extended directories list for comprehensive scanning
     */
    private fun getExtendedDirectoriesToScan(): List<File> {
        val dirs = mutableListOf<File>()
        
        val externalDir = Environment.getExternalStorageDirectory()
        
        // All common directories
        dirs.addAll(getDirectoriesToScan())
        
        // Additional directories for documents and apps
        dirs.add(File(externalDir, "Books"))
        dirs.add(File(externalDir, "eBooks"))
        dirs.add(File(externalDir, "PDFs"))
        dirs.add(File(externalDir, "Office"))
        dirs.add(File(externalDir, "Work"))
        dirs.add(File(externalDir, "School"))
        dirs.add(File(externalDir, "Study"))
        dirs.add(File(externalDir, "Projects"))
        dirs.add(File(externalDir, "Scans"))
        dirs.add(File(externalDir, "Scanner"))
        dirs.add(File(externalDir, "CamScanner"))
        dirs.add(File(externalDir, "Adobe Scan"))
        dirs.add(File(externalDir, "Backups"))
        dirs.add(File(externalDir, "backup"))
        dirs.add(File(externalDir, "Bluetooth"))
        dirs.add(File(externalDir, "ShareIt"))
        dirs.add(File(externalDir, "Xender"))
        dirs.add(File(externalDir, "SHAREit"))
        dirs.add(File(externalDir, "Nearby Share"))
        dirs.add(File(externalDir, "Received Files"))
        
        // App-specific document folders
        dirs.add(File(externalDir, "WPS Office"))
        dirs.add(File(externalDir, "Microsoft"))
        dirs.add(File(externalDir, "Google Drive"))
        dirs.add(File(externalDir, "OneDrive"))
        dirs.add(File(externalDir, "Dropbox"))
        dirs.add(File(externalDir, "Kindle"))
        dirs.add(File(externalDir, "Adobe"))
        
        // Messaging app media folders
        dirs.add(File(externalDir, "Viber"))
        dirs.add(File(externalDir, "Signal"))
        dirs.add(File(externalDir, "WeChat"))
        dirs.add(File(externalDir, "LINE"))
        dirs.add(File(externalDir, "Discord"))
        
        return dirs.filter { it.exists() && it.canRead() }
    }
    
    /**
     * Scan root directory for documents with smart filtering
     */
    private fun scanRootForDocuments(
        rootDir: File,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        extensions: Set<String>
    ) {
        // Scan root level files
        rootDir.listFiles()?.forEach { file ->
            if (file.isFile && !file.isHidden) {
                val extension = getExtensionFromPath(file.name)
                if (extensions.contains(extension.lowercase()) && file.length() > 1024) {
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
            }
        }
        
        // Scan subdirectories with smart filtering
        val dirsToDeepScan = listOf("Documents", "Download", "Downloads", "Books", "PDFs", "Office")
        rootDir.listFiles()?.forEach { dir ->
            if (dir.isDirectory && !dir.isHidden && dir.canRead()) {
                val dirName = dir.name
                // Deep scan for known document directories
                if (dirsToDeepScan.contains(dirName)) {
                    scanDirectoryForFiles(dir, fileMap, extensions, 0, maxDepth = 5)
                } else if (!dirName.startsWith(".") && !dirName.equals("Android", ignoreCase = true)) {
                    // Shallow scan for other directories
                    scanDirectoryForFiles(dir, fileMap, extensions, 0, maxDepth = 2)
                }
            }
        }
    }
    
    /**
     * Scan root directory for APK files with smart filtering
     */
    private fun scanRootForApps(
        rootDir: File,
        fileMap: ConcurrentHashMap<String, Map<String, Any>>,
        extensions: Set<String>
    ) {
        // Scan root level for APKs
        rootDir.listFiles()?.forEach { file ->
            if (file.isFile && !file.isHidden) {
                val extension = getExtensionFromPath(file.name)
                if (extensions.contains(extension.lowercase())) {
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
            }
        }
        
        // Scan subdirectories with priority for app-related folders
        val appDirs = listOf("Download", "Downloads", "Apk", "APKs", "Apps", "backup", "Backups",
                            "Bluetooth", "ShareIt", "Xender", "SHAREit", "Received Files")
        
        rootDir.listFiles()?.forEach { dir ->
            if (dir.isDirectory && !dir.isHidden && dir.canRead()) {
                val dirName = dir.name
                // Deep scan for known app directories
                if (appDirs.any { dirName.contains(it, ignoreCase = true) }) {
                    scanDirectoryForFiles(dir, fileMap, extensions, 0, maxDepth = 4)
                } else if (!dirName.startsWith(".")) {
                    // Shallow scan for other directories
                    scanDirectoryForFiles(dir, fileMap, extensions, 0, maxDepth = 1)
                }
            }
        }
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
            // Images
            ".jpg", ".jpeg" -> "image/jpeg"
            ".png" -> "image/png"
            ".gif" -> "image/gif"
            ".bmp" -> "image/bmp"
            ".webp" -> "image/webp"
            ".svg" -> "image/svg+xml"
            ".ico" -> "image/x-icon"
            ".tiff", ".tif" -> "image/tiff"
            ".heic", ".heif" -> "image/heif"
            // Videos
            ".mp4" -> "video/mp4"
            ".avi" -> "video/x-msvideo"
            ".mkv" -> "video/x-matroska"
            ".mov" -> "video/quicktime"
            ".wmv" -> "video/x-ms-wmv"
            ".flv" -> "video/x-flv"
            ".webm" -> "video/webm"
            ".3gp" -> "video/3gpp"
            ".mpg", ".mpeg" -> "video/mpeg"
            // Audio
            ".mp3" -> "audio/mpeg"
            ".wav" -> "audio/wav"
            ".flac" -> "audio/flac"
            ".aac" -> "audio/aac"
            ".ogg" -> "audio/ogg"
            ".wma" -> "audio/x-ms-wma"
            ".m4a" -> "audio/mp4"
            ".opus" -> "audio/opus"
            ".amr" -> "audio/amr"
            // Documents
            ".pdf" -> "application/pdf"
            ".doc" -> "application/msword"
            ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ".xls" -> "application/vnd.ms-excel"
            ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            ".ppt" -> "application/vnd.ms-powerpoint"
            ".pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            ".txt" -> "text/plain"
            ".csv" -> "text/csv"
            ".xml" -> "application/xml"
            ".json" -> "application/json"
            ".html", ".htm" -> "text/html"
            ".rtf" -> "application/rtf"
            ".odt" -> "application/vnd.oasis.opendocument.text"
            ".ods" -> "application/vnd.oasis.opendocument.spreadsheet"
            ".odp" -> "application/vnd.oasis.opendocument.presentation"
            // E-books
            ".epub" -> "application/epub+zip"
            ".mobi" -> "application/x-mobipocket-ebook"
            ".azw", ".azw3" -> "application/vnd.amazon.ebook"
            ".fb2" -> "application/x-fictionbook+xml"
            // Applications
            ".apk" -> "application/vnd.android.package-archive"
            ".xapk" -> "application/vnd.android.package-archive"
            ".aab" -> "application/x-authorware-bin"
            // Archives
            ".zip" -> "application/zip"
            ".rar" -> "application/x-rar-compressed"
            ".7z" -> "application/x-7z-compressed"
            ".tar" -> "application/x-tar"
            ".gz" -> "application/gzip"
            // Other
            ".iso" -> "application/x-iso9660-image"
            ".exe" -> "application/x-msdownload"
            ".dmg" -> "application/x-apple-diskimage"
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

    /**
     * Check if notifications are enabled for the app
     */
    private fun areNotificationsEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                notificationManager.areNotificationsEnabled()
            } else {
                // For API < 26, notifications are enabled by default
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            true // Default to enabled if we can't check
        }
    }

    /**
     * Request notification permission (Android 13+)
     */
    private fun requestNotificationPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // For Android 13+, permission must be requested through Flutter
                // This method returns whether the permission dialog can be shown
                if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    // Permission not granted, Flutter will handle the request
                    false
                } else {
                    // Permission already granted
                    true
                }
            } else {
                // For Android < 13, notifications don't require runtime permission
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            true // Default to true for older versions
        }
    }
    
    /**
     * Get file sizes and counts for each category
     */
    private fun getCategorySizes(): Map<String, Any> {
        val categorySizes = mutableMapOf<String, Any>()
        
        try {
            // Get file counts and sizes for each category
            val categories = listOf("images", "videos", "audio", "documents", "apps", "others")
            
            for (category in categories) {
                val files = when (category) {
                    "images" -> getMediaFilesForCategory("images")
                    "videos" -> getMediaFilesForCategory("videos")
                    "audio" -> getMediaFilesForCategory("audio")
                    "documents" -> getDocumentFilesForCategory()
                    "apps" -> getAppFilesForCategory()
                    "others" -> getOtherFilesForCategory()
                    else -> emptyList()
                }
                
                var totalSize = 0L
                var fileCount = 0
                
                for (file in files) {
                    totalSize += (file["size"] as? Long) ?: 0
                    fileCount++
                }
                
                categorySizes["${category}_size"] = totalSize
                categorySizes["${category}_count"] = fileCount
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
            // Return empty sizes on error
            val categories = listOf("images", "videos", "audio", "documents", "apps", "others")
            for (category in categories) {
                categorySizes["${category}_size"] = 0L
                categorySizes["${category}_count"] = 0
            }
        }
        
        return categorySizes
    }
    
    /**
     * Helper method to get media files for category size calculation
     */
    private fun getMediaFilesForCategory(type: String): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
        
        getMediaFiles(type, fileMap)
        filesList.addAll(fileMap.values)
        
        return filesList
    }
    
    /**
     * Helper method to get document files for category size calculation
     */
    private fun getDocumentFilesForCategory(): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
        
        getDocumentFiles(fileMap)
        filesList.addAll(fileMap.values)
        
        return filesList
    }
    
    /**
     * Helper method to get app files for category size calculation
     */
    private fun getAppFilesForCategory(): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
        
        getAppFiles(fileMap)
        filesList.addAll(fileMap.values)
        
        return filesList
    }
    
    /**
     * Helper method to get other files for category size calculation
     */
    private fun getOtherFilesForCategory(): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val fileMap = ConcurrentHashMap<String, Map<String, Any>>()
        
        getOtherFiles(fileMap)
        filesList.addAll(fileMap.values)
        
        return filesList
    }
}