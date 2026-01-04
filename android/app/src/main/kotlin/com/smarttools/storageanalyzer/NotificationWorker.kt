package com.smarttools.storageanalyzer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import android.util.Log

class NotificationWorker(
    context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {
    
    companion object {
        const val CHANNEL_ID = "storage_analyzer_channel"
        const val CHANNEL_NAME = "Storage Analyzer"
        const val NOTIFICATION_ID = 1001
        const val TAG = "NotificationWorker"
    }
    
    override fun doWork(): Result {
        Log.d(TAG, "Starting notification work")
        
        try {
            createNotificationChannel()
            showNotification()
            Log.d(TAG, "Notification sent successfully")
            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error sending notification", e)
            return Result.failure()
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                importance
            ).apply {
                description = "Regular reminders to analyze your device storage"
            }
            
            val notificationManager = applicationContext.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager
            
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }
    
    private fun showNotification() {
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Get storage info for the notification
        val storageInfo = getStorageInfo()
        val title = "Time to Clean Your Storage!"
        val text = if (storageInfo.usedPercentage > 80) {
            "Your storage is ${storageInfo.usedPercentage}% full. Free up space now!"
        } else {
            "Keep your device running smoothly. Check for files to clean up."
        }
        
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        val notificationManager = applicationContext.getSystemService(
            Context.NOTIFICATION_SERVICE
        ) as NotificationManager
        
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun getStorageInfo(): StorageInfo {
        return try {
            val path = android.os.Environment.getDataDirectory()
            val stat = android.os.StatFs(path.path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong
            
            val totalSpace = totalBlocks * blockSize
            val availableSpace = availableBlocks * blockSize
            val usedSpace = totalSpace - availableSpace
            val usedPercentage = ((usedSpace.toDouble() / totalSpace) * 100).toInt()
            
            StorageInfo(totalSpace, usedSpace, availableSpace, usedPercentage)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting storage info", e)
            StorageInfo(0, 0, 0, 0)
        }
    }
    
    data class StorageInfo(
        val totalSpace: Long,
        val usedSpace: Long,
        val availableSpace: Long,
        val usedPercentage: Int
    )
}