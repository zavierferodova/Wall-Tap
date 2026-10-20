package com.zavierdev.walltap

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val ENGINE_ID = "walltap_flutter_engine"
        private const val CHANNEL = "com.walltap.app/wallpaper"
        private var activeChannel: MethodChannel? = null

        fun notifyWidgetSync(context: Context) {
            Handler(Looper.getMainLooper()).post {
                try {
                    activeChannel?.invokeMethod("onWidgetSync", null)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private val CHANNEL = "com.walltap.app/wallpaper"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val REQUEST_CODE_PICK_FOLDER = 9921
    private var pendingFolderResult: MethodChannel.Result? = null

    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun shouldDestroyEngineWithHost(): Boolean = !isChangingConfigurations

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(ENGINE_ID)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (!isChangingConfigurations) {
            activeChannel = null
            FlutterEngineCache.getInstance().remove(ENGINE_ID)
            super.cleanUpFlutterEngine(flutterEngine)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        activeChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val targetScreen = call.argument<String>("targetScreen") ?: "both"
                    val scaleType = call.argument<String>("scaleType") ?: "full"

                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath cannot be null", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        val success = WallpaperHelper.setDeviceWallpaper(
                            context = applicationContext,
                            imagePath = filePath,
                            targetScreen = targetScreen,
                            scaleType = scaleType
                        )
                        if (success) {
                            WidgetProvider.updateAllWidgets(applicationContext)
                        }
                        mainHandler.post {
                            result.success(success)
                        }
                    }
                }
                "updateWidget" -> {
                    WidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                }
                "getDisplayDimensions" -> {
                    val (w, h) = WallpaperHelper.getDisplayDimensions(applicationContext)
                    result.success(mapOf("width" to w, "height" to h))
                }
                "updateSchedule" -> {
                    val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 0
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putLong("flutter.walltap_interval_minutes", intervalMinutes.toLong()).apply()
                    Scheduler.schedule(applicationContext, intervalMinutes)
                    WidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                }
                "isBatteryOptimizationIgnored" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                    } else {
                        true
                    }
                    result.success(isIgnored)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("SETTINGS_ERROR", e2.localizedMessage, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "pickFolderAndGetImages" -> {
                    if (pendingFolderResult != null) {
                        result.error("ALREADY_PICKING", "A folder picking operation is already in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingFolderResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        startActivityForResult(intent, REQUEST_CODE_PICK_FOLDER)
                    } catch (e: Exception) {
                        pendingFolderResult = null
                        result.error("PICK_ERROR", e.localizedMessage, null)
                    }
                }
                "getAlbumWidgets" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                    val thisWidget = ComponentName(applicationContext, AlbumWidgetProvider::class.java)
                    val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                    val widgetList = mutableListOf<Map<String, Any>>()
                    for (widgetId in allWidgetIds) {
                        val albumId = prefs.getString("flutter.album_widget_${widgetId}_album_id", "all_photos") ?: "all_photos"
                        val (resolvedName, paths) = AlbumWidgetProvider.getAlbumImagePaths(applicationContext, albumId)
                        val savedName = prefs.getString("flutter.album_widget_${widgetId}_album_name", null)
                        val albumName = if (!savedName.isNullOrEmpty()) savedName else resolvedName
                        val intervalMinutes = prefs.getLong("flutter.album_widget_${widgetId}_interval_minutes", 0L).toInt()
                        val isRandom = prefs.getBoolean("flutter.album_widget_${widgetId}_is_random", true)
                        val rawIndex = prefs.getLong("flutter.album_widget_${widgetId}_current_index", 0L).toInt()
                        val safeIndex = if (paths.isNotEmpty() && rawIndex in paths.indices) rawIndex else 0
                        if (rawIndex != safeIndex && paths.isNotEmpty()) {
                            prefs.edit().putLong("flutter.album_widget_${widgetId}_current_index", safeIndex.toLong()).apply()
                        }
                        val lastPath = prefs.getString("flutter.album_widget_${widgetId}_last_path", null)
                        val currentImagePath = if (!lastPath.isNullOrEmpty() && File(lastPath).exists()) {
                            lastPath
                        } else if (paths.isNotEmpty()) {
                            paths[safeIndex]
                        } else {
                            ""
                        }

                        widgetList.add(mapOf(
                            "widgetId" to widgetId,
                            "albumId" to albumId,
                            "albumName" to albumName,
                            "intervalMinutes" to intervalMinutes,
                            "isRandom" to isRandom,
                            "currentIndex" to safeIndex,
                            "currentImagePath" to currentImagePath,
                            "totalImages" to paths.size
                        ))
                    }
                    result.success(widgetList)
                }
                "updateAlbumWidget" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    val albumId = call.argument<String>("albumId") ?: "all_photos"
                    val albumName = call.argument<String>("albumName") ?: "Album"
                    val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 0
                    val isRandom = call.argument<Boolean>("isRandom") ?: false

                    if (widgetId == null) {
                        result.error("INVALID_ARGUMENT", "widgetId cannot be null", null)
                        return@setMethodCallHandler
                    }

                    val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.album_widget_${widgetId}_album_id", albumId)
                        .putString("flutter.album_widget_${widgetId}_album_name", albumName)
                        .putLong("flutter.album_widget_${widgetId}_interval_minutes", intervalMinutes.toLong())
                        .putBoolean("flutter.album_widget_${widgetId}_is_random", isRandom)
                        .apply()

                    val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                    AlbumWidgetProvider.updateWidget(applicationContext, appWidgetManager, widgetId)
                    AlbumWidgetScheduler.schedule(applicationContext, widgetId, intervalMinutes)
                    result.success(true)
                }
                "shuffleAlbumWidget" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    if (widgetId == null) {
                        result.error("INVALID_ARGUMENT", "widgetId cannot be null", null)
                        return@setMethodCallHandler
                    }
                    AlbumWidgetProvider.advanceWidget(applicationContext, widgetId)
                    result.success(true)
                }
                "updateAllAlbumWidgets" -> {
                    AlbumWidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_FOLDER) {
            val result = pendingFolderResult
            pendingFolderResult = null
            if (resultCode != Activity.RESULT_OK || data == null || data.data == null) {
                result?.success(emptyList<String>())
                return
            }

            val treeUri = data.data!!
            try {
                val takeFlags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION)
                contentResolver.takePersistableUriPermission(treeUri, takeFlags)
            } catch (e: Exception) {
                // Ignore if persistable grant not permitted by provider
            }

            executor.execute {
                val copiedPaths = mutableListOf<String>()
                try {
                    val rootDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                    if (rootDir != null && rootDir.exists()) {
                        scanAndCopyImages(rootDir, copiedPaths)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                mainHandler.post {
                    result?.success(copiedPaths)
                }
            }
        }
    }

    private fun scanAndCopyImages(dir: DocumentFile, outList: MutableList<String>) {
        val supportedExtensions = setOf("jpg", "jpeg", "png", "webp", "bmp")
        val cacheFolder = File(cacheDir, "picked_folder_images").apply { mkdirs() }

        val files = dir.listFiles()
        for (file in files) {
            // Only import files directly in the selected directory; do NOT recurse into subdirectories
            if (!file.isDirectory) {
                val name = file.name ?: ""
                val ext = name.substringAfterLast('.', "").lowercase()
                val isImage = (file.type?.startsWith("image/") == true) || supportedExtensions.contains(ext)
                if (isImage) {
                    try {
                        val safeExt = if (ext.isNotEmpty()) ext else "jpg"
                        val destFile = File(cacheFolder, "img_${UUID.randomUUID()}.$safeExt")
                        contentResolver.openInputStream(file.uri)?.use { input ->
                            FileOutputStream(destFile).use { output ->
                                input.copyTo(output)
                            }
                        }
                        if (destFile.exists() && destFile.length() > 0) {
                            outList.add(destFile.absolutePath)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }
}
