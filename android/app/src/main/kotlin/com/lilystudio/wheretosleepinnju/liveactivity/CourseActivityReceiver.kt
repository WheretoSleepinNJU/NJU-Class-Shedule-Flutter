package com.lilystudio.wheretosleepinnju.liveactivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class CourseActivityReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            when (intent.action) {
                ARRIVED, DISMISS -> intent.getStringExtra("activityId")?.let {
                    CourseActivityEngine.dismiss(context, it, intent.action == ARRIVED)
                }
                // Boot recovery posts a standard notification; no foreground service is launched from boot.
                else -> CourseActivityEngine.reconcile(context,
                    intent.action == ALARM && CourseActivityScheduler.exact(context))
            }
        } catch (error: Exception) { Log.e("CourseLiveActivity", "Receiver failed", error) }
    }
    companion object {
        const val ALARM = "com.lilystudio.wheretosleepinnju.liveactivity.ALARM"
        const val ARRIVED = "com.lilystudio.wheretosleepinnju.liveactivity.ARRIVED"
        const val DISMISS = "com.lilystudio.wheretosleepinnju.liveactivity.DISMISS"
    }
}
