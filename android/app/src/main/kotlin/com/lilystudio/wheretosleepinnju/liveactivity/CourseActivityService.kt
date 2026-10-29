package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log

/** Runs only during a visible countdown; never stays alive while waiting for tomorrow. */
class CourseActivityService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val tick = Runnable { CourseActivityEngine.reconcile(this, false) }
    override fun onCreate() { super.onCreate(); running = this }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return try {
            CourseActivityEngine.reconcile(this, false)
            val item = CourseActivityEngine.current()
            if (item == null || !CourseActivityNotification.allowed(this)) {
                stopSelf(); return START_NOT_STICKY
            }
            // Satisfy the FGS deadline while a privileged connection is pending.
            startForeground(CourseActivityNotification.ID, CourseActivityNotification.build(this, item, false))
            CourseActivityEngine.invalidate()
            CourseActivityEngine.reconcile(this, false)
            arm(item.start)
            START_STICKY
        } catch (error: Exception) {
            // OEM/type restrictions can reject startForeground after the start request
            // itself succeeded. Keep the alarm/standard-notification fallback alive.
            Log.w("CourseLiveActivity", "Foreground promotion failed", error)
            CourseActivityStore.prefs(this).edit().putString("lastError", error.message).apply()
            stopSelf()
            START_NOT_STICKY
        }
    }

    private fun arm(start: Long) {
        handler.removeCallbacks(tick)
        handler.postDelayed(tick, (start - System.currentTimeMillis()).coerceIn(100L, 30_000L))
    }
    override fun onDestroy() {
        if (running === this) running = null
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?) = null
    companion object {
        private var running: CourseActivityService? = null
        fun start(context: Context) {
            if (running != null) return
            try {
                if (android.os.Build.VERSION.SDK_INT >= 26) context.startForegroundService(Intent(context, CourseActivityService::class.java))
                else context.startService(Intent(context, CourseActivityService::class.java))
            } catch (error: Exception) {
                Log.w("CourseLiveActivity", "Foreground start unavailable; alarm and standard notification remain", error)
            }
        }
        fun refreshRunning() { running?.let { service -> CourseActivityEngine.current()?.let { service.arm(it.start) } } }
        fun stop(context: Context) {
            running?.stopForeground(STOP_FOREGROUND_REMOVE)
            context.stopService(Intent(context, CourseActivityService::class.java))
            CourseActivityStore.prefs(context).edit().remove("activeId").remove("surface").apply()
        }
    }
}
