package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Application
import android.content.Context
import android.content.Intent
import com.lilystudio.wheretosleepinnju.widget.WidgetDataStore
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class CourseActivityLifecycleTest {
    private lateinit var context: Context
    private fun iso(time: Long) = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date(time))
    private fun upcoming(id: String = "today", start: Long = System.currentTimeMillis() + 600_000) = JSONObject()
        .put("activityId", id).put("courseId", "c").put("courseName", "数学")
        .put("startTime", iso(start)).put("endTime", iso(start + 3_000_000))
    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        CourseActivityStore.prefs(context).edit().clear().commit()
        WidgetDataStore.clearAll(context)
        context.getSharedPreferences("island_bypass", 0).edit().clear().commit()
        CourseActivityEngine.clear(context)
    }
    private fun enable() { CourseActivityStore.prefs(context).edit().putBoolean("enabled", true).commit() }
    @Test fun disabledDoesNotScheduleOrPost() {
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.reconcile(context, false)
        assertNull(CourseActivityEngine.current())
        assertEquals(0L, CourseActivityStore.prefs(context).getLong("nextAt", 0))
        assertEquals(0, CourseActivityNotification.manager(context).activeNotifications.size)
    }
    @Test fun schedulesWithoutAnyInstalledWidgetAndBootRebuildsPersistedState() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertEquals("today", CourseActivityEngine.current()?.id)
        assertTrue(CourseActivityStore.prefs(context).getLong("nextAt", 0) > System.currentTimeMillis())
        assertEquals(1, CourseActivityNotification.manager(context).activeNotifications.size)
        assertNull(org.robolectric.Shadows.shadowOf(context as Application).nextStartedService)
    }
    @Test fun emptyReplacementCancelsNotificationAndAlarm() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.reconcile(context, false)
        CourseActivityStore.saveActivities(context, JSONArray())
        CourseActivityEngine.reconcile(context, false)
        assertNull(CourseActivityEngine.current())
        assertEquals(0, CourseActivityNotification.manager(context).activeNotifications.size)
        assertEquals(0L, CourseActivityStore.prefs(context).getLong("nextAt", 0))
    }
    @Test fun dismissedOccurrenceDoesNotReappearAfterClockOrBootRecovery() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.reconcile(context, false)
        CourseActivityEngine.dismiss(context, "today", false)
        CourseActivityReceiver().onReceive(context, Intent(Intent.ACTION_TIME_CHANGED))
        CourseActivityReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertNull(CourseActivityEngine.current())
        assertTrue(CourseActivityStore.dismissed(context).contains("today"))
    }
    @Test fun arrivalUpdatesWidgetStateWithoutFlutter() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.dismiss(context, "today", true)
        assertEquals("c", WidgetDataStore.getArrivedCourseId(context))
        assertNull(CourseActivityEngine.current())
    }
    @Test fun malformedReplacementPreservesThePreviousSchedule() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        try { CourseActivityStore.saveActivities(context, JSONArray().put(upcoming().put("startTime", "bad"))); fail() }
        catch (_: IllegalArgumentException) { }
        CourseActivityEngine.reconcile(context, false)
        assertEquals("today", CourseActivityEngine.current()?.id)
    }
    @Test fun staleButtonCannotDismissAReplacementOccurrence() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming("replacement")))
        CourseActivityEngine.dismiss(context, "old", true)
        CourseActivityEngine.reconcile(context, false)
        assertEquals("replacement", CourseActivityEngine.current()?.id)
        assertNull(WidgetDataStore.getArrivedCourseId(context))
    }
    @Test fun forgedIslandActionCannotDismissTheActivity() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        org.robolectric.Robolectric.buildActivity(CourseIslandActionActivity::class.java,
            Intent().setAction(CourseActivityReceiver.DISMISS).putExtra("activityId", "today").putExtra("token", "forged")).create()
        CourseActivityEngine.reconcile(context, false)
        assertEquals("today", CourseActivityEngine.current()?.id)
    }
    private class Result : io.flutter.plugin.common.MethodChannel.Result {
        var value: Any? = null
        var error: String? = null
        override fun success(result: Any?) { value = result }
        override fun error(code: String, message: String?, details: Any?) { error = code }
        override fun notImplemented() { error = "notImplemented" }
    }
    @Test fun existingFlutterMethodAcceptsSnapshotAndRejectsMalformedReplacement() {
        enable()
        val result = Result()
        val start = System.currentTimeMillis() + 600_000
        val value = mapOf("activityId" to "bridge", "courseId" to "c", "courseName" to "数学",
            "startTime" to iso(start), "endTime" to iso(start + 3_000_000))
        assertTrue(CourseLiveActivityBridge.handle(null, context,
            io.flutter.plugin.common.MethodCall("sendLiveActivityData", mapOf("activities" to listOf(value))), result))
        assertEquals(true, result.value); assertNull(result.error)
        assertEquals("bridge", CourseActivityEngine.current()?.id)
        val invalid = Result()
        CourseLiveActivityBridge.handle(null, context,
            io.flutter.plugin.common.MethodCall("sendLiveActivityData", mapOf("activities" to listOf(value + ("startTime" to "invalid")))), invalid)
        assertEquals("LIVE_ACTIVITY_ERROR", invalid.error)
        assertEquals("bridge", CourseActivityEngine.current()?.id)
        val empty = Result()
        CourseLiveActivityBridge.handle(null, context,
            io.flutter.plugin.common.MethodCall("sendLiveActivityData", mapOf("activities" to emptyList<Any>())), empty)
        assertEquals(true, empty.value); assertNull(CourseActivityEngine.current())
    }
    @Test fun countdownServiceStopsWhenTheLastActivityIsRemoved() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        val service = org.robolectric.Robolectric.buildService(CourseActivityService::class.java).create().startCommand(0, 0)
        assertNotNull(CourseActivityEngine.current())
        CourseActivityStore.saveActivities(context, JSONArray())
        CourseActivityEngine.reconcile(context, false)
        assertNull(CourseActivityEngine.current())
        assertEquals(0, CourseActivityNotification.manager(context).activeNotifications.size)
        service.destroy()
    }

    @Test fun missingSystemNotificationIsRepublishedEvenWhenOccurrenceHasNotChanged() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.reconcile(context, false)
        CourseActivityNotification.manager(context).cancel(CourseActivityNotification.ID)
        CourseActivityEngine.reconcile(context, false)
        assertEquals(1, CourseActivityNotification.manager(context).activeNotifications.size)
    }
    @Test fun statusExplainsAbsentTimetableAndFutureReminderWindow() {
        enable()
        assertEquals("noData", CourseLiveActivityBridge.status(context)["state"])
        val start = System.currentTimeMillis() + 3_600_000
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming(start = start)))
        CourseActivityEngine.reconcile(context, false)
        val status = CourseLiveActivityBridge.status(context)
        assertEquals("waiting", status["state"])
        assertEquals(start, status["nextCourseAt"])
        assertEquals(start - 900_000, status["windowStartAt"])
        assertEquals(false, status["notificationPosted"])
    }
    @Test fun previewPublishesImmediatelyAndExpiresWithoutReplacingRealSnapshot() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityStore.startPreview(context)
        CourseActivityEngine.reconcile(context, false)
        assertEquals("preview", CourseActivityEngine.current()?.courseId)
        assertEquals(true, CourseLiveActivityBridge.status(context)["notificationPosted"])
        // Evaluate the exact wall-clock expiry boundary. Advancing Robolectric's
        // uptime alone does not advance System.currentTimeMillis in this harness.
        val expires = CourseActivityEngine.current()!!.start
        assertNull(CourseActivityStore.preview(context, expires))
        CourseActivityEngine.reconcile(context, false)
        assertEquals("today", CourseActivityEngine.current()?.id)
        assertNull(CourseActivityStore.preview(context, System.currentTimeMillis()))
    }
    @Test fun previewArrivalDoesNotMarkACourseOrForgetExistingDismissals() {
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityStore.dismiss(context, "today")
        CourseActivityStore.startPreview(context)
        CourseActivityEngine.reconcile(context, false)
        CourseActivityEngine.dismiss(context, CourseActivityEngine.current()!!.id, true)
        assertNull(CourseActivityEngine.current())
        assertNull(WidgetDataStore.getArrivedCourseId(context))
        assertTrue(CourseActivityStore.dismissed(context).contains("today"))
    }
    @Test fun blockedNotificationsProduceAnExplicitReasonAndRejectPreview() {
        enable()
        org.robolectric.Shadows.shadowOf(CourseActivityNotification.manager(context)).setNotificationsEnabled(false)
        assertEquals("permissionDenied", CourseLiveActivityBridge.status(context)["state"])
        val result = Result()
        CourseLiveActivityBridge.handle(null, context,
            io.flutter.plugin.common.MethodCall("testLiveActivity", null), result)
        assertEquals("LIVE_ACTIVITY_ERROR", result.error)
        assertNull(CourseActivityStore.preview(context, System.currentTimeMillis()))
    }
    @Test fun nativeFallbackIsAlreadyPostedWhilePrivilegedBackendIsPending() {
        org.robolectric.util.ReflectionHelpers.setStaticField(android.os.Build::class.java, "MANUFACTURER", "Xiaomi")
        context.getSharedPreferences("island_bypass", 0).edit().putString("mode", "SHIZUKU").commit()
        enable()
        CourseActivityStore.saveActivities(context, JSONArray().put(upcoming()))
        CourseActivityEngine.reconcile(context, false)
        val notification = CourseActivityNotification.manager(context).activeNotifications.single().notification
        assertFalse(notification.extras.containsKey("miui.focus.param"))
        assertEquals("notification", CourseLiveActivityBridge.status(context)["surface"])
    }

}
