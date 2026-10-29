package com.lilystudio.wheretosleepinnju.liveactivity

import android.content.Context
import org.json.JSONArray

internal object CourseActivityStore {
    fun prefs(context: Context) = context.getSharedPreferences("course_live_activity", Context.MODE_PRIVATE)
    fun enabled(context: Context) = prefs(context).getBoolean("enabled", false)
    fun useExplicit(context: Context) = prefs(context).getBoolean("explicit", false)
    fun saveActivities(context: Context, activities: JSONArray) {
        CourseActivityPlanner.fromJson(activities)
        check(prefs(context).edit().putString("activities", activities.toString()).putBoolean("explicit", true).commit())
    }
    /** Separate, expiring diagnostic occurrence; never overwrites the real timetable. */
    fun startPreview(context: Context) {
        val now = System.currentTimeMillis()
        val format = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US)
        val item = org.json.JSONObject().put("activityId", "preview:$now").put("courseId", "preview")
            .put("courseName", "实时活动测试").put("classroom", "两分钟后自动结束")
            .put("startTime", format.format(java.util.Date(now + 120_000)))
            .put("endTime", format.format(java.util.Date(now + 180_000)))
        check(prefs(context).edit().putString("preview", item.toString()).commit())
    }
    fun preview(context: Context, now: Long): CourseActivity? {
        val raw = prefs(context).getString("preview", null) ?: return null
        val item = runCatching { CourseActivityPlanner.fromJson(JSONArray().put(org.json.JSONObject(raw))).single() }.getOrNull()
        if (item != null && item.start > now) return item
        prefs(context).edit().remove("preview").commit()
        return null
    }
    fun useWidget(context: Context) {
        check(prefs(context).edit().remove("activities").putBoolean("explicit", false).commit())
    }
    fun dismissed(context: Context): Set<String> = prefs(context).getStringSet("dismissed", emptySet()).orEmpty().toSet()
    fun dismiss(context: Context, id: String) {
        // Expired IDs are pruned by reconcile. Never remove a future occurrence's dismissal.
        prefs(context).edit().putStringSet("dismissed", dismissed(context) + id).commit()
    }
    fun pruneDismissals(context: Context, futureIds: Set<String>) {
        val old = dismissed(context); val next = old.intersect(futureIds)
        if (next != old) prefs(context).edit().putStringSet("dismissed", next).commit()
    }
}
