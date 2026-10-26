package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Activity
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.lilystudio.wheretosleepinnju.widget.WidgetDataStore
import com.lilystudio.wheretosleepinnju.widget.ScheduleWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import rikka.shizuku.Shizuku

/** Existing widget_data channel, with Android-specific configuration/capability methods. */
object CourseLiveActivityBridge {
    private var initialized = false
    @JvmStatic fun initialize(context: Context) {
        if (initialized) return
        initialized = true
        val app = context.applicationContext
        Shizuku.addRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode == 52002 && grantResult == PackageManager.PERMISSION_GRANTED &&
                IslandWhitelistBypass.mode(app) == IslandBypassMode.SHIZUKU) {
                IslandWhitelistBypass.authorize(app)
            }
        }
    }

    @JvmStatic fun status(context: Context): Map<String, Any?> {
        val manager = CourseActivityNotification.manager(context)
        val prefs = CourseActivityStore.prefs(context)
        val active = manager.activeNotifications.firstOrNull { it.id == CourseActivityNotification.ID }
        val now = System.currentTimeMillis()
        val items = runCatching { CourseActivityEngine.activities(context, now).first }.getOrDefault(emptyList())
        val future = items.filter { it.start > now && it.id !in CourseActivityStore.dismissed(context) }
        val next = future.minByOrNull { it.start }
        val minutes = WidgetDataStore.loadWidgetData(context)?.resolveApproachingMinutes() ?: 15
        val reason = when {
            !CourseActivityStore.enabled(context) -> "disabled"
            !CourseActivityNotification.allowed(context) -> "permissionDenied"
            active != null -> "posted"
            items.isEmpty() -> "noData"
            next == null -> "noUpcomingCourse"
            now < next.start - minutes.coerceIn(1, 60) * 60_000L -> "waiting"
            else -> "notPosted"
        }
        return mapOf(
            "state" to reason,
            "courseCount" to items.size,
            "nextCourseAt" to next?.start,
            "windowStartAt" to next?.let { it.start - minutes.coerceIn(1, 60) * 60_000L },
            "approachingMinutes" to minutes,
            "notificationPosted" to (active != null),
            "lastPostAt" to prefs.getLong("lastPostAt", 0),
            "enabled" to CourseActivityStore.enabled(context),
            "notificationsEnabled" to CourseActivityNotification.allowed(context),
            "exactAlarmAllowed" to CourseActivityScheduler.exact(context),
            "batteryUnrestricted" to context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName),
            "supportsLiveUpdates" to (Build.VERSION.SDK_INT >= 36),
            "promotionAllowed" to (Build.VERSION.SDK_INT >= 36 && manager.canPostPromotedNotifications()),
            "promoted" to (Build.VERSION.SDK_INT >= 36 && active != null && active.notification.flags and Notification.FLAG_PROMOTED_ONGOING != 0),
            "supportsIsland" to CourseIslandTemplate.supportsIsland(),
            "islandMode" to IslandWhitelistBypass.mode(context).name,
            "islandReady" to IslandWhitelistBypass.ready(context),
            "islandStatus" to IslandWhitelistBypass.statusText(),
            "activeId" to prefs.getString("activeId", null),
            "surface" to prefs.getString("surface", null),
            "nextAt" to prefs.getLong("nextAt", 0),
            "lastError" to prefs.getString("lastError", null))
    }

    @JvmStatic fun handle(activity: Activity?, context: Context, call: MethodCall, result: MethodChannel.Result): Boolean {
        if (call.method !in setOf("sendLiveActivityData", "refreshLiveActivities", "endLiveActivity", "sendUnifiedDataPackage",
                "getLiveActivityStatus", "testLiveActivity", "configureLiveActivities", "openLiveActivitySettings", "authorizeIsland", "restoreIslandNetwork")) return false
        try {
            when (call.method) {
                "sendLiveActivityData" -> {
                    val values = call.argument<List<*>>("activities") ?: throw IllegalArgumentException("Missing activities")
                    CourseActivityStore.saveActivities(context, JSONArray(values))
                    CourseActivityEngine.reconcile(context, false); result.success(true)
                }
                "sendUnifiedDataPackage" -> {
                    val data = call.argument<Map<String, Any?>>("data") ?: throw IllegalArgumentException("Missing data")
                    val widget = data["widget"] as? Map<*, *>
                    // Validate activities before mutating either snapshot.
                    val live = data["liveActivities"] as? Map<*, *>
                    val activities = live?.get("activities") as? List<*>
                    if (live != null && activities == null) throw IllegalArgumentException("Missing activities")
                    if (activities != null) CourseActivityPlanner.fromJson(JSONArray(activities))
                    if (widget != null) {
                        check(WidgetDataStore.saveWidgetData(context, JSONObject(widget).toString()))
                        CourseActivityStore.useWidget(context)
                        ScheduleWidgetProvider.refreshAllWidgets(context)
                    }
                    if (activities != null) CourseActivityStore.saveActivities(context, JSONArray(activities))
                    CourseActivityEngine.reconcile(context, false); result.success(true)
                }
                "refreshLiveActivities" -> { CourseActivityEngine.reconcile(context, false); result.success(true) }
                "endLiveActivity" -> {
                    val id = call.argument<String>("activityId") ?: throw IllegalArgumentException("Missing activityId")
                    CourseActivityEngine.dismiss(context, id, false); result.success(true)
                }
                "testLiveActivity" -> {
                    check(CourseActivityStore.enabled(context)) { "请先开启课前实时活动" }
                    check(CourseActivityNotification.allowed(context)) { "请先允许通知，并开启课前实时活动通知类别" }
                    CourseActivityStore.startPreview(context)
                    CourseActivityEngine.invalidate()
                    CourseActivityEngine.reconcile(context, activity != null)
                    result.success(status(context))
                }
                "getLiveActivityStatus" -> result.success(status(context))
                "configureLiveActivities" -> {
                    val mode = call.argument<String>("islandMode")?.let { IslandBypassMode.valueOf(it) }
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled != null) check(CourseActivityStore.prefs(context).edit().putBoolean("enabled", enabled).commit())
                    if (enabled == false) {
                        CourseActivityStore.prefs(context).edit().remove("preview").commit()
                        IslandWhitelistBypass.restore(context, disconnect = true)
                    }
                    if (mode != null) IslandWhitelistBypass.setMode(context, mode)
                    CourseActivityEngine.invalidate()
                    CourseActivityEngine.reconcile(context, activity != null)
                    result.success(status(context))
                }
                "authorizeIsland" -> {
                    if (IslandWhitelistBypass.mode(context) == IslandBypassMode.SHIZUKU &&
                        runCatching { Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED }.getOrDefault(true)) {
                        IslandWhitelistBypass.requestShizukuPermission()
                    } else IslandWhitelistBypass.authorize(context)
                    result.success(true)
                }
                "restoreIslandNetwork" -> { IslandWhitelistBypass.restore(context); result.success(true) }
                "openLiveActivitySettings" -> {
                    val host = requireNotNull(activity) { "Activity required" }
                    val target = call.argument<String>("target") ?: "notifications"
                    val intent = when (target) {
                        "notifications" -> {
                            if (Build.VERSION.SDK_INT >= 33 && host.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                host.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 7103)
                                result.success(true); return true
                            }
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                        }
                        "exactAlarm" -> if (Build.VERSION.SDK_INT >= 31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${context.packageName}"))
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
                        "promotion" -> if (Build.VERSION.SDK_INT >= 36) Intent(Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                            else Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                        "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        "autostart" -> if (CourseIslandTemplate.supportsIsland()) Intent().setComponent(android.content.ComponentName(
                            "com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"))
                            else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
                        else -> throw IllegalArgumentException("Unknown settings target")
                    }
                    try { host.startActivity(intent) } catch (_: RuntimeException) {
                        host.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")))
                    }
                    result.success(true)
                }
            }
        } catch (error: Exception) { result.error("LIVE_ACTIVITY_ERROR", error.message, null) }
        return true
    }
}
