package com.zavierdev.walltap

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.io.File
import kotlin.random.Random

class AlbumWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_NEXT_ALBUM_IMAGE = "com.walltap.app.ACTION_NEXT_ALBUM_IMAGE"
        const val ACTION_TOGGLE_CONTROLS = "com.walltap.app.ACTION_TOGGLE_ALBUM_CONTROLS"
        const val ACTION_HIDE_CONTROLS = "com.walltap.app.ACTION_HIDE_ALBUM_CONTROLS"
        const val ACTION_OPEN_SETTINGS = "com.walltap.app.ACTION_OPEN_ALBUM_SETTINGS"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, AlbumWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateWidget(context, appWidgetManager, widgetId)
            }
        }

        fun getAlbumImagePaths(context: Context, targetAlbumId: String?): Pair<String, List<String>> {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val itemsJson = prefs.getString("flutter.walltap_items", null)
            val albumsJson = prefs.getString("flutter.walltap_albums", null)

            // Map itemId -> path
            val idToPath = mutableMapOf<String, String>()
            val allPaths = mutableListOf<String>()
            if (!itemsJson.isNullOrEmpty()) {
                try {
                    val itemsArray = JSONArray(itemsJson)
                    for (i in 0 until itemsArray.length()) {
                        val obj = itemsArray.optJSONObject(i) ?: continue
                        val id = obj.optString("id")
                        val path = obj.optString("path")
                        if (id.isNotEmpty() && path.isNotEmpty() && File(path).exists()) {
                            idToPath[id] = path
                            allPaths.add(path)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            if (targetAlbumId == null || targetAlbumId == "all" || targetAlbumId == "all_photos") {
                return Pair("All Photos", allPaths)
            }

            // Find specific album
            var albumName = "Album"
            val albumPaths = mutableListOf<String>()
            if (!albumsJson.isNullOrEmpty()) {
                try {
                    val albumsArray = JSONArray(albumsJson)
                    for (i in 0 until albumsArray.length()) {
                        val albumObj = albumsArray.optJSONObject(i) ?: continue
                        if (albumObj.optString("id") == targetAlbumId) {
                            albumName = albumObj.optString("name", "Album")
                            val wallIds = albumObj.optJSONArray("wallpaperIds")
                            if (wallIds != null) {
                                for (j in 0 until wallIds.length()) {
                                    val wId = wallIds.optString(j)
                                    val path = idToPath[wId]
                                    if (path != null) {
                                        albumPaths.add(path)
                                    }
                                }
                            }
                            break
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Fallback to all paths if album wasn't found or is empty
            if (albumPaths.isEmpty() && allPaths.isNotEmpty() && albumName == "Album") {
                return Pair("All Photos", allPaths)
            }

            return Pair(albumName, albumPaths)
        }

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.album_widget)
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val albumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null)
                val isRandom = prefs.getBoolean("flutter.album_widget_${appWidgetId}_is_random", true)
                val currentIndex = prefs.getLong("flutter.album_widget_${appWidgetId}_current_index", 0L).toInt()
                val showControls = prefs.getBoolean("flutter.album_widget_${appWidgetId}_show_controls", false)

                val (resolvedName, paths) = getAlbumImagePaths(context, albumId)
                val savedName = prefs.getString("flutter.album_widget_${appWidgetId}_album_name", null)
                val displayName = if (!savedName.isNullOrEmpty()) savedName else resolvedName

                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // Configuration intent for empty state fallback
                val configureIntent = Intent(context, AlbumWidgetConfigureActivity::class.java).apply {
                    this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val configurePendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + 2,
                    configureIntent,
                    flags
                )

                if (paths.isEmpty()) {
                    views.setViewVisibility(R.id.widget_album_image, View.GONE)
                    views.setViewVisibility(R.id.widget_album_controls_container, View.GONE)
                    views.setViewVisibility(R.id.widget_album_empty_container, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_album_empty_text,
                        "No photos in $displayName\nTap to configure"
                    )
                    views.setOnClickPendingIntent(R.id.widget_album_empty_container, configurePendingIntent)
                    views.setOnClickPendingIntent(R.id.album_widget_root, configurePendingIntent)
                } else {
                    views.setViewVisibility(R.id.widget_album_empty_container, View.GONE)
                    views.setViewVisibility(R.id.widget_album_image, View.VISIBLE)

                    val safeIndex = if (currentIndex in paths.indices) currentIndex else 0
                    val currentPath = paths[safeIndex]

                    val sampledBitmap = WallpaperHelper.decodeSampledBitmapFromFile(
                        currentPath,
                        400,
                        400,
                        Bitmap.Config.RGB_565
                    )
                    if (sampledBitmap != null) {
                        views.setImageViewBitmap(R.id.widget_album_image, sampledBitmap)
                    } else {
                        views.setImageViewResource(R.id.widget_album_image, android.R.color.transparent)
                    }

                    // Tapping the widget image or root toggles the controls overlay (Settings & Next)
                    val toggleIntent = Intent(context, AlbumWidgetProvider::class.java).apply {
                        action = ACTION_TOGGLE_CONTROLS
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val togglePendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 10 + 1,
                        toggleIntent,
                        flags
                    )
                    views.setOnClickPendingIntent(R.id.widget_album_image, togglePendingIntent)
                    views.setOnClickPendingIntent(R.id.album_widget_root, togglePendingIntent)

                    // Controls overlay visibility
                    views.setViewVisibility(
                        R.id.widget_album_controls_container,
                        if (showControls) View.VISIBLE else View.GONE
                    )

                    // Settings button intent: opens configuration activity & closes controls
                    val settingsIntent = Intent(context, AlbumWidgetProvider::class.java).apply {
                        action = ACTION_OPEN_SETTINGS
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val settingsPendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 10 + 4,
                        settingsIntent,
                        flags
                    )
                    views.setOnClickPendingIntent(R.id.btn_album_widget_settings, settingsPendingIntent)

                    // Next image button intent: advances to next photo
                    val nextIntent = Intent(context, AlbumWidgetProvider::class.java).apply {
                        action = ACTION_NEXT_ALBUM_IMAGE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val nextPendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 10 + 3,
                        nextIntent,
                        flags
                    )
                    views.setOnClickPendingIntent(R.id.btn_album_widget_next, nextPendingIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun advanceWidget(context: Context, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val albumId = prefs.getString("flutter.album_widget_${appWidgetId}_album_id", null)
            val isRandom = prefs.getBoolean("flutter.album_widget_${appWidgetId}_is_random", true)
            val currentIndex = prefs.getLong("flutter.album_widget_${appWidgetId}_current_index", 0L).toInt()

            val (_, paths) = getAlbumImagePaths(context, albumId)
            if (paths.isEmpty()) return

            val newIndex = if (isRandom && paths.size > 1) {
                var r = Random.nextInt(paths.size)
                if (r == currentIndex) {
                    r = (r + 1) % paths.size
                }
                r
            } else {
                (currentIndex + 1) % paths.size
            }

            prefs.edit().putLong("flutter.album_widget_${appWidgetId}_current_index", newIndex.toLong()).apply()
            updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
        }

        fun scheduleAutoHide(context: Context, appWidgetId: Int) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val hideIntent = Intent(context, AlbumWidgetProvider::class.java).apply {
                    action = ACTION_HIDE_CONTROLS
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 5,
                    hideIntent,
                    flags
                )
                alarmManager.set(
                    AlarmManager.RTC,
                    System.currentTimeMillis() + 5000,
                    pendingIntent
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun cancelAutoHide(context: Context, appWidgetId: Int) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val hideIntent = Intent(context, AlbumWidgetProvider::class.java).apply {
                    action = ACTION_HIDE_CONTROLS
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 5,
                    hideIntent,
                    flags
                )
                alarmManager.cancel(pendingIntent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            cancelAutoHide(context, appWidgetId)
            AlbumWidgetScheduler.cancel(context, appWidgetId)
            editor.remove("flutter.album_widget_${appWidgetId}_album_id")
            editor.remove("flutter.album_widget_${appWidgetId}_album_name")
            editor.remove("flutter.album_widget_${appWidgetId}_interval_minutes")
            editor.remove("flutter.album_widget_${appWidgetId}_is_random")
            editor.remove("flutter.album_widget_${appWidgetId}_current_index")
            editor.remove("flutter.album_widget_${appWidgetId}_show_controls")
        }
        editor.apply()
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        when (intent.action) {
            ACTION_TOGGLE_CONTROLS -> {
                val currentlyShowing = prefs.getBoolean("flutter.album_widget_${appWidgetId}_show_controls", false)
                val newShow = !currentlyShowing
                prefs.edit().putBoolean("flutter.album_widget_${appWidgetId}_show_controls", newShow).apply()
                updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
                if (newShow) {
                    scheduleAutoHide(context, appWidgetId)
                } else {
                    cancelAutoHide(context, appWidgetId)
                }
            }
            ACTION_HIDE_CONTROLS -> {
                prefs.edit().putBoolean("flutter.album_widget_${appWidgetId}_show_controls", false).apply()
                updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
            }
            ACTION_NEXT_ALBUM_IMAGE -> {
                advanceWidget(context, appWidgetId)
                if (prefs.getBoolean("flutter.album_widget_${appWidgetId}_show_controls", false)) {
                    scheduleAutoHide(context, appWidgetId)
                }
            }
            ACTION_OPEN_SETTINGS -> {
                cancelAutoHide(context, appWidgetId)
                prefs.edit().putBoolean("flutter.album_widget_${appWidgetId}_show_controls", false).apply()
                updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)

                val configureIntent = Intent(context, AlbumWidgetConfigureActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                context.startActivity(configureIntent)
            }
        }
    }
}
