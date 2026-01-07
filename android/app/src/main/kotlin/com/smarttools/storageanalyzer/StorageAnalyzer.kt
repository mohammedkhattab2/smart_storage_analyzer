package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs

class StorageAnalyzer(private val context: Context) {
    companion object {
        // File size thresholds
        private const val LARGE_FILE_THRESHOLD = 100 * 1024 * 1024L // 100MB
        private const val OLD_FILE_DAYS = 180 // 6 months
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
        
        // Cache and temp file patterns - comprehensive list
        private val CACHE_PATTERNS = listOf(
            "/cache/",
            "/.cache/",
            "/temp/",
            "/.temp/",
            "/tmp/",
            "/.tmp/",
            "/Cache/",
            "/Caches/",
            "/.Caches/",
            "/com.android.chrome/",
            "/cachetemp/",
            "/webcache/",
            ".tmp",
            ".temp",
            ".cache",
            ".bak",
            ".backup",
            "~",
            ".swp",
            ".swo",
            ".log",
            ".thumb",
            ".thumbnails"
        )
        
        // Additional temporary file extensions
        private val TEMP_EXTENSIONS = listOf(
            ".tmp", ".temp", ".partial", ".part", ".download",
            ".crdownload", ".td", ".dlcrdownload", ".bc!", ".bc",
            ".unconfirmed", ".adadownload", ".blkdwn", ".inflight",
            ".jdownloader", ".pud", ".tmp.exe", ".tmpfs", ".lck",
            ".lock", "._mp", ".~tmp"
        )
        
        // App-specific cache directories
        private val APP_CACHE_DIRS = listOf(
            "com.whatsapp", "com.facebook.katana", "com.instagram.android",
            "com.snapchat.android", "com.twitter.android", "com.chrome.android",
            "com.android.chrome", "com.google.android.apps.photos",
            "com.telegram.messenger", "com.viber.voip", "com.skype.raider"
        )
        
        private val THUMBNAIL_PATTERNS = listOf(
            "/.thumbnails/",
            "/thumbnails/",
            "/.Thumbnails/",
            "/Thumbnails/",
            ".thumbnail",
            "_thumb",
            "-thumb",
            "_tn",
            ".thm",
            "/thumb/",
            "/thumbs/",
            "/.thumb/",
            "/.thumbs/",
            "/album_thumb/",
            "/cover_thumb/",
            ".micro_thumb",
            ".mini_thumb"
        )
    }
    
    data class AnalysisResult(
        val totalFilesScanned: Int,
        val totalSpaceUsed: Long,
        val totalSpaceAvailable: Long,
        val cacheFiles: List<Map<String, Any>>,
        val temporaryFiles: List<Map<String, Any>>,
        val largeOldFiles: List<Map<String, Any>>,
        val duplicateFiles: List<Map<String, Any>>,
        val thumbnails: List<Map<String, Any>>,
        val totalCleanupPotential: Long
    )
    
    /**
     * Perform deep storage analysis
     */
    fun analyzeStorage(): AnalysisResult {
        val cacheFiles = mutableListOf<Map<String, Any>>()
        val tempFiles = mutableListOf<Map<String, Any>>()
        val largeOldFiles = mutableListOf<Map<String, Any>>()
        val duplicateFiles = mutableListOf<Map<String, Any>>()
        val thumbnails = mutableListOf<Map<String, Any>>()
        
        var totalFilesScanned = 0
        
        // Scan for different types of files
        scanCacheFiles(cacheFiles, tempFiles)
        scanForLargeOldFiles(largeOldFiles)
        scanForThumbnails(thumbnails)
        findDuplicates(duplicateFiles)
        
        // Count total files
        totalFilesScanned = cacheFiles.size + tempFiles.size + largeOldFiles.size + 
                          duplicateFiles.size + thumbnails.size
        
        // Calculate cleanup potential
        val totalCleanupPotential = 
            cacheFiles.sumOf { (it["size"] as Long) } +
            tempFiles.sumOf { (it["size"] as Long) } +
            duplicateFiles.sumOf { (it["size"] as Long) } +
            thumbnails.sumOf { (it["size"] as Long) }
        
        // Get storage info
        val stat = android.os.StatFs(Environment.getExternalStorageDirectory().path)
        val totalSpace = stat.blockSizeLong * stat.blockCountLong
        val availableSpace = stat.blockSizeLong * stat.availableBlocksLong
        val usedSpace = totalSpace - availableSpace
        
        return AnalysisResult(
            totalFilesScanned = totalFilesScanned,
            totalSpaceUsed = usedSpace,
            totalSpaceAvailable = totalSpace,
            cacheFiles = cacheFiles,
            temporaryFiles = tempFiles,
            largeOldFiles = largeOldFiles,
            duplicateFiles = duplicateFiles,
            thumbnails = thumbnails,
            totalCleanupPotential = totalCleanupPotential
        )
    }
    
