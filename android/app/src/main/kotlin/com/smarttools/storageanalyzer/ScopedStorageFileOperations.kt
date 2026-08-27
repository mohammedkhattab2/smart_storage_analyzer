package com.smarttools.storageanalyzer

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class ScopedStorageFileOperations(private val context: Context) {
    companion object {
        private const val TAG = "ScopedStorageFileOperations"
    }

    /**
     * Find the MediaStore Content URI for a given file path
     */
    fun findMediaStoreUri(path: String): Uri? {
        if (path.startsWith("content://")) {
            return Uri.parse(path)
        }
        val file = File(path)
        val fileName = file.name
        val collections = mutableListOf(
            MediaStore.Files.getContentUri("external"),
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            collections.add(MediaStore.Downloads.EXTERNAL_CONTENT_URI)
        }

        for (collectionUri in collections) {
            try {
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                
                // 1. Try match by _DATA
                context.contentResolver.query(
                    collectionUri,
                    projection,
                    "${MediaStore.MediaColumns.DATA} = ?",
                    arrayOf(path),
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                        return ContentUris.withAppendedId(collectionUri, id)
                    }
                }

                // 2. Try match by DISPLAY_NAME
                context.contentResolver.query(
                    collectionUri,
                    projection,
                    "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
                    arrayOf(fileName),
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                        return ContentUris.withAppendedId(collectionUri, id)
                    }
                }
            } catch (e: Exception) {
                // Ignore query exceptions
            }
        }
        return null
    }

    /**
     * Delete files using direct file API and MediaStore fallback
     */
    suspend fun deleteFiles(filePaths: List<String>): Int = withContext(Dispatchers.IO) {
        var deletedCount = 0
        val contentResolver = context.contentResolver

        for (path in filePaths) {
            if (path.isEmpty()) continue

            try {
                var deleted = false

                // Method 1: Direct File deletion
                try {
                    val file = File(path)
                    if (file.exists() && file.delete()) {
                        deleted = true
                    }
                } catch (e: Exception) {
                    // Ignore
                }

                // Method 2: MediaStore delete from collections
                if (!deleted) {
                    deleted = deleteFromAllMediaStoreCollections(path, contentResolver)
                }

                // Method 3: Content URI parsing if path is URI
                if (!deleted && path.startsWith("content://")) {
                    try {
                        val uri = Uri.parse(path)
                        if (contentResolver.delete(uri, null, null) > 0) {
                            deleted = true
                        }
                    } catch (e: Exception) {
                        // Ignore
                    }
                }

                if (deleted) {
                    deletedCount++
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error deleting file $path: ${e.message}")
            }
        }

        deletedCount
    }

    private fun deleteFromAllMediaStoreCollections(path: String, contentResolver: ContentResolver): Boolean {
        val fileName = File(path).name
        val collections = mutableListOf(
            MediaStore.Files.getContentUri("external"),
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            collections.add(MediaStore.Downloads.EXTERNAL_CONTENT_URI)
        }

        for (collectionUri in collections) {
            try {
                // Try 1: By _DATA column
                val deletedByData = contentResolver.delete(
                    collectionUri,
                    "${MediaStore.MediaColumns.DATA} = ?",
                    arrayOf(path)
                )
                if (deletedByData > 0) {
                    return true
                }

                // Try 2: By DISPLAY_NAME column
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                contentResolver.query(
                    collectionUri,
                    projection,
                    "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
                    arrayOf(fileName),
                    null
                )?.use { cursor ->
                    val idCol = cursor.getColumnIndex(MediaStore.MediaColumns._ID)
                    while (cursor.moveToNext()) {
                        if (idCol >= 0) {
                            val id = cursor.getLong(idCol)
                            val itemUri = ContentUris.withAppendedId(collectionUri, id)
                            try {
                                if (contentResolver.delete(itemUri, null, null) > 0) {
                                    return true
                                }
                            } catch (e: Exception) {
                                // Ignore
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }

        return false
    }
}