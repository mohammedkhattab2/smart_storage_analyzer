package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs

class StorageAnalyzer(private val context: Context) {
    companion object {
        // File size thresholds
        private const val LARGE_FILE_THRESHOLD = 100 * 1024 * 1024L // 100MB
        private const val OLD_FILE_DAYS = 180 // 6 months
        private const val OLD_FILE_THRESHOLD = OLD_FILE_DAYS * 24 * 60 * 60 * 1000L
        
        // Cache and temp file patterns
        private val CACHE_PATTERNS = listOf(
            "/cache/",
            "/.cache/",
            "/temp/",
            "/.temp/",
            "/tmp/",
            ".tmp",
            ".temp",
            ".cache"
        )
        
        private val THUMBNAIL_PATTERNS = listOf(
            "/.thumbnails/",
            "/thumbnails/",
            ".thumbnail",
            "_thumb",
            "-thumb"
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
            File(Environment.getExternalStorageDirectory(), "tmp")
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
                    val isCache = CACHE_PATTERNS.any { pattern -> path.contains(pattern) }
                    
                    if (isCache) {
                        val fileInfo = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "name" to file.name,
                            "path" to file.absolutePath,
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to getFileExtension(file)
                        )
                        
                        if (path.contains("temp") || path.contains("tmp")) {
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
            File(Environment.getExternalStorageDirectory(), "WhatsApp/Media/.Thumbnails")
        )
        
        for (dir in thumbnailDirs) {
            if (dir.exists() && dir.canRead()) {
                scanDirectoryForThumbnails(dir, thumbnails)
            }
        }
        
        // Also scan Android media thumbnails
        val androidMediaDir = File(Environment.getExternalStorageDirectory(), "Android/media")
        if (androidMediaDir.exists() && androidMediaDir.canRead()) {
            scanDirectoryForThumbnails(androidMediaDir, thumbnails, checkPatterns = true)
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
                    val shouldAdd = if (checkPatterns) {
                        THUMBNAIL_PATTERNS.any { pattern -> 
                            file.absolutePath.lowercase().contains(pattern) ||
                            file.name.lowercase().contains(pattern)
                        }
                    } else {
                        true // In dedicated thumbnail directories, all files are thumbnails
                    }
                    
                    if (shouldAdd) {
                        thumbnails.add(
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
                } else if (file.isDirectory && file.canRead()) {
                    // Check if this is a thumbnail directory
                    val isDedicatedThumbDir = THUMBNAIL_PATTERNS.any { pattern ->
                        file.name.lowercase().contains(pattern.trim('/'))
                    }
                    
                    if (isDedicatedThumbDir || !checkPatterns) {
                        scanDirectoryForThumbnails(file, thumbnails, false, depth + 1, maxDepth)
                    } else {
                        scanDirectoryForThumbnails(file, thumbnails, true, depth + 1, maxDepth)
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Find duplicate files
     */
    private fun findDuplicates(duplicateFiles: MutableList<Map<String, Any>>) {
        val fileMap = ConcurrentHashMap<String, MutableList<Map<String, Any>>>()
        
        // Collect all media files from MediaStore
        collectMediaFiles(fileMap)
        
        // Find duplicates based on name and size
        for ((key, files) in fileMap) {
            if (files.size > 1) {
                // Sort by modification date to keep the oldest
                files.sortBy { it["lastModified"] as Long }
                
                // Mark all except the first as duplicates
                duplicateFiles.addAll(files.drop(1))
            }
        }
    }
    
    /**
     * Collect media files for duplicate detection
     */
    private fun collectMediaFiles(fileMap: ConcurrentHashMap<String, MutableList<Map<String, Any>>>) {
        val contentResolver = context.contentResolver
        
        // Collect images
        collectFromMediaStore(contentResolver, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, fileMap)
        
        // Collect videos
        collectFromMediaStore(contentResolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI, fileMap)
        
        // Collect audio
        collectFromMediaStore(contentResolver, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, fileMap)
    }
    
    /**
     * Collect files from MediaStore
     */
    private fun collectFromMediaStore(
        contentResolver: ContentResolver,
        uri: Uri,
        fileMap: ConcurrentHashMap<String, MutableList<Map<String, Any>>>
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
                    
                    // Skip very small files
                    if (size < 1024) continue
                    
                    val key = "${name}_${size}"
                    val fileInfo = mapOf(
                        "id" to it.getLong(idColumn).toString(),
                        "name" to name,
                        "path" to (it.getString(pathColumn) ?: ""),
                        "size" to size,
                        "lastModified" to (it.getLong(dateColumn) * 1000),
                        "extension" to getFileExtension(File(name))
                    )
                    
                    fileMap.computeIfAbsent(key) { mutableListOf() }.add(fileInfo)
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