package com.lilystudio.wheretosleepinnju.liveactivity

import org.junit.Assert.*
import org.junit.Test
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

class CourseActivityPlannerTest {
    private val start = 1_800_000_000_000L
    private fun item(id: String = "course", at: Long = start) = CourseActivity(id, id, "数学", "仙I-101", null, at, at + 7_200_000, null)
    @Test fun schedulesWindowWithoutKeepingAServiceAliveBeforeIt() {
        val plan = CourseActivityPlanner.plan(listOf(item()), start - 3_600_000, 15, emptySet(), false)
        assertNull(plan.current); assertEquals(start - 900_000, plan.nextAt)
    }
    @Test fun startsExactlyAtWindowAndEndsAtClassStart() {
        assertEquals("course", CourseActivityPlanner.plan(listOf(item()), start - 900_000, 15, emptySet(), false).current?.id)
        val ended = CourseActivityPlanner.plan(listOf(item()), start, 15, emptySet(), false)
        assertNull(ended.current); assertNull(ended.nextAt)
    }
    @Test fun doesNotDropAnImminentBoundary() {
        assertEquals(start, CourseActivityPlanner.plan(listOf(item()), start - 1, 15, emptySet(), false).nextAt)
    }
    @Test fun dismissalSuppressesOnlyThatOccurrence() {
        val tomorrow = item("tomorrow", start + 86_400_000)
        val plan = CourseActivityPlanner.plan(listOf(item(), tomorrow), start - 60_000, 15, setOf("course"), false)
        assertNull(plan.current); assertEquals(tomorrow.start - 900_000, plan.nextAt)
    }
    @Test fun simultaneousCoursesChooseAStableWinnerAndCancelToNext() {
        val a = item("a"); val b = item("b")
        assertEquals("a", CourseActivityPlanner.plan(listOf(b, a), start - 1, 15, emptySet(), false).current?.id)
        assertEquals("b", CourseActivityPlanner.plan(listOf(a, b), start - 1, 15, setOf("a"), false).current?.id)
    }
    @Test fun recurringEmptyDayStillSchedulesMidnight() {
        val now = System.currentTimeMillis()
        val next = CourseActivityPlanner.plan(emptyList(), now, 15, emptySet(), true).nextAt!!
        assertTrue(next > now); assertTrue(next - now <= 25 * 3_600_000)
    }
    @Test fun isoParsingPreservesOffsetsAndMicroseconds() {
        assertEquals(CourseActivityPlanner.parseDate("2026-10-26T00:00:00.123Z"),
            CourseActivityPlanner.parseDate("2026-10-26T08:00:00.123456+08:00"))
        assertNull(CourseActivityPlanner.parseDate("2026-02-30T08:00:00"))
        assertNull(CourseActivityPlanner.parseDate("2026-10-26T08:00:00garbage"))
    }
    private fun payload(status: String = "scheduled"): JSONObject = JSONObject()
        .put("activityId", "stable-id").put("courseId", "c").put("courseName", "数学")
        .put("startTime", "2026-10-26T08:00:00.000000").put("endTime", "2026-10-26T09:50:00")
        .put("status", status)
    @Test fun completeSnapshotRemovesTerminalActivities() {
        assertTrue(CourseActivityPlanner.fromJson(JSONArray().put(payload("ended"))).isEmpty())
        assertEquals(1, CourseActivityPlanner.fromJson(JSONArray().put(payload()).put(payload())).size)
    }
    @Test(expected = IllegalArgumentException::class) fun invalidRangeRejectsTheSnapshot() {
        CourseActivityPlanner.fromJson(JSONArray().put(payload().put("endTime", "2026-10-26T07:00:00")))
    }
    @Test fun nextWeekCourseComesFromSemesterSourceAndEmptyWeeksStayUnscheduled() {
        val old = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"))
            val course = JSONObject().put("id", "next").put("name", "下周才上")
                .put("startPeriod", 1).put("periodCount", 1).put("weekDay", 1)
                .put("weeks", JSONArray().put(2))
            val emptyWeeks = JSONObject(course.toString()).put("id", "empty").put("weeks", JSONArray())
            val json = JSONObject().put("schoolId", "nju").put("currentWeek", 1).put("currentWeekDay", 1)
                .put("lastUpdateTime", "2026-10-19T12:00:00.123456+08:00")
                .put("semesterCourses", JSONArray().put(course).put(emptyWeeks))
                .put("timeTemplate", JSONObject().put("periods", JSONArray().put(
                    JSONObject().put("startTime", "08:00").put("endTime", "08:50"))))
            val data = com.lilystudio.wheretosleepinnju.widget.WidgetScheduleData.fromJson(json)
            val now = CourseActivityPlanner.parseDate("2026-10-26T07:50:00+08:00")!!
            val items = CourseActivityPlanner.fromWidget(data, now)
            assertEquals(listOf("next"), items.map { it.courseId })
            assertEquals(CourseActivityPlanner.fromWidget(data, now + 1_000).first().id, items.first().id)
        } finally { TimeZone.setDefault(old) }
    }
    @Test fun clockRollbackReprojectsTheSourceWeekInsteadOfAdvancingIt() {
        val course = JSONObject().put("id", "week1").put("name", "第一周")
            .put("startPeriod", 1).put("periodCount", 1).put("weekDay", 1).put("weeks", JSONArray().put(1))
        val json = JSONObject().put("schoolId", "nju").put("currentWeek", 2).put("currentWeekDay", 1)
            .put("timestamp", "2026-10-26T12:00:00").put("semesterCourses", JSONArray().put(course))
            .put("timeTemplate", JSONObject().put("periods", JSONArray().put(
                JSONObject().put("startTime", "08:00").put("endTime", "08:50"))))
        val data = com.lilystudio.wheretosleepinnju.widget.WidgetScheduleData.fromJson(json)
        val now = CourseActivityPlanner.parseDate("2026-10-19T07:50:00")!!
        assertEquals(listOf("week1"), CourseActivityPlanner.fromWidget(data, now).map { it.courseId })
    }

}
