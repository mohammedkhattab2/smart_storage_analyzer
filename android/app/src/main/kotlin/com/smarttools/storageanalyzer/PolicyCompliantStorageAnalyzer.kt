package com.smarttools.storageanalyzer

import android.app.usage.StorageStats
import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import java.io.File
import java.util.UUID

/**
 * Policy-compliant storage analyzer that does NOT require READ_MEDIA_IMAGES,
 * READ_MEDIA_VIDEO, or any broad media access permissions.
 * 
 * Uses:
 * - StorageStatsManager for app storage statistics (Android 8.0+)
 * - StatFs for overall storage information
 * - Package manager for installed app information
 * 
 * This complies with Google Play's Photo and Video Permissions policy
 * for storage analyzer apps that don't need to access individual media files.
 */
class PolicyCompliantStorageAnalyzer(private val context: Context) {
    
    companion object {
        private const val TAG = "PolicyCompliantStorageAnalyzer"
    }
    
    private val storageStatsManager: StorageStatsManager? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.getSystemService(Context.STORAGE_STATS_SERVICE) as? StorageStatsManager
        } else {
            null
        }
    }
    
    private val storageManager: StorageManager by lazy {
        context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
    }
    
    private val packageManager: PackageManager by lazy {
        context.packageManager
    }
    
    /**
     * Get overall storage information using StatFs (no permissions required)
     */
    fun getStorageInfo(): Map<String, Long> {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong
            
            val totalSpace = totalBlocks * blockSize
            val availableSpace = availableBlocks * blockSize
            val usedSpace = totalSpace - availableSpace
            
            mapOf(
                "totalSpace" to totalSpace,
                "availableSpace" to availableSpace,
                "usedSpace" to usedSpace
            )
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error getting storage info", e)
            mapOf(
                "totalSpace" to 0L,
                "availableSpace" to 0L,
                "usedSpace" to 0L
            )
        }
    }
    
    /**
     * Get storage breakdown by category using StorageStatsManager
     * This provides estimated sizes without accessing individual files
     */
    fun getCategoryEstimates(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        try {
            val storageInfo = getStorageInfo()
            val totalUsed = storageInfo["usedSpace"] ?: 0L
            
            // Get app storage statistics
            val appStats = getAppStorageStats()
            val totalAppSize = appStats.sumOf { (it["size"] as? Long) ?: 0L }
            val totalCacheSize = appStats.sumOf { (it["cacheSize"] as? Long) ?: 0L }
            
            // Calculate system and other storage
            val systemSize = estimateSystemSize()
            val remainingSize = maxOf(0L, totalUsed - totalAppSize - systemSize)
            
            // Estimate media categories based on typical distribution
            // These are estimates since we can't access individual files
            val mediaEstimate = estimateMediaDistribution(remainingSize)
            
            result["apps_size"] = totalAppSize
            result["apps_count"] = appStats.size
            result["cache_size"] = totalCacheSize
            result["system_size"] = systemSize
            result["images_size"] = mediaEstimate["images"] ?: 0L
            result["images_count"] = 0 // Cannot count without media permission
            result["videos_size"] = mediaEstimate["videos"] ?: 0L
            result["videos_count"] = 0
            result["audio_size"] = mediaEstimate["audio"] ?: 0L
            result["audio_count"] = 0
            result["documents_size"] = mediaEstimate["documents"] ?: 0L
            result["documents_count"] = 0
            result["others_size"] = mediaEstimate["others"] ?: 0L
            result["others_count"] = 0
            
            // Flag indicating this is an estimate (no media access)
            result["isEstimate"] = true
            result["policyCompliant"] = true
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error getting category estimates", e)
        }
        
        return result
    }
    
    /**
     * Get storage statistics for all installed apps
     * Requires PACKAGE_USAGE_STATS permission (granted via Settings)
     */
    fun getAppStorageStats(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        
        try {
            val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getInstalledApplications(
                    PackageManager.ApplicationInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstalledApplications(0)
            }
            
            for (appInfo in packages) {
                try {
                    // Skip system apps that aren't updated
                    if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                        (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                        continue
                    }
                    
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    var appSize = 0L
                    var cacheSize = 0L
                    var dataSize = 0L
                    
                    // Try to get storage stats using StorageStatsManager (Android 8.0+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && storageStatsManager != null) {
                        try {
                            val storageStats = storageStatsManager!!.queryStatsForPackage(
                                StorageManager.UUID_DEFAULT,
                                appInfo.packageName,
                                android.os.Process.myUserHandle()
                            )
                            appSize = storageStats.appBytes + storageStats.dataBytes + storageStats.cacheBytes
                            cacheSize = storageStats.cacheBytes
                            dataSize = storageStats.dataBytes
                        } catch (e: Exception) {
                            // Fall back to APK size if stats not available
                            val apkFile = File(appInfo.sourceDir)
                            appSize = if (apkFile.exists()) apkFile.length() else 0L
                        }
                    } else {
                        // For older Android versions, use APK file size
                        val apkFile = File(appInfo.sourceDir)
                        appSize = if (apkFile.exists()) apkFile.length() else 0L
                    }
                    
                    if (appSize > 0) {
                        apps.add(mapOf(
                            "id" to appInfo.packageName,
                            "name" to "$appName",
                            "packageName" to appInfo.packageName,
                            "size" to appSize,
                            "cacheSize" to cacheSize,
                            "dataSize" to dataSize,
                            "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                            "path" to "app://${appInfo.packageName}",
                            "extension" to ".apk",
                            "mimeType" to "application/vnd.android.package-archive"
                        ))
                    }
                } catch (e: Exception) {
                    // Skip apps that can't be analyzed
                    android.util.Log.w(TAG, "Could not analyze app: ${appInfo.packageName}", e)
                }
            }
            
            // Sort by size descending
            apps.sortByDescending { (it["size"] as? Long) ?: 0L }
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error getting app storage stats", e)
        }
        
        return apps
    }
    
    /**
     * Get cache files that can be cleaned (app's own cache only)
     * We can only access our own app's cache without special permissions
     */
    fun getCleanableCache(): List<Map<String, Any>> {
        val cacheFiles = mutableListOf<Map<String, Any>>()
        
        try {
            // Scan our own app's cache directory
            val cacheDir = context.cacheDir
            scanDirectoryForCache(cacheDir, cacheFiles)
            
            // Scan external cache if available
            context.externalCacheDir?.let { externalCache ->
                scanDirectoryForCache(externalCache, cacheFiles)
            }
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error getting cleanable cache", e)
        }
        
        return cacheFiles
    }
    
    /**
     * Scan directory for cache files
     */
    private fun scanDirectoryForCache(
        directory: File,
        cacheFiles: MutableList<Map<String, Any>>,
        depth: Int = 0,
        maxDepth: Int = 3
    ) {
        if (depth > maxDepth || !directory.exists() || !directory.canRead()) return
        
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile) {
                    cacheFiles.add(mapOf(
                        "id" to file.absolutePath.hashCode().toString(),
                        "name" to file.name,
                        "path" to file.absolutePath,
                        "size" to file.length(),
                        "lastModified" to file.lastModified(),
                        "extension" to getExtension(file.name)
                    ))
                } else if (file.isDirectory && file.canRead()) {
                    scanDirectoryForCache(file, cacheFiles, depth + 1, maxDepth)
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }
    
    /**
     * Estimate system storage size
     */
    private fun estimateSystemSize(): Long {
        return try {
            // System partition size estimation
            val systemStat = StatFs("/system")
            val systemUsed = (systemStat.blockCountLong - systemStat.availableBlocksLong) * systemStat.blockSizeLong
            systemUsed
        } catch (e: Exception) {
            // Default estimate: 5GB for system
            5L * 1024 * 1024 * 1024
        }
    }
    
    /**
     * Estimate media distribution based on typical usage patterns
     * This is used when we don't have media access permissions
     */
    private fun estimateMediaDistribution(totalMediaSize: Long): Map<String, Long> {
        // Typical distribution based on average user data:
        // Images: 30%, Videos: 45%, Audio: 15%, Documents: 5%, Others: 5%
        return mapOf(
            "images" to (totalMediaSize * 0.30).toLong(),
            "videos" to (totalMediaSize * 0.45).toLong(),
            "audio" to (totalMediaSize * 0.15).toLong(),
            "documents" to (totalMediaSize * 0.05).toLong(),
            "others" to (totalMediaSize * 0.05).toLong()
        )
    }
    
    /**
     * Perform storage analysis without media permissions
     */
    fun analyzeStorage(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        try {
            val storageInfo = getStorageInfo()
            val categoryEstimates = getCategoryEstimates()
            val appStats = getAppStorageStats()
            val cleanableCache = getCleanableCache()
            
            result["totalSpace"] = storageInfo["totalSpace"] ?: 0L
            result["availableSpace"] = storageInfo["availableSpace"] ?: 0L
            result["usedSpace"] = storageInfo["usedSpace"] ?: 0L
            
            result["categories"] = categoryEstimates
            result["apps"] = appStats
            result["cleanableCache"] = cleanableCache
            result["totalCleanupPotential"] = cleanableCache.sumOf { (it["size"] as? Long) ?: 0L }
            
            // Metadata
            result["analysisType"] = "policy_compliant"
            result["hasMediaAccess"] = false
            result["timestamp"] = System.currentTimeMillis()
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error analyzing storage", e)
        }
        
        return result
    }
    
    /**
     * Get file extension from name
     */
    private fun getExtension(name: String): String {
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0 && lastDot < name.length - 1) {
            name.substring(lastDot).lowercase()
        } else ""
    }
    
    /**
     * Check if usage stats permission is granted
     */
    fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            }
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }
}