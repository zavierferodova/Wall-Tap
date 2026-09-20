package com.zavierdev.walltap

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import android.widget.Toast
import org.json.JSONArray
import java.io.File
import kotlin.random.Random

class WidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_NEXT = "com.walltap.app.ACTION_NEXT"
        const val ACTION_TOGGLE = "com.walltap.app.ACTION_TOGGLE"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, WidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateWidget(context, appWidgetManager, widgetId)
            }
        }

        fun getOrCalculateNextIndex(prefs: android.content.SharedPreferences, paths: List<String>, currentIndex: Int): Int {
            if (paths.isEmpty()) return 0
            if (paths.size == 1) return 0
            val savedNext = prefs.getLong("flutter.walltap_next_index", -1L).toInt()
            if (savedNext in paths.indices && (paths.size <= 1 || savedNext != currentIndex)) {
                return savedNext
            }
            val isRandom = prefs.getBoolean("flutter.walltap_is_random", false)
            val calculated = if (isRandom && paths.size > 1) {
                var r = Random.nextInt(paths.size)
                if (r == currentIndex) {
                    r = (r + 1) % paths.size
                }
                r
            } else {
                (currentIndex + 1) % paths.size
            }
            prefs.edit().putLong("flutter.walltap_next_index", calculated.toLong()).apply()
            return calculated
        }

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.walltap_widget)
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                // Get next wallpaper path for change wallpaper widget display
                val playlistJson = prefs.getString("flutter.walltap_playlist_paths", null)
                val currentIndex = (prefs.getLong("flutter.walltap_current_index", 0L)).toInt()
                val paths = parsePaths(playlistJson)

                var nextPath: String? = null
                if (paths.isNotEmpty()) {
                    val nextIndex = getOrCalculateNextIndex(prefs, paths, currentIndex)
                    val safeNextIndex = if (nextIndex in paths.indices) nextIndex else 0
                    nextPath = paths[safeNextIndex]
                }

                if (nextPath != null && File(nextPath).exists()) {
                    val widgetThumb = WallpaperHelper.decodeSampledBitmapFromFile(
                        nextPath,
                        300,
                        480,
                        android.graphics.Bitmap.Config.RGB_565
                    )
                    if (widgetThumb != null) {
                        views.setImageViewBitmap(R.id.widget_wallpaper_image, widgetThumb)
                    } else {
                        views.setImageViewResource(R.id.widget_wallpaper_image, android.R.color.transparent)
                    }
                    views.setViewVisibility(R.id.widget_badge_container, android.view.View.VISIBLE)
                    views.setTextViewText(R.id.widget_badge_text, "NEXT")
                    views.setContentDescription(R.id.widget_wallpaper_image, "Next Wallpaper")
                } else {
                    views.setImageViewResource(R.id.widget_wallpaper_image, android.R.color.transparent)
                    views.setViewVisibility(R.id.widget_badge_container, android.view.View.GONE)
                }

                // PendingIntent for Settings / Launch App
                val appIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val appPendingIntent = PendingIntent.getActivity(context, 0, appIntent, flags)
                views.setOnClickPendingIntent(R.id.btn_widget_settings, appPendingIntent)

                // PendingIntent for Next Wallpaper
                val nextIntent = Intent(context, WidgetProvider::class.java).apply {
                    action = ACTION_NEXT
                }
                val nextPendingIntent = PendingIntent.getBroadcast(context, 1, nextIntent, flags)
                views.setOnClickPendingIntent(R.id.btn_widget_next, nextPendingIntent)

                // PendingIntent for Toggle / Play / Pause
                val toggleIntent = Intent(context, WidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE
                }
                val togglePendingIntent = PendingIntent.getBroadcast(context, 2, toggleIntent, flags)
                views.setOnClickPendingIntent(R.id.btn_widget_play, togglePendingIntent)

                // Dynamic Play / Pause Icon
                val isEnabled = prefs.getBoolean("flutter.walltap_slideshow_enabled", true)
                val intervalMinutes = prefs.getLong("flutter.walltap_interval_minutes", 0L).toInt()
                val isRunning = isEnabled && intervalMinutes > 0
                if (isRunning) {
                    views.setImageViewResource(R.id.btn_widget_play, R.drawable.ic_widget_pause)
                    views.setContentDescription(R.id.btn_widget_play, "Pause Auto-Shuffle")
                } else {
                    views.setImageViewResource(R.id.btn_widget_play, R.drawable.ic_widget_play)
                    views.setContentDescription(R.id.btn_widget_play, "Resume Auto-Shuffle")
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun handleNextWallpaper(context: Context, onComplete: ((Boolean) -> Unit)? = null) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val playlistJson = prefs.getString("flutter.walltap_playlist_paths", null)
            val paths = parsePaths(playlistJson)
            if (paths.isEmpty()) {
                onComplete?.invoke(false)
                return
            }

            val currentIndex = (prefs.getLong("flutter.walltap_current_index", 0L)).toInt()
            val targetNextIndex = getOrCalculateNextIndex(prefs, paths, currentIndex)
            val nextPath = paths[targetNextIndex]
            val targetScreen = prefs.getString("flutter.walltap_target_screen", "both") ?: "both"
            val scaleType = prefs.getString("flutter.walltap_scale_type", "full") ?: "full"

            Thread {
                val success = WallpaperHelper.setDeviceWallpaper(context, nextPath, targetScreen, scaleType)
                if (success) {
                    val newCurrentIndex = targetNextIndex
                    val editor = prefs.edit()
                    editor.putLong("flutter.walltap_current_index", newCurrentIndex.toLong())

                    val configJson = prefs.getString("flutter.walltap_config", null)
                    if (!configJson.isNullOrEmpty()) {
                        try {
                            val jsonObj = org.json.JSONObject(configJson)
                            jsonObj.put("currentIndex", newCurrentIndex)
                            editor.putString("flutter.walltap_config", jsonObj.toString())
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }

                    // Pre-calculate upcoming next index for next rotation
                    val isRandom = prefs.getBoolean("flutter.walltap_is_random", false)
                    val upcomingNextIndex = if (isRandom && paths.size > 1) {
                        var r = Random.nextInt(paths.size)
                        if (r == newCurrentIndex) {
                            r = (r + 1) % paths.size
                        }
                        r
                    } else {
                        (newCurrentIndex + 1) % paths.size
                    }
                    editor.putLong("flutter.walltap_next_index", upcomingNextIndex.toLong())
                    editor.apply()

                    updateAllWidgets(context)
                }
                onComplete?.invoke(success)
            }.start()
        }

        fun handleToggle(context: Context) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.walltap_slideshow_enabled", true)
            val intervalMinutes = prefs.getLong("flutter.walltap_interval_minutes", 0L).toInt()

            val isCurrentlyRunning = isEnabled && intervalMinutes > 0

            if (isCurrentlyRunning) {
                // Pause auto-shuffle
                prefs.edit().putBoolean("flutter.walltap_slideshow_enabled", false).apply()
                Scheduler.cancel(context)
                Toast.makeText(context, "Auto-shuffle paused", Toast.LENGTH_SHORT).show()
            } else {
                // Resume auto-shuffle
                val targetInterval = if (intervalMinutes > 0) intervalMinutes else 15
                prefs.edit()
                    .putBoolean("flutter.walltap_slideshow_enabled", true)
                    .putLong("flutter.walltap_interval_minutes", targetInterval.toLong())
                    .apply()
                Scheduler.schedule(context, targetInterval)
                Toast.makeText(context, "Auto-shuffle running ($targetInterval min)", Toast.LENGTH_SHORT).show()
            }

            updateAllWidgets(context)
        }

        private fun parsePaths(jsonString: String?): List<String> {
            if (jsonString.isNullOrEmpty()) return emptyList()
            return try {
                val array = JSONArray(jsonString)
                val list = mutableListOf<String>()
                for (i in 0 until array.length()) {
                    val path = array.optString(i)
                    if (path.isNotEmpty() && File(path).exists()) {
                        list.add(path)
                    }
                }
                list
            } catch (e: Exception) {
                emptyList()
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_NEXT -> {
                handleNextWallpaper(context)
            }
            ACTION_TOGGLE -> {
                handleToggle(context)
            }
        }
    }
}
