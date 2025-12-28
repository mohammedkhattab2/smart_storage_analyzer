package com.example.smart_storage_analyzer

import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "storage_info_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageInfo" -> {
                    try {
                        val storageInfo = getInternalStorageInfo()
                        result.success(storageInfo)
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", "Failed to get storage info", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInternalStorageInfo(): Map<String, Long> {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        
        val blockSize: Long
        val totalBlocks: Long
        val availableBlocks: Long
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            blockSize = stat.blockSizeLong
            totalBlocks = stat.blockCountLong
            availableBlocks = stat.availableBlocksLong
        } else {
            @Suppress("DEPRECATION")
            blockSize = stat.blockSize.toLong()
            @Suppress("DEPRECATION")
            totalBlocks = stat.blockCount.toLong()
            @Suppress("DEPRECATION")
            availableBlocks = stat.availableBlocks.toLong()
        }
        
        val totalSpace = totalBlocks * blockSize
        val availableSpace = availableBlocks * blockSize
        
        return mapOf(
            "totalSpace" to totalSpace,
            "availableSpace" to availableSpace
        )
    }
}
