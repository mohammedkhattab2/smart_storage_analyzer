package com.smarttools.storageanalyzer

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import java.io.File

class FileOperations(private val context: Context) {
    
    companion object {
        private const val AUTHORITY = "com.smarttools.storageanalyzer.fileprovider"
    }
    
    /**
     * Open a file using appropriate app
     */
    fun openFile(filePath: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                android.util.Log.e("FileOperations", "File does not exist: $filePath")
                return false
            }
            
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(context, AUTHORITY, file)
            } else {
                Uri.fromFile(file)
            }
            
            val extension = file.extension
            val mimeType = getMimeType(extension)
            
            android.util.Log.d("FileOperations", "Opening file: $filePath with MIME type: $mimeType")
            
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                
                // Add extra flags for better compatibility
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                
                // For documents, add EXTRA_ALLOW_MULTIPLE flag
                if (isDocument(extension)) {
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
            }
            
            return try {
                // Try to open directly first
                context.startActivity(intent)
                android.util.Log.d("FileOperations", "Successfully opened file with default app")
                true
            } catch (e: android.content.ActivityNotFoundException) {
                android.util.Log.w("FileOperations", "No default app found, showing chooser")
                // If no default app, show chooser
                val chooserIntent = Intent.createChooser(intent, "Open with")
                chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                
                try {
                    context.startActivity(chooserIntent)
                    android.util.Log.d("FileOperations", "Opened file with chooser")
                    true
                } catch (ex: Exception) {
                    android.util.Log.e("FileOperations", "Failed to open file even with chooser: ${ex.message}")
                    // As last resort, try share intent
                    shareFile(filePath)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("FileOperations", "Error opening file: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Check if the file extension is a document type
     */
    private fun isDocument(extension: String): Boolean {
        return when (extension.lowercase()) {
            "pdf", "doc", "docx", "txt", "rtf", "xls", "xlsx",
            "ppt", "pptx", "csv", "odt", "ods", "odp",
            "html", "htm", "xml", "json" -> true
            else -> false
        }
    }
    
    /**
     * Share file using Android Share Sheet
     */
    fun shareFile(filePath: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) return false
            
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(context, AUTHORITY, file)
            } else {
                Uri.fromFile(file)
            }
            
            val mimeType = getMimeType(file.extension)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            
            val chooserIntent = Intent.createChooser(shareIntent, "Share via")
            chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(chooserIntent)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Share multiple files
     */
    fun shareFiles(filePaths: List<String>): Boolean {
        try {
            val uris = ArrayList<Uri>()
            var mimeType = "*/*"
            val mimeTypes = mutableSetOf<String>()
            
            for (path in filePaths) {
                val file = File(path)
                if (file.exists()) {
                    val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        FileProvider.getUriForFile(context, AUTHORITY, file)
                    } else {
                        Uri.fromFile(file)
                    }
                    uris.add(uri)
                    mimeTypes.add(getMimeType(file.extension))
                }
            }
            
            // If all files have the same mime type, use it. Otherwise use */*
            if (mimeTypes.size == 1) {
                mimeType = mimeTypes.first()
            }
            
            if (uris.isEmpty()) return false
            
            val shareIntent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = mimeType
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            
            val chooserIntent = Intent.createChooser(shareIntent, "Share files via")
            chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(chooserIntent)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Get MIME type from file extension
     */
    private fun getMimeType(extension: String): String {
        return when (extension.lowercase()) {
            // Images
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "bmp" -> "image/bmp"
            "webp" -> "image/webp"
            "svg" -> "image/svg+xml"
            
            // Videos
            "mp4" -> "video/mp4"
            "avi" -> "video/x-msvideo"
            "mkv" -> "video/x-matroska"
            "mov" -> "video/quicktime"
            "wmv" -> "video/x-ms-wmv"
            "flv" -> "video/x-flv"
            "webm" -> "video/webm"
            "3gp" -> "video/3gpp"
            
            // Audio
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/wav"
            "flac" -> "audio/flac"
            "aac" -> "audio/aac"
            "ogg" -> "audio/ogg"
            "wma" -> "audio/x-ms-wma"
            "m4a" -> "audio/m4a"
            
            // Documents
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "txt" -> "text/plain"
            "rtf" -> "application/rtf"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "csv" -> "text/csv"
            
            // Apps
            "apk" -> "application/vnd.android.package-archive"
            
            // Archives
            "zip" -> "application/zip"
            "rar" -> "application/x-rar-compressed"
            "7z" -> "application/x-7z-compressed"
            "tar" -> "application/x-tar"
            "gz" -> "application/gzip"
            
            else -> "*/*"
        }
    }
}