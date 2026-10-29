package com.lilystudio.wheretosleepinnju.liveactivity

import com.lilystudio.wheretosleepinnju.widget.WidgetScheduleData
import com.lilystudio.wheretosleepinnju.widget.WidgetStateResolver
import org.json.JSONArray
import java.util.Calendar
import java.util.Date

/** An occurrence, not a recurring course. IDs survive process recreation and re-sends. */
data class CourseActivity(
    val id: String, val courseId: String, val name: String,
    val classroom: String?, val teacher: String?, val start: Long, val end: Long,
    val color: String?,
)

data class CourseActivityPlan(val current: CourseActivity?, val nextAt: Long?)

object CourseActivityPlanner {
    fun parseDate(value: String): Long? = WidgetStateResolver.parseIsoDate(value)?.time

    fun fromWidget(data: WidgetScheduleData, now: Long): List<CourseActivity> {
        val result = mutableListOf<CourseActivity>()
        val day = Calendar.getInstance().apply { timeInMillis = now }
        // Midnight rebuilds this projection; tomorrow is included for windows crossing midnight.
        repeat(2) {
            val date = day.time
            val normalized = WidgetStateResolver.normalizeForCurrentDay(data, date)
            normalized.todayCourses.forEach { course ->
                val period = data.timeTemplate.getPeriodRange(course.startPeriod, course.periodCount)
                if (period != null) {
                    val start = WidgetStateResolver.parseTimeOnDate(period.startTime, date)?.time
                    val end = WidgetStateResolver.parseTimeOnDate(period.endTime, date)?.time
                    if (start != null && end != null && end > start) result += CourseActivity(
                        "${data.schoolId}:${course.id}:$start", course.id, course.name,
                        course.classroom, course.teacher, start, end, course.color)
                }
            }
            day.add(Calendar.DAY_OF_MONTH, 1)
        }
        return result.distinctBy { it.id }.sortedWith(compareBy({ it.start }, { it.id }))
    }

    /** Validate the entire snapshot before replacing the last accepted payload. */
    fun fromJson(activities: JSONArray): List<CourseActivity> = (0 until activities.length()).map { index ->
        val json = activities.getJSONObject(index)
        val start = requireNotNull(parseDate(json.getString("startTime"))) { "Invalid startTime" }
        val end = requireNotNull(parseDate(json.getString("endTime"))) { "Invalid endTime" }
        require(end > start) { "endTime must follow startTime" }
        val status = json.optString("status", "scheduled")
        val id = json.getString("activityId"); require(id.isNotBlank())
        CourseActivity(id, json.getString("courseId"), json.getString("courseName"),
            json.optString("classroom").takeUnless { it.isBlank() || it == "null" },
            json.optString("teacher").takeUnless { it.isBlank() || it == "null" }, start, end,
            json.optString("color").takeUnless { it.isBlank() || it == "null" }) to status
    }.filter { it.second !in setOf("ended", "failed", "ending") }.map { it.first }.distinctBy { it.id }

    fun plan(activities: List<CourseActivity>, now: Long, minutesBefore: Int,
             dismissed: Set<String>, nextMidnight: Boolean): CourseActivityPlan {
        val lead = minutesBefore.coerceIn(1, 60) * 60_000L
        val candidates = activities.filter { it.id !in dismissed && it.start > now }
            .sortedWith(compareBy({ it.start }, { it.id }))
        val current = candidates.firstOrNull { now >= it.start - lead }
        val transitions = candidates.flatMap { listOf(it.start - lead, it.start) }.filter { it > now }.toMutableList()
        if (nextMidnight) transitions += Calendar.getInstance().apply {
            timeInMillis = now; add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return CourseActivityPlan(current, transitions.minOrNull())
    }
}
