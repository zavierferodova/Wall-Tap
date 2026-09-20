package com.zavierdev.walltap

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val intervalMinutes = prefs.getLong("flutter.walltap_interval_minutes", 0L).toInt()
            if (intervalMinutes > 0) {
                Scheduler.schedule(context, intervalMinutes)
            }
            WidgetProvider.updateAllWidgets(context)

            // Reschedule and update Album Display Widgets
            AlbumWidgetScheduler.rescheduleAll(context)
            AlbumWidgetProvider.updateAllWidgets(context)

            // Restore persistent notification if enabled
            if (NotificationHelper.isNotificationEnabled(context)) {
                NotificationHelper.showNotification(context)
            }
        }
    }
}
