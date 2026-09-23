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

                // Get next wallpaper path for change wallpaper widget display
                val playlistJson = prefs.getString("flutter.walltap_playlist_paths", null)
                val currentIndex = (prefs.getLong("flutter.walltap_current_index", 0L)).toInt()
                val paths = parsePaths(playlistJson)

                if (paths.isEmpty()) {
                    views.setViewVisibility(R.id.widget_wallpaper_flipper, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_badge_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_empty_container, android.view.View.VISIBLE)
                    views.setTextViewText(R.id.widget_empty_text, "No wallpapers added\nTap to open WallTap")
                    views.setOnClickPendingIntent(R.id.widget_empty_container, appPendingIntent)
                    views.setOnClickPendingIntent(R.id.widget_root, appPendingIntent)
                    prefs.edit().remove("flutter.widget_${appWidgetId}_last_path").apply()
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                    return
                }

                views.setViewVisibility(R.id.widget_empty_container, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_wallpaper_flipper, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_badge_container, android.view.View.VISIBLE)
                views.setTextViewText(R.id.widget_badge_text, "NEXT")

                val nextIndex = getOrCalculateNextIndex(prefs, paths, currentIndex)
                val safeNextIndex = if (nextIndex in paths.indices) nextIndex else 0
                val nextPath = paths[safeNextIndex]

                val lastPath = prefs.getString("flutter.widget_${appWidgetId}_last_path", null)
                val currentChild = prefs.getInt("flutter.widget_${appWidgetId}_displayed_child", 0)

                var updatedDisplayedChild = currentChild

                if (File(nextPath).exists()) {
                    val widgetThumb = WallpaperHelper.decodeWidgetBitmap(nextPath, 300, 480)
                    if (widgetThumb != null) {
                        if (lastPath == null) {
                            // Initial load: set directly on child 0 and ensure child 0 is displayed
                            views.setImageViewBitmap(R.id.widget_wallpaper_image_1, widgetThumb)
                            views.setContentDescription(R.id.widget_wallpaper_image_1, "Next Wallpaper")
                            views.setInt(R.id.widget_wallpaper_flipper, "setDisplayedChild", 0)
                            updatedDisplayedChild = 0
                        } else if (lastPath != nextPath) {
                            // Wallpaper changed: set on alternate child and switch displayed child with animation
                            val nextChild = if (currentChild == 0) 1 else 0
                            val targetViewId = if (nextChild == 0) R.id.widget_wallpaper_image_1 else R.id.widget_wallpaper_image_2
                            views.setImageViewBitmap(targetViewId, widgetThumb)
                            views.setContentDescription(targetViewId, "Next Wallpaper")
                            views.setInt(R.id.widget_wallpaper_flipper, "setDisplayedChild", nextChild)
                            updatedDisplayedChild = nextChild
                        } else {
                            // Unchanged path: update currently displayed child and enforce displayed child in launcher
                            val safeChild = if (currentChild == 1) 1 else 0
                            val targetViewId = if (safeChild == 0) R.id.widget_wallpaper_image_1 else R.id.widget_wallpaper_image_2
                            views.setImageViewBitmap(targetViewId, widgetThumb)
                            views.setContentDescription(targetViewId, "Next Wallpaper")
                            views.setInt(R.id.widget_wallpaper_flipper, "setDisplayedChild", safeChild)
                            updatedDisplayedChild = safeChild
                        }
                    }
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)

                prefs.edit()
                    .putString("flutter.widget_${appWidgetId}_last_path", nextPath)
                    .putInt("flutter.widget_${appWidgetId}_displayed_child", updatedDisplayedChild)
                    .apply()
            } catch (e: Exception) {
                android.util.Log.e("WidgetProvider", "Error updating widget $appWidgetId: ${e.message}", e)
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

                    val itemsJson = prefs.getString("flutter.walltap_items", null)
                    if (!itemsJson.isNullOrEmpty()) {
                        try {
                            val itemsArray = org.json.JSONArray(itemsJson)
                            for (i in 0 until itemsArray.length()) {
                                val itemObj = itemsArray.getJSONObject(i)
                                if (itemObj.optString("path") == nextPath) {
                                    val matchedId = itemObj.optString("id")
                                    if (matchedId.isNotEmpty()) {
                                        editor.putString("flutter.walltap_current_wallpaper_id", matchedId)
                                    }
                                    break
                                }
                            }
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
                    MainActivity.notifyWidgetSync(context)
                }
                onComplete?.invoke(success)
            }.start()
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
        }
    }
}
