package com.zavierdev.walltap

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Scheduler.ACTION_ALARM_TICK) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.walltap_slideshow_enabled", false)
            val intervalMinutes = prefs.getLong("flutter.walltap_interval_minutes", 0L).toInt()

            if (!isEnabled || intervalMinutes <= 0) {
                Scheduler.cancel(context)
                return
            }

            // 1. Advance to next wallpaper
            WidgetProvider.handleNextWallpaper(context)

            // 2. Schedule the next tick based on saved interval
            Scheduler.schedule(context, intervalMinutes)
        }
    }
}