    /**
     * Scan for cache and temporary files
     */
    private fun scanCacheFiles(
        cacheFiles: MutableList<Map<String, Any>>,
        tempFiles: MutableList<Map<String, Any>>
    ) {
        // Scan app cache directories
        val cacheDir = context.cacheDir
        scanDirectoryForCache(cacheDir, cacheFiles, tempFiles)
        
        // Scan external cache if available
        val externalCacheDir = context.externalCacheDir
        if (externalCacheDir != null) {
            scanDirectoryForCache(externalCacheDir, cacheFiles, tempFiles)
        }
        
        // Scan common cache locations
        val commonCachePaths = listOf(
            File(Environment.getExternalStorageDirectory(), ".cache"),
            File(Environment.getExternalStorageDirectory(), "temp"),
            File(Environment.getExternalStorageDirectory(), "tmp"),
            File(Environment.getExternalStorageDirectory(), ".temp"),
            File(Environment.getExternalStorageDirectory(), ".tmp"),
            File(Environment.getExternalStorageDirectory(), "Cache"),
            File(Environment.getExternalStorageDirectory(), "Download/.tmp"),
            File(Environment.getExternalStorageDirectory(), "Downloads/.tmp"),
            File(Environment.getExternalStorageDirectory(), "DCIM/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Pictures/.thumbnails")
        )
        
        for (path in commonCachePaths) {
            if (path.exists() && path.canRead()) {
                scanDirectoryForCache(path, cacheFiles, tempFiles)
            }
        }
        
        // Scan Android app cache directories
        val androidDataDir = File(Environment.getExternalStorageDirectory(), "Android/data")
        if (androidDataDir.exists() && androidDataDir.canRead()) {
            androidDataDir.listFiles()?.forEach { appDir ->
                val appCacheDir = File(appDir, "cache")
                if (appCacheDir.exists() && appCacheDir.canRead()) {
                    scanDirectoryForCache(appCacheDir, cacheFiles, tempFiles, depth = 0, maxDepth = 2)
                }
                
                // Also check for files/cache subdirectory
                val filesCacheDir = File(appDir, "files/cache")
                if (filesCacheDir.exists() && filesCacheDir.canRead()) {
                    scanDirectoryForCache(filesCacheDir, cacheFiles, tempFiles, depth = 0, maxDepth = 2)
                }
            }
        }
        
        // Scan app-specific directories
        for (appPackage in APP_CACHE_DIRS) {
            val appSpecificDir = File(Environment.getExternalStorageDirectory(), appPackage)
            if (appSpecificDir.exists() && appSpecificDir.canRead()) {
                scanDirectoryForCache(appSpecificDir, cacheFiles, tempFiles, depth = 0, maxDepth = 2)
            }
        }
    }
    
