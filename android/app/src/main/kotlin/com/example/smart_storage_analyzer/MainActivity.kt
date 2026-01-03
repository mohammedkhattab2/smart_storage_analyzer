package com.example.smart_storage_analyzer

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        // Primary channel for storage operations
        private const val STORAGE_CHANNEL = "com.smarttools.imagecompressor/native"
        // Legacy channel for other operations
        private const val LEGACY_CHANNEL = "com.smartstorage/native"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
                    result.success(getAllFilesByCategory(category))
                }
                "deleteFiles" -> {
                    val filePaths = call.argument<List<String>>("paths") ?: listOf()
                    result.success(deleteFiles(filePaths))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Get total storage space in bytes
     * Uses StatFs API to calculate total device storage
     * @return Total storage space in bytes (Long)
     */
    private fun getTotalStorage(): Long {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            stat.blockSizeLong * stat.blockCountLong
        } catch (e: Exception) {
            // Return 0 if unable to get storage info
            0L
        }
    }

    /**
     * Get free storage space in bytes
     * Uses StatFs API to calculate available storage
     * @return Free storage space in bytes (Long)
     */
    private fun getFreeStorage(): Long {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            stat.blockSizeLong * stat.availableBlocksLong
        } catch (e: Exception) {
            // Return 0 if unable to get storage info
            0L
        }
    }

    /**
     * Get used storage space in bytes
     * Calculates as: Total - Free
     * @return Used storage space in bytes (Long)
     */
    private fun getUsedStorage(): Long {
        return try {
            val total = getTotalStorage()
            val free = getFreeStorage()
            if (total > 0 && free >= 0) total - free else 0L
        } catch (e: Exception) {
            // Return 0 if unable to calculate
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
        return getAllFilesByCategory("all")
    }
    
    /**
     * Get files by category with proper filtering
     */
    private fun getAllFilesByCategory(category: String): List<Map<String, Any>> {
        val filesList = mutableListOf<Map<String, Any>>()
        val scannedPaths = mutableSetOf<String>()
        
        try {
            // Get common directories to scan
            val dirsToScan = getDirectoriesToScan()
            
            for (dir in dirsToScan) {
                if (dir.exists() && dir.canRead()) {
                    scanDirectoryByCategory(dir, filesList, scannedPaths, category, 0)
                }
            }
            
            // Sort by size (largest first) for better UX
            filesList.sortByDescending { (it["size"] as? Long) ?: 0 }
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return filesList
    }
    
    /**
     * Get directories to scan based on Android storage structure
     */
    private fun getDirectoriesToScan(): List<java.io.File> {
        val dirs = mutableListOf<java.io.File>()
        
        // Primary external storage
        val externalDir = Environment.getExternalStorageDirectory()
        
        // Common user directories
        dirs.add(java.io.File(externalDir, "Download"))
        dirs.add(java.io.File(externalDir, "Downloads"))
        dirs.add(java.io.File(externalDir, "DCIM"))
        dirs.add(java.io.File(externalDir, "Pictures"))
        dirs.add(java.io.File(externalDir, "Movies"))
        dirs.add(java.io.File(externalDir, "Music"))
        dirs.add(java.io.File(externalDir, "Documents"))
        dirs.add(java.io.File(externalDir, "WhatsApp"))
        dirs.add(java.io.File(externalDir, "Telegram"))
        dirs.add(java.io.File(externalDir, "Android/media"))
        
        // Also scan root storage for other files
        dirs.add(externalDir)
        
        return dirs.filter { it.exists() }
    }
    
    /**
     * Recursively scan directory with category filtering
     */
    private fun scanDirectoryByCategory(
        directory: java.io.File,
        filesList: MutableList<Map<String, Any>>,
        scannedPaths: MutableSet<String>,
        category: String,
        depth: Int
    ) {
        // Limit recursion depth to avoid performance issues
        if (depth > 3) return
        
        // Skip system directories
        val skipDirs = listOf(".", "..", ".android", ".thumbnails", "Android/data", "Android/obb")
        if (skipDirs.any { directory.absolutePath.contains(it) }) return
        
        try {
            val files = directory.listFiles() ?: return
            
            for (file in files) {
                if (file.isFile && !file.isHidden) {
                    // Avoid duplicates
                    if (scannedPaths.contains(file.absolutePath)) continue
                    scannedPaths.add(file.absolutePath)
                    
                    // Apply category filter
                    if (shouldIncludeFile(file, category)) {
                        val fileInfo = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "path" to file.absolutePath,
                            "name" to file.name,
                            "size" to file.length(),
                            "lastModified" to file.lastModified(),
                            "extension" to getFileExtension(file),
                            "mimeType" to getMimeType(file)
                        )
                        filesList.add(fileInfo)
                    }
                } else if (file.isDirectory && !file.isHidden && file.canRead()) {
                    // Recursively scan subdirectories
                    scanDirectoryByCategory(file, filesList, scannedPaths, category, depth + 1)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors for specific directories
        }
    }
    
    /**
     * Check if file should be included based on category
     */
    private fun shouldIncludeFile(file: java.io.File, category: String): Boolean {
        when (category) {
            "all" -> return true
            "large" -> return file.length() > 50 * 1024 * 1024 // Files > 50MB
            "old" -> {
                val thirtyDaysAgo = System.currentTimeMillis() - (30L * 24 * 60 * 60 * 1000)
                return file.lastModified() < thirtyDaysAgo
            }
            "duplicates" -> {
                // For now, just return false. Real duplicate detection needs more logic
                return false
            }
        }
        return true
    }
    
    /**
     * Get file extension
     */
    private fun getFileExtension(file: java.io.File): String {
        val name = file.name
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0) name.substring(lastDot) else ""
    }
    
    /**
     * Get MIME type for file
     */
    private fun getMimeType(file: java.io.File): String {
        val extension = getFileExtension(file).lowercase()
        return when (extension) {
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp" -> "image/*"
            ".mp4", ".avi", ".mkv", ".mov", ".wmv" -> "video/*"
            ".mp3", ".wav", ".flac", ".aac", ".ogg" -> "audio/*"
            ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx" -> "document/*"
            ".apk" -> "application/vnd.android.package-archive"
            ".zip", ".rar", ".7z" -> "application/zip"
            else -> "application/octet-stream"
        }
    }
    
    /**
     * Delete multiple files
     * Returns number of successfully deleted files
     */
    private fun deleteFiles(filePaths: List<String>): Int {
        var deletedCount = 0
        
        for (path in filePaths) {
            try {
                val file = java.io.File(path)
                if (file.exists() && file.canWrite()) {
                    if (file.delete()) {
                        deletedCount++
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        return deletedCount
    }
}