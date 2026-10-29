package com.lilystudio.wheretosleepinnju.liveactivity

import android.content.Context
import android.os.Build
import android.util.Log
import com.lilystudio.wheretosleepinnju.widget.WidgetDataStore
import org.json.JSONArray

/** All entry points run on the main thread. Delayed privileged callbacks revalidate generation. */
object CourseActivityEngine {
    private var generation = 0L
    private var appForeground = false
    @JvmStatic fun setAppForeground(value: Boolean) { appForeground = value }
    private var current: CourseActivity? = null
    private var signature: String? = null

    internal fun invalidate() { signature = null }

    @JvmStatic fun onWidgetData(context: Context) {
        CourseActivityStore.useWidget(context)
        reconcile(context, false)
    }
    @JvmStatic fun clear(context: Context) {
        CourseActivityStore.prefs(context).edit().remove("activities").putBoolean("explicit", true)
            .remove("dismissed").remove("preview").commit()
        reconcile(context, false)
    }
    internal fun activities(context: Context, now: Long): Pair<List<CourseActivity>, Boolean> {
        if (CourseActivityStore.useExplicit(context)) {
            val raw = CourseActivityStore.prefs(context).getString("activities", "[]")!!
            return CourseActivityPlanner.fromJson(JSONArray(raw)) to false
        }
        val widget = WidgetDataStore.loadWidgetData(context) ?: return emptyList<CourseActivity>() to false
        return CourseActivityPlanner.fromWidget(widget, now) to true
    }
    @JvmStatic fun reconcile(context: Context, allowServiceStart: Boolean) {
        val app = context.applicationContext
        CourseActivityNotification.createChannel(app)
        IslandWhitelistBypass.recoverPending(app)
        val now = System.currentTimeMillis()
        try {
            val (scheduled, recurring) = activities(app, now)
            val preview = CourseActivityStore.preview(app, now)
            val items = scheduled + listOfNotNull(preview)
            CourseActivityStore.pruneDismissals(app, items.filter { it.start > now }.map { it.id }.toSet())
            val enabled = CourseActivityStore.enabled(app) && CourseActivityNotification.allowed(app)
            val minutes = WidgetDataStore.loadWidgetData(app)?.resolveApproachingMinutes() ?: 15
            val planned = if (enabled) CourseActivityPlanner.plan(items, now, minutes,
                CourseActivityStore.dismissed(app), recurring) else CourseActivityPlan(null, null)
            val plan = if (enabled && preview != null) CourseActivityPlan(preview,
                listOfNotNull(preview.start, planned.nextAt).minOrNull()) else planned
            // Scheduling failure must not suppress a notification already due now.
            try { CourseActivityScheduler.schedule(app, plan.nextAt) }
            catch (error: Exception) { recordError(app, error) }
            val next = plan.current
            current = next
            if (next == null) {
                generation++; signature = null
                CourseActivityService.stop(app)
                CourseActivityNotification.manager(app).cancel(CourseActivityNotification.ID)
                return
            }
            // Include the effective backend so permission loss switches back to native promotion.
            val nextSignature = "$next:${IslandWhitelistBypass.mode(app)}:${IslandWhitelistBypass.ready(app)}"
            val stillPosted = CourseActivityNotification.manager(app).activeNotifications.any {
                it.id == CourseActivityNotification.ID
            }
            if (signature != nextSignature || !stillPosted) {
                // Publish the native fallback before attempting any privileged work.
                // A slow/failed backend must never leave the notification drawer empty.
                post(app, next, false)
                signature = nextSignature
                val token = ++generation
                try { IslandWhitelistBypass.publish(app, "course", onPublication = { accepted ->
                    if (!accepted && generation == token) signature = null
                }) { accepted ->
                    if (token == generation && System.currentTimeMillis() < next.start &&
                        CourseActivityStore.enabled(app) && next.id !in CourseActivityStore.dismissed(app)) {
                        val island = CourseIslandTemplate.supportsIsland() && accepted &&
                            (Build.VERSION.SDK_INT < 36 || IslandWhitelistBypass.mode(app) != IslandBypassMode.OFF)
                        if (island) {
                            try { post(app, next, true) }
                            catch (error: Exception) {
                                recordError(app, error)
                                signature = null
                            }
                        }
                    }
                } } catch (error: Exception) {
                    recordError(app, error)
                    signature = null
                }
            }
            if (allowServiceStart || appForeground) CourseActivityService.start(app)
            CourseActivityService.refreshRunning()
        } catch (error: Exception) {
            recordError(app, error)
            generation++; signature = null; current = null
            CourseActivityService.stop(app)
            CourseActivityNotification.manager(app).cancel(CourseActivityNotification.ID)
        }
    }
    private fun post(context: Context, item: CourseActivity, island: Boolean) {
        CourseActivityNotification.manager(context).notify(CourseActivityNotification.ID,
            CourseActivityNotification.build(context, item, island))
        CourseActivityStore.prefs(context).edit().putString("activeId", item.id)
            .putLong("lastPostAt", System.currentTimeMillis())
            .putString("surface", if (island) "xiaomiIsland" else if (Build.VERSION.SDK_INT >= 36) "liveUpdate" else "notification").apply()
    }
    private fun recordError(context: Context, error: Exception) {
        Log.e("CourseLiveActivity", "publication/scheduling failed", error)
        CourseActivityStore.prefs(context).edit()
            .putString("lastError", "${error.javaClass.simpleName}: ${error.message}").apply()
    }
    internal fun current() = current
    internal fun dismiss(context: Context, id: String, arrived: Boolean) {
        // A stale notification button must not suppress a different occurrence.
        val now = System.currentTimeMillis()
        val test = CourseActivityStore.preview(context, now)
        val item = (activities(context, now).first + listOfNotNull(test))
            .firstOrNull { it.id == id && it.start > now } ?: return
        val preview = test?.id == id
        if (preview) CourseActivityStore.prefs(context).edit().remove("preview").commit()
        else CourseActivityStore.dismiss(context, id)
        if (arrived && !preview) WidgetDataStore.setArrivedCourse(context, item.courseId)
        com.lilystudio.wheretosleepinnju.widget.ScheduleWidgetProvider.refreshAllWidgets(context)
        reconcile(context, false)
    }
}