    /**
     * Recursively scan directory for cache files
     */
    private fun scanDirectoryForCache(
        directory: File,
        cacheFiles: MutableList<Map<String, Any>>,
        tempFiles: MutableList<Map<String, Any>>,
        depth: Int = 0,
        maxDepth: Int = 5
    ) {
        if (depth > maxDepth) return
        
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile) {
                    val path = file.absolutePath.lowercase()
                    val fileName = file.name.lowercase()
                    val extension = getFileExtension(file).lowercase()
                    
                    // Check if it's a cache file by path patterns
                    val isCachePath = CACHE_PATTERNS.any { pattern ->
                        path.contains(pattern) || fileName.contains(pattern)
                    }
                    
                    // Check if it's a temporary file by extension
                    val isTempExtension = TEMP_EXTENSIONS.any { ext ->
                        extension == ext || fileName.endsWith(ext)
                    }
                    
                    // Check if parent directory is a cache directory
                    val isInCacheDir = file.parent?.let { parent ->
                        parent.contains("/cache") || parent.contains("/.cache") ||
                        parent.contains("/temp") || parent.contains("/.temp") ||
                        parent.contains("/tmp") || parent.contains("/.tmp")
                    } ?: false
                    
                    if (isCachePath || isTempExtension || isInCacheDir) {
                        val fileInfo = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "name" to file.name,
                            "path" to file.absolutePath,
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to extension
                        )
                        
                        // Categorize as temp or cache
                        if (isTempExtension || path.contains("temp") || path.contains("tmp") ||
                            fileName.contains(".download") || fileName.contains(".partial")) {
                            tempFiles.add(fileInfo)
                        } else {
                            cacheFiles.add(fileInfo)
                        }
                    }
                } else if (file.isDirectory && file.canRead()) {
                    scanDirectoryForCache(file, cacheFiles, tempFiles, depth + 1, maxDepth)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Scan for large old files
     */
    private fun scanForLargeOldFiles(largeOldFiles: MutableList<Map<String, Any>>) {
        val now = System.currentTimeMillis()
        val oldThreshold = now - OLD_FILE_THRESHOLD
        
        // Scan common user directories
        val userDirs = listOf(
            File(Environment.getExternalStorageDirectory(), "Download"),
            File(Environment.getExternalStorageDirectory(), "Downloads"),
            File(Environment.getExternalStorageDirectory(), "Documents"),
            File(Environment.getExternalStorageDirectory(), "Movies"),
            File(Environment.getExternalStorageDirectory(), "DCIM/Camera")
        )
        
        for (dir in userDirs) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForLargeOld(dir, largeOldFiles, oldThreshold)
            }
        }
        
        // Also check MediaStore for large old media files
        scanMediaStoreForLargeOld(largeOldFiles, oldThreshold)
    }
    
    /**
     * Scan directory for large old files
     */
    private fun scanDirectoryForLargeOld(
        directory: File,
        largeOldFiles: MutableList<Map<String, Any>>,
        oldThreshold: Long,
        depth: Int = 0,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth) return
        
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile) {
                    if (file.length() >= LARGE_FILE_THRESHOLD && 
                        file.lastModified() < oldThreshold) {
                        largeOldFiles.add(
                            mapOf(
                                "id" to file.absolutePath.hashCode().toString(),
                                "name" to file.name,
                                "path" to file.absolutePath,
                                "size" to file.length(),
                                "lastModified" to file.lastModified(),
                                "extension" to getFileExtension(file)
                            )
                        )
                    }
                } else if (file.isDirectory && file.canRead() && !file.name.startsWith(".")) {
                    scanDirectoryForLargeOld(file, largeOldFiles, oldThreshold, depth + 1, maxDepth)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Scan MediaStore for large old media files
     */
    private fun scanMediaStoreForLargeOld(
        largeOldFiles: MutableList<Map<String, Any>>,
        oldThreshold: Long
    ) {
        val contentResolver = context.contentResolver
        
        // Query for large old images
        queryMediaStore(
            contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            largeOldFiles,
            oldThreshold
        )
        
        // Query for large old videos
        queryMediaStore(
            contentResolver,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            largeOldFiles,
            oldThreshold
        )
    }
    
    /**
     * Query MediaStore for files
     */
    private fun queryMediaStore(
        contentResolver: ContentResolver,
        uri: Uri,
        largeOldFiles: MutableList<Map<String, Any>>,
        oldThreshold: Long
    ) {
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED
        )
        
        val selection = "${MediaStore.MediaColumns.SIZE} >= ? AND ${MediaStore.MediaColumns.DATE_MODIFIED} < ?"
        val selectionArgs = arrayOf(
            LARGE_FILE_THRESHOLD.toString(),
            (oldThreshold / 1000).toString() // MediaStore uses seconds
        )
        
        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                null
            )
            
            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val pathColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                val sizeColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val dateColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                
                while (it.moveToNext()) {
                    val path = it.getString(pathColumn) ?: continue
                    
                    largeOldFiles.add(
                        mapOf(
                            "id" to it.getLong(idColumn).toString(),
                            "name" to (it.getString(nameColumn) ?: "Unknown"),
                            "path" to path,
                            "size" to it.getLong(sizeColumn),
                            "lastModified" to (it.getLong(dateColumn) * 1000), // Convert to milliseconds
                            "extension" to getFileExtension(File(path))
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Scan for thumbnail files
     */
    private fun scanForThumbnails(thumbnails: MutableList<Map<String, Any>>) {
        // Common thumbnail locations
        val thumbnailDirs = listOf(
            File(Environment.getExternalStorageDirectory(), ".thumbnails"),
            File(Environment.getExternalStorageDirectory(), "DCIM/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Pictures/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "WhatsApp/Media/.Thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Telegram/Telegram Images/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Viber/media/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Instagram/media/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Snapchat/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Facebook/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Twitter/media/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Screenshots/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Camera/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Download/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Movies/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Music/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Podcasts/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Audiobooks/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Ringtones/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Alarms/.thumbnails"),
            File(Environment.getExternalStorageDirectory(), "Notifications/.thumbnails")
        )
        
        for (dir in thumbnailDirs) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForThumbnails(dir, thumbnails, checkPatterns = false)
            }
        }
        
        // Also scan Android directories
        val androidDirs = listOf(
            File(Environment.getExternalStorageDirectory(), "Android/media"),
            File(Environment.getExternalStorageDirectory(), "Android/data")
        )
        
        for (dir in androidDirs) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForThumbnails(dir, thumbnails, checkPatterns = true)
            }
        }
        
        // Scan root directory for hidden thumbnail directories
        val rootDir = Environment.getExternalStorageDirectory()
        rootDir.listFiles()?.forEach { file ->
            if (file.isDirectory && file.name.contains(".thumb", ignoreCase = true)) {
                scanDirectoryForThumbnails(file, thumbnails, checkPatterns = false)
            }
        }
        
        // Scan MediaStore for thumbnail entries
        scanMediaStoreForThumbnails(thumbnails)
    }
    
    /**
     * Scan MediaStore for thumbnail files
     */
    private fun scanMediaStoreForThumbnails(thumbnails: MutableList<Map<String, Any>>) {
        val contentResolver = context.contentResolver
        
        // Query for thumbnails in MediaStore
        try {
            val uri = MediaStore.Files.getContentUri("external")
            val projection = arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED
            )
            
            // Look for files with thumbnail patterns in their path
            val selection = "${MediaStore.Files.FileColumns.DATA} LIKE ? OR " +
                           "${MediaStore.Files.FileColumns.DATA} LIKE ? OR " +
                           "${MediaStore.Files.FileColumns.DATA} LIKE ? OR " +
                           "${MediaStore.Files.FileColumns.DATA} LIKE ?"
            
            val selectionArgs = arrayOf(
                "%/.thumbnails/%",
                "%/thumbnails/%",
                "%/.thumb/%",
                "%thumb%"
            )
            
            val cursor = contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                null
            )
            
            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val nameColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val pathColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
                val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                val dateColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
                
                while (it.moveToNext()) {
                    val path = it.getString(pathColumn) ?: continue
                    
                    // Additional check to avoid duplicates
                    if (thumbnails.any { thumb -> (thumb["path"] as String) == path }) {
                        continue
                    }
                    
                    thumbnails.add(
                        mapOf(
                            "id" to it.getLong(idColumn).toString(),
                            "name" to (it.getString(nameColumn) ?: "Unknown"),
                            "path" to path,
                            "size" to it.getLong(sizeColumn),
                            "lastModified" to (it.getLong(dateColumn) * 1000),
                            "extension" to getFileExtension(File(path))
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Scan directory for thumbnail files
     */
    private fun scanDirectoryForThumbnails(
        directory: File,
        thumbnails: MutableList<Map<String, Any>>,
        checkPatterns: Boolean = false,
        depth: Int = 0,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth) return
        
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile) {
                    val fileName = file.name.lowercase()
                    val filePath = file.absolutePath.lowercase()
                    
                    val shouldAdd = if (checkPatterns) {
                        // Check if file matches thumbnail patterns
                        THUMBNAIL_PATTERNS.any { pattern ->
                            filePath.contains(pattern) || fileName.contains(pattern)
                        } ||
                        // Check for common thumbnail file extensions and sizes
                        (isImageFile(fileName) && file.length() < 50 * 1024) || // Small images < 50KB
                        // Check for specific thumbnail naming patterns
                        fileName.matches(Regex(".*\\.(thumb|thumbnail|preview|icon)\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.matches(Regex("thumb_.*\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.matches(Regex(".*_thumb\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.matches(Regex(".*-thumb\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.matches(Regex("tn_.*\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.matches(Regex(".*_tn\\.(jpg|jpeg|png|gif|webp)$")) ||
                        fileName.contains(".albumthumbs") ||
                        fileName.startsWith(".")
                    } else {
                        true // In dedicated thumbnail directories, all files are thumbnails
                    }
                    
                    if (shouldAdd) {
                        // Avoid duplicates
                        val path = file.absolutePath
                        if (thumbnails.none { it["path"] == path }) {
                            thumbnails.add(
                                mapOf(
                                    "id" to path.hashCode().toString(),
                                    "name" to file.name,
                                    "path" to path,
                                    "size" to file.length(),
                                    "lastModified" to file.lastModified(),
                                    "extension" to getFileExtension(file)
                                )
                            )
                        }
                    }
                } else if (file.isDirectory && file.canRead() && !file.isHidden) {
                    // Check if this is a thumbnail directory
                    val dirName = file.name.lowercase()
                    val isDedicatedThumbDir = THUMBNAIL_PATTERNS.any { pattern ->
                        dirName.contains(pattern.trim('/').lowercase())
                    } || dirName == ".thumbnails" || dirName == "thumbnails" ||
                      dirName == ".thumb" || dirName == "thumb" || dirName == ".thumbs" ||
                      dirName == "thumbs" || dirName.contains("thumbnail") ||
                      dirName.contains("albumthumbs") || dirName.contains("cover")
                    
                    if (isDedicatedThumbDir || !checkPatterns) {
                        scanDirectoryForThumbnails(file, thumbnails, false, depth + 1, maxDepth)
                    } else if (depth < 2) { // Only go deeper for pattern checking in shallow directories
                        scanDirectoryForThumbnails(file, thumbnails, true, depth + 1, maxDepth)
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Check if file is an image file
     */
    private fun isImageFile(fileName: String): Boolean {
        val imageExtensions = listOf(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico")
        return imageExtensions.any { fileName.endsWith(it) }
    }
    
    /**
     * Find duplicate files using improved algorithm
     */
    private fun findDuplicates(duplicateFiles: MutableList<Map<String, Any>>) {
        // Step 1: Group files by size (fast initial filter)
        val sizeGroups = ConcurrentHashMap<Long, MutableList<Map<String, Any>>>()
        
        // Collect all files
        collectAllFiles(sizeGroups)
        
        // Step 2: For files with same size, calculate MD5 hash
        for ((size, files) in sizeGroups) {
            if (files.size > 1 && size > 1024) { // Skip files smaller than 1KB
                val hashGroups = mutableMapOf<String, MutableList<Map<String, Any>>>()
                
                for (file in files) {
                    val path = file["path"] as String
                    val hash = calculateFileHash(path)
                    
                    if (hash != null) {
                        hashGroups.computeIfAbsent(hash) { mutableListOf() }.add(file)
                    }
                }
                
                // Step 3: Mark duplicates
                for ((hash, duplicateGroup) in hashGroups) {
                    if (duplicateGroup.size > 1) {
                        // Sort by modification date to keep the oldest
                        duplicateGroup.sortBy { it["lastModified"] as Long }
                        
                        // Mark all except the first as duplicates
                        duplicateFiles.addAll(duplicateGroup.drop(1))
                    }
                }
            }
        }
    }
    
    /**
     * Calculate MD5 hash of a file
     */
    private fun calculateFileHash(filePath: String): String? {
        return try {
            val file = File(filePath)
            if (!file.exists() || !file.canRead()) return null
            
            val digest = MessageDigest.getInstance("MD5")
            val buffer = ByteArray(8192)
            
            FileInputStream(file).use { fis ->
                var bytesRead: Int
                while (fis.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            
            // Convert to hex string
            digest.digest().joinToString("") { byte ->
                "%02x".format(byte)
            }
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Collect all files for duplicate detection
     */
    private fun collectAllFiles(sizeGroups: ConcurrentHashMap<Long, MutableList<Map<String, Any>>>) {
        val contentResolver = context.contentResolver
        
        // Collect media files from MediaStore
        collectFromMediaStore(contentResolver, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, sizeGroups)
        collectFromMediaStore(contentResolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI, sizeGroups)
        collectFromMediaStore(contentResolver, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, sizeGroups)
        
        // Also scan common directories for documents and other files
        val dirsToScan = listOf(
            File(Environment.getExternalStorageDirectory(), "Download"),
            File(Environment.getExternalStorageDirectory(), "Downloads"),
            File(Environment.getExternalStorageDirectory(), "Documents"),
            File(Environment.getExternalStorageDirectory(), "WhatsApp/Media"),
            File(Environment.getExternalStorageDirectory(), "Telegram"),
            File(Environment.getExternalStorageDirectory(), "DCIM"),
            File(Environment.getExternalStorageDirectory(), "Pictures")
        )
        
        for (dir in dirsToScan) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForDuplicates(dir, sizeGroups)
            }
        }
    }
    
    /**
     * Scan directory for files to check for duplicates
     */
    private fun scanDirectoryForDuplicates(
        directory: File,
        sizeGroups: ConcurrentHashMap<Long, MutableList<Map<String, Any>>>,
        depth: Int = 0,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth) return
        
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile && !file.isHidden && file.length() > 1024) {
                    val fileInfo = mapOf(
                        "id" to file.absolutePath.hashCode().toString(),
                        "name" to file.name,
                        "path" to file.absolutePath,
                        "size" to file.length(),
                        "lastModified" to file.lastModified(),
                        "extension" to getFileExtension(file)
                    )
                    
                    sizeGroups.computeIfAbsent(file.length()) { mutableListOf() }.add(fileInfo)
                } else if (file.isDirectory && file.canRead() && !file.name.startsWith(".")) {
                    scanDirectoryForDuplicates(file, sizeGroups, depth + 1, maxDepth)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Collect files from MediaStore
     */
    private fun collectFromMediaStore(
        contentResolver: ContentResolver,
        uri: Uri,
        sizeGroups: ConcurrentHashMap<Long, MutableList<Map<String, Any>>>
    ) {
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED
        )
        
        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, null, null, null)
            
            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val pathColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                val sizeColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                val dateColumn = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                
                while (it.moveToNext()) {
                    val name = it.getString(nameColumn) ?: continue
                    val size = it.getLong(sizeColumn)
                    val path = it.getString(pathColumn) ?: continue
                    
                    // Skip very small files and non-existent files
                    if (size < 1024 || !File(path).exists()) continue
                    
                    val fileInfo = mapOf(
                        "id" to it.getLong(idColumn).toString(),
                        "name" to name,
                        "path" to path,
                        "size" to size,
                        "lastModified" to (it.getLong(dateColumn) * 1000),
                        "extension" to getFileExtension(File(name))
                    )
                    
                    sizeGroups.computeIfAbsent(size) { mutableListOf() }.add(fileInfo)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Get file extension
     */
    private fun getFileExtension(file: File): String {
        val name = file.name
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0) name.substring(lastDot) else ""
    }
}