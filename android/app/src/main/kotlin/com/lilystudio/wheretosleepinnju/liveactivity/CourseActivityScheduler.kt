package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

internal object CourseActivityScheduler {
    private fun pending(context: Context) = PendingIntent.getBroadcast(context, 7100,
        Intent(context, CourseActivityReceiver::class.java).setAction(CourseActivityReceiver.ALARM),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun exact(context: Context): Boolean {
        val manager = context.getSystemService(AlarmManager::class.java)
        return Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()
    }
    fun schedule(context: Context, at: Long?) {
        val manager = context.getSystemService(AlarmManager::class.java)
        manager.cancel(pending(context))
        val prefs = CourseActivityStore.prefs(context)
        if (at == null) { prefs.edit().remove("nextAt").apply(); return }
        // Use WAKEUP independently of whether a desktop widget is installed.
        try {
            if (exact(context)) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
            else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
        }
        prefs.edit().putLong("nextAt", at).apply()
    }
}
