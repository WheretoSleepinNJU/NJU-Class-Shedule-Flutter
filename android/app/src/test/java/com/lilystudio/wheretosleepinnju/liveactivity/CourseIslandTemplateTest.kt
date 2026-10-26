package com.lilystudio.wheretosleepinnju.liveactivity

import android.app.Application
import android.app.Notification
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class CourseIslandTemplateTest {
    private val context get() = RuntimeEnvironment.getApplication()
    private fun item() = CourseActivity("template", "math", "高等数学", "仙I-101", "教师", System.currentTimeMillis() + 600_000,
        System.currentTimeMillis() + 3_600_000, "#4285F4")
    @Test fun standardNotificationRetainsCountdownAndActionsWithoutCustomRemoteViews() {
        val item = item()
        val notification = CourseActivityNotification.build(context, item, false)
        assertNull(notification.contentView)
        assertEquals(item.start, notification.`when`)
        assertTrue(notification.flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertEquals(2, notification.actions.size)
        assertFalse(notification.extras.containsKey("miui.focus.param"))
    }
    @Test fun focusV3ReferencesSuppliedPicturesAndAuthenticatedActivityActions() {
        val extras = CourseIslandTemplate.create(context, item())
        val params = JSONObject(extras.getString("miui.focus.param")!!).getJSONObject("param_v2")
        val pictures = extras.getBundle("miui.focus.pics")!!
        assertTrue(pictures.containsKey(params.getString("tickerPic")))
        assertTrue(params.getBoolean("updatable"))
        val buttons = params.getJSONArray("textButton")
        assertEquals(2, buttons.length())
        for (index in 0 until buttons.length()) {
            val button = buttons.getJSONObject(index)
            assertTrue(pictures.containsKey(button.getString("actionIcon")))
            assertEquals(1, button.getInt("actionIntentType"))
            val intent = Intent.parseUri(button.getString("actionIntent"), Intent.URI_INTENT_SCHEME)
            assertEquals(CourseIslandActionActivity::class.java.name, intent.component!!.className)
            assertNotNull(intent.getStringExtra("token"))
        }
    }
    @Test fun authenticatedSerializedIslandActionEndsThePersistedOccurrence() {
        val item = item()
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
        CourseActivityStore.prefs(context).edit().clear().putBoolean("enabled", true).commit()
        CourseActivityStore.saveActivities(context, JSONArray().put(JSONObject()
            .put("activityId", item.id).put("courseId", item.courseId).put("courseName", item.name)
            .put("startTime", format.format(Date(item.start))).put("endTime", format.format(Date(item.end)))))
        val params = JSONObject(CourseIslandTemplate.create(context, item).getString("miui.focus.param")!!).getJSONObject("param_v2")
        val intent = Intent.parseUri(params.getJSONArray("textButton").getJSONObject(0).getString("actionIntent"), Intent.URI_INTENT_SCHEME)
        Robolectric.buildActivity(CourseIslandActionActivity::class.java, intent).create()
        assertTrue(CourseActivityStore.dismissed(context).contains(item.id))
        assertNull(CourseActivityEngine.current())
    }
}
