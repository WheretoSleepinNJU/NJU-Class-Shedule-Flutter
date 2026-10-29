package com.lilystudio.wheretosleepinnju.liveactivity

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import com.lilystudio.wheretosleepinnju.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Focus V3 param_v2/param_island, adapted from Deadliner's notification adapter. */
internal object CourseIslandTemplate {
    private const val APP_PIC = "miui.focus.pic_nju_course"
    private const val SMALL_PIC = "miui.land.pic_nju_course"
    fun supportsIsland() = Build.VERSION.SDK_INT >= 35 && listOf("xiaomi", "redmi", "poco").any {
        Build.MANUFACTURER.equals(it, true) || Build.BRAND.equals(it, true)
    }
    private fun icon(context: Context, resource: Int, size: Int): Icon {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        requireNotNull(context.getDrawable(resource)).apply { setBounds(0, 0, size, size); draw(Canvas(bitmap)) }
        return Icon.createWithBitmap(bitmap)
    }
    fun create(context: Context, item: CourseActivity): Bundle {
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(item.start))
        val content = listOfNotNull(item.classroom, item.teacher).joinToString(" · ")
        val picture = JSONObject().put("type", 1).put("pic", APP_PIC)
        // Display an absolute start time so no per-second privileged network windows are needed.
        val island = JSONObject().put("islandProperty", 1)
            .put("bigIslandArea", JSONObject().put("imageTextInfoLeft", JSONObject().put("type", 1)
                .put("picInfo", picture).put("textInfo", JSONObject().put("title", item.classroom ?: item.name).put("narrowFont", false)))
                .put("textInfo", JSONObject().put("title", time).put("narrowFont", false)))
            .put("smallIslandArea", JSONObject().put("combinePicInfo", JSONObject().put("picInfo",
                JSONObject().put("type", 1).put("pic", SMALL_PIC))))
        val pictures = Bundle().apply {
            putParcelable(APP_PIC, icon(context, R.mipmap.ic_launcher, 120))
            putParcelable(SMALL_PIC, icon(context, R.drawable.ic_course_live, 88))
        }
        val buttons = JSONArray()
        listOf("我已到达" to CourseActivityReceiver.ARRIVED, "关闭本次提醒" to CourseActivityReceiver.DISMISS).forEachIndexed { index, (label, action) ->
            val key = "miui.focus.pic_course_action_$index"
            pictures.putParcelable(key, icon(context, R.drawable.ic_course_live, 88))
            // Explicit immutable identity; receiver verifies the currently scheduled occurrence.
            buttons.put(JSONObject().put("type", 0).put("actionTitle", label).put("actionIcon", key)
                .put("actionIntentType", 1).put("actionIntent", CourseIslandActionActivity.intent(context, item, action).toUri(Intent.URI_INTENT_SCHEME)))
        }
        val params = JSONObject().put("business", "nju_course_upcoming").put("isShowNotification", true)
            .put("enableFloat", false).put("updatable", true).put("islandFirstFloat", false)
            .put("filterWhenNoPermission", false).put("ticker", "即将上课 $time").put("tickerPic", APP_PIC)
            .put("aodTitle", "${item.name} $time").put("picInfo", picture).put("param_island", island)
            .put("iconTextInfo", JSONObject().put("animIconInfo", JSONObject().put("type", 0).put("src", APP_PIC).put("srcDark", APP_PIC))
                .put("title", item.name).put("content", content).put("subContent", "$time 上课"))
            .put("textButton", buttons)
        return Bundle().apply {
            putString("miui.focus.param", JSONObject().put("param_v2", params).toString())
            putBundle("miui.focus.pics", pictures)
        }
    }
}
