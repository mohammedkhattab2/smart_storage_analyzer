package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

class StorageAnalyzer(private val context: Context) {
    companion object {
        private const val TAG = "StorageAnalyzer"
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
     * Perform deep storage analysis using MediaStore & accessible directories
     */
    fun analyzeStorage(
        quickScan: Boolean = false,
        skipDuplicates: Boolean = false,
        skipLargeFiles: Boolean = false,
        cacheOnly: Boolean = false
    ): AnalysisResult {
        android.util.Log.d(TAG, "Starting storage analysis (quickScan=$quickScan, skipDuplicates=$skipDuplicates, skipLargeFiles=$skipLargeFiles, cacheOnly=$cacheOnly)")

        val cacheFiles = mutableListOf<Map<String, Any>>()
        val tempFiles = mutableListOf<Map<String, Any>>()
        val thumbnails = mutableListOf<Map<String, Any>>()
        val largeOldFiles = mutableListOf<Map<String, Any>>()
        val duplicateFiles = mutableListOf<Map<String, Any>>()

        // Collect all available media & files from MediaStore
        val allMediaFiles = collectAllMediaStoreFiles()
        android.util.Log.d(TAG, "Total raw files collected from MediaStore: ${allMediaFiles.size}")

        // 1. Process Large & Old Files
        if (!skipLargeFiles && !cacheOnly) {
            processLargeAndOldFiles(allMediaFiles, largeOldFiles)
            android.util.Log.d(TAG, "Large & Old files identified: ${largeOldFiles.size}")
        }

        // 2. Process Duplicates
        if (!skipDuplicates && !cacheOnly) {
            processDuplicateFiles(allMediaFiles, duplicateFiles)
            android.util.Log.d(TAG, "Duplicates identified: ${duplicateFiles.size}")
        }

        // 3. Process Thumbnails
        processThumbnails(allMediaFiles, thumbnails)
        android.util.Log.d(TAG, "Thumbnails identified: ${thumbnails.size}")

        // 4. Process Cache & Temporary Files
        processCacheAndTempFiles(allMediaFiles, cacheFiles, tempFiles)
        android.util.Log.d(TAG, "Cache files: ${cacheFiles.size}, Temp files: ${tempFiles.size}")

        val totalFilesScanned = cacheFiles.size + tempFiles.size + thumbnails.size + duplicateFiles.size + largeOldFiles.size

        val totalCleanupPotential =
            cacheFiles.sumOf { (it["size"] as? Number)?.toLong() ?: 0L } +
            tempFiles.sumOf { (it["size"] as? Number)?.toLong() ?: 0L } +
            thumbnails.sumOf { (it["size"] as? Number)?.toLong() ?: 0L } +
            duplicateFiles.sumOf { (it["size"] as? Number)?.toLong() ?: 0L }

        // Get storage metrics
        val stat = android.os.StatFs(Environment.getExternalStorageDirectory().path)
        val totalSpace = stat.blockSizeLong * stat.blockCountLong
        val availableSpace = stat.blockSizeLong * stat.availableBlocksLong
        val usedSpace = totalSpace - availableSpace

        android.util.Log.d(TAG, "Analysis finished. Scanned $totalFilesScanned files, Cleanup potential: $totalCleanupPotential bytes")

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
     * Collect all files across Images, Videos, Audio, Downloads, and Files tables
     */
    private fun collectAllMediaStoreFiles(): List<Map<String, Any>> {
        val contentResolver = context.contentResolver
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_MODIFIED
        )

        val targetUris = mutableListOf(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Files.getContentUri("external")
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            targetUris.add(MediaStore.Downloads.EXTERNAL_CONTENT_URI)
        }

        val allFiles = mutableListOf<Map<String, Any>>()
        val seenPaths = mutableSetOf<String>()

        for (uri in targetUris) {
            try {
                contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                    val idCol = cursor.getColumnIndex(MediaStore.MediaColumns._ID)
                    val nameCol = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                    val dataCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                    val sizeCol = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                    val dateCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED)

                    while (cursor.moveToNext()) {
                        val size = if (sizeCol >= 0) cursor.getLong(sizeCol) else 0L
                        val path = if (dataCol >= 0) cursor.getString(dataCol) ?: "" else ""
                        val name = if (nameCol >= 0) cursor.getString(nameCol) ?: File(path).name else File(path).name
                        val id = if (idCol >= 0) cursor.getLong(idCol).toString() else ""
                        val rawDate = if (dateCol >= 0) cursor.getLong(dateCol) else 0L
                        // MediaStore date_modified is in seconds, convert to milliseconds
                        val date = if (rawDate > 100000000000L) rawDate else rawDate * 1000L

                        val finalPath = if (path.isNotEmpty()) path else "/storage/emulated/0/$name"
                        val effectiveKey = finalPath
                        if (seenPaths.contains(effectiveKey)) continue
                        seenPaths.add(effectiveKey)

                        allFiles.add(
                            mapOf(
                                "id" to (if (id.isNotEmpty()) id else effectiveKey.hashCode().toString()),
                                "name" to name,
                                "path" to finalPath,
                                "size" to size,
                                "lastModified" to (if (date > 0) date else System.currentTimeMillis()),
                                "extension" to getExtension(name)
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error collecting files from $uri: ${e.message}")
            }
        }

        return allFiles
    }

    /**
     * Categorize Large (> 10MB) or Old (> 14 days and > 1MB) files
     */
    private fun processLargeAndOldFiles(
        allFiles: List<Map<String, Any>>,
        largeOldFiles: MutableList<Map<String, Any>>
    ) {
        val now = System.currentTimeMillis()
        val oldThresholdMillis = now - (14L * 24 * 60 * 60 * 1000L) // 14 days

        for (file in allFiles) {
            val size = (file["size"] as? Number)?.toLong() ?: 0L
            val lastModified = (file["lastModified"] as? Number)?.toLong() ?: 0L

            val isLarge = size >= (10 * 1024 * 1024L) // >= 10MB
            val isOld = (size >= 1 * 1024 * 1024L) && (lastModified < oldThresholdMillis) // >= 1MB & older than 14 days

            if (isLarge || isOld) {
                largeOldFiles.add(file)
            }
        }

        // Sort descending by size
        largeOldFiles.sortByDescending { (it["size"] as? Number)?.toLong() ?: 0L }
    }

    /**
     * Categorize exact duplicate files
     */
    private fun processDuplicateFiles(
        allFiles: List<Map<String, Any>>,
        duplicateFiles: MutableList<Map<String, Any>>
    ) {
        val sizeMap = mutableMapOf<Long, MutableList<Map<String, Any>>>()

        for (file in allFiles) {
            val size = (file["size"] as? Number)?.toLong() ?: 0L
            if (size >= 10240) { // >= 10KB
                sizeMap.getOrPut(size) { mutableListOf() }.add(file)
            }
        }

        for ((_, group) in sizeMap) {
            if (group.size < 2) continue

            val hashGroups = mutableMapOf<String, MutableList<Map<String, Any>>>()
            for (fileItem in group) {
                val path = fileItem["path"] as? String ?: ""
                val idStr = fileItem["id"] as? String ?: ""
                val hash = calculateQuickHash(path, idStr) ?: fileItem["name"] as? String ?: ""
                hashGroups.getOrPut(hash) { mutableListOf() }.add(fileItem)
            }

            for ((_, matchingFiles) in hashGroups) {
                if (matchingFiles.size > 1) {
                    matchingFiles.sortBy { (it["lastModified"] as? Long) ?: 0L }
                    val dupes = matchingFiles.drop(1)
                    duplicateFiles.addAll(dupes)
                }
            }
        }
    }

    /**
     * Categorize Thumbnails
     */
    private fun processThumbnails(
        allFiles: List<Map<String, Any>>,
        thumbnails: MutableList<Map<String, Any>>
    ) {
        val seen = mutableSetOf<String>()

        for (file in allFiles) {
            val name = (file["name"] as? String ?: "").lowercase()
            val path = (file["path"] as? String ?: "").lowercase()
            val size = (file["size"] as? Number)?.toLong() ?: 0L

            val isThumbnail =
                (size > 0 && size <= 100 * 1024 && (name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp"))) &&
                (name.contains("thumb") || path.contains("thumb") || name.contains("preview") ||
                 name.contains("icon") || name.contains("cover") || name.startsWith(".") ||
                 name.endsWith(".thm") || path.contains("/.thumbnails/") || path.contains("/thumbnails/"))

            if (isThumbnail) {
                val p = file["path"] as? String ?: ""
                if (p.isNotEmpty() && !seen.contains(p)) {
                    seen.add(p)
                    thumbnails.add(file)
                }
            }
        }

        // Direct directory scan for dedicated .thumbnails folders
        val publicDirs = listOf(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        )
        for (pDir in publicDirs) {
            val thumbDir = File(pDir, ".thumbnails")
            if (thumbDir.exists() && thumbDir.canRead()) {
                scanDirectoryFiles(thumbDir, thumbnails)
            }
        }
    }

    /**
     * Categorize Cache & Temporary files
     */
    private fun processCacheAndTempFiles(
        allFiles: List<Map<String, Any>>,
        cacheFiles: MutableList<Map<String, Any>>,
        tempFiles: MutableList<Map<String, Any>>
    ) {
        val seen = mutableSetOf<String>()

        for (file in allFiles) {
            val name = (file["name"] as? String ?: "").lowercase()
            val path = (file["path"] as? String ?: "").lowercase()
            val size = (file["size"] as? Number)?.toLong() ?: 0L

            if (size <= 0) continue

            val isTemp = name.endsWith(".apk") || name.endsWith(".tmp") ||
                         name.endsWith(".temp") || name.endsWith(".crdownload") ||
                         name.endsWith(".part") || name.endsWith(".log") ||
                         name.endsWith(".bak") || name.startsWith(".pending") ||
                         name.startsWith("temp_") || name.startsWith("tmp_")

            val isCache = path.contains("/cache/") || path.contains("/.cache/") ||
                          path.contains("/temp/") || path.contains("/tmp/") ||
                          path.contains("/whatsapp/.shared/") || path.contains("/.statuses/") ||
                          name.endsWith(".nomedia") || name.contains("cache_")

            val p = file["path"] as? String ?: ""
            if (p.isNotEmpty() && !seen.contains(p)) {
                if (isTemp) {
                    seen.add(p)
                    tempFiles.add(file)
                } else if (isCache) {
                    seen.add(p)
                    cacheFiles.add(file)
                }
            }
        }

        // Add application internal & external cache directory files
        scanDirectoryFiles(context.cacheDir, cacheFiles)
        context.externalCacheDir?.let { scanDirectoryFiles(it, cacheFiles) }
        context.codeCacheDir?.let { scanDirectoryFiles(it, cacheFiles) }

        // Scan accessible WhatsApp Statuses cache
        val waDirs = listOf(
            File(Environment.getExternalStorageDirectory(), "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"),
            File(Environment.getExternalStorageDirectory(), "WhatsApp/Media/.Statuses")
        )
        for (waDir in waDirs) {
            if (waDir.exists() && waDir.canRead()) {
                scanDirectoryFiles(waDir, cacheFiles)
            }
        }
    }

    /**
     * Calculate quick MD5 hash of first 4KB using ContentResolver (works with Scoped Storage)
     */
    private fun calculateQuickHash(path: String, idStr: String): String? {
        if (idStr.isNotEmpty()) {
            try {
                val idLong = idStr.toLongOrNull()
                if (idLong != null) {
                    val contentUri = ContentUris.withAppendedId(MediaStore.Files.getContentUri("external"), idLong)
                    context.contentResolver.openInputStream(contentUri)?.use { input ->
                        val digest = MessageDigest.getInstance("MD5")
                        val buffer = ByteArray(4096)
                        val bytesRead = input.read(buffer)
                        if (bytesRead > 0) {
                            digest.update(buffer, 0, bytesRead)
                            return digest.digest().joinToString("") { "%02x".format(it) }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore and try fallback
            }
        }

        if (path.isNotEmpty()) {
            try {
                val file = File(path)
                if (file.exists() && file.canRead()) {
                    FileInputStream(file).use { input ->
                        val digest = MessageDigest.getInstance("MD5")
                        val buffer = ByteArray(4096)
                        val bytesRead = input.read(buffer)
                        if (bytesRead > 0) {
                            digest.update(buffer, 0, bytesRead)
                            return digest.digest().joinToString("") { "%02x".format(it) }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }

        return null
    }

    /**
     * Scan physical directory files (app cache / local folders)
     */
    private fun scanDirectoryFiles(directory: File, targetList: MutableList<Map<String, Any>>) {
        if (!directory.exists() || !directory.canRead()) return
        try {
            directory.listFiles()?.forEach { file ->
                if (file.isFile && file.length() > 0) {
                    val path = file.absolutePath
                    if (targetList.none { it["path"] == path }) {
                        targetList.add(
                            mapOf(
                                "id" to path.hashCode().toString(),
                                "name" to file.name,
                                "path" to path,
                                "size" to file.length(),
                                "lastModified" to file.lastModified(),
                                "extension" to getExtension(file.name)
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore permission errors
        }
    }

    private fun getExtension(name: String): String {
        val lastDot = name.lastIndexOf('.')
        return if (lastDot > 0 && lastDot < name.length - 1) {
            name.substring(lastDot).lowercase()
        } else ""
    }
}