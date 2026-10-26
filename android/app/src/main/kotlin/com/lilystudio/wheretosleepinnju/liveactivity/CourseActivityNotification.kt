package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat
import com.lilystudio.wheretosleepinnju.MainActivity
import com.lilystudio.wheretosleepinnju.R

internal object CourseActivityNotification {
    const val ID = 7101
    const val CHANNEL = "course_live_activity"
    fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    fun allowed(context: Context): Boolean {
        val manager = manager(context)
        return manager.areNotificationsEnabled() && (Build.VERSION.SDK_INT < 26 ||
            manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)
    }
    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) manager(context).createNotificationChannel(
            NotificationChannel(CHANNEL, "课前实时活动", NotificationManager.IMPORTANCE_LOW).apply {
                description = "即将上课的课程、教室和倒计时"; setSound(null, null)
            })
    }
    fun actionIntent(context: Context, item: CourseActivity, action: String) = Intent(context, CourseActivityReceiver::class.java)
        .setAction(action).putExtra("activityId", item.id).putExtra("courseId", item.courseId)
        .setData(android.net.Uri.Builder().scheme("ncs-live").authority("action").appendPath(item.id).appendPath(action).build())
    private fun action(context: Context, item: CourseActivity, action: String) = PendingIntent.getBroadcast(
        context, 0, actionIntent(context, item, action), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun build(context: Context, item: CourseActivity, island: Boolean): Notification {
        createChannel(context)
        val open = Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW)
            .setData(android.net.Uri.Builder().scheme("ncs").authority("course").appendPath(item.courseId).build())
        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_course_live).setContentTitle(item.name)
            .setContentText(listOfNotNull(item.classroom, item.teacher).joinToString(" · ").ifBlank { "即将上课" })
            .setOngoing(true).setOnlyAlertOnce(true).setCategory(NotificationCompat.CATEGORY_EVENT)
            .setWhen(item.start).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
            .setColor(runCatching { Color.parseColor(item.color) }.getOrDefault(Color.rgb(66, 133, 244)))
            .setContentIntent(PendingIntent.getActivity(context, 7102, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            .setDeleteIntent(action(context, item, CourseActivityReceiver.DISMISS))
            .addAction(0, "我已到达", action(context, item, CourseActivityReceiver.ARRIVED))
            .addAction(0, "关闭本次提醒", action(context, item, CourseActivityReceiver.DISMISS))
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        if (island) builder.addExtras(CourseIslandTemplate.create(context, item))
        else if (Build.VERSION.SDK_INT >= 36) builder.setRequestPromotedOngoing(true)
        return builder.build()
    }
}
