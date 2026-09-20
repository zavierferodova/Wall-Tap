package com.zavierdev.walltap

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlbumWidgetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == AlbumWidgetScheduler.ACTION_ALARM_TICK_ALBUM) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )

            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                // 1. Advance the photo on this specific widget
                AlbumWidgetProvider.advanceWidget(context, appWidgetId)

                // 2. Reschedule next tick
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val interval = prefs.getLong("flutter.album_widget_${appWidgetId}_interval_minutes", 0L).toInt()
                if (interval > 0) {
                    AlbumWidgetScheduler.schedule(context, appWidgetId, interval)
                }
            }
        }
    }
}
