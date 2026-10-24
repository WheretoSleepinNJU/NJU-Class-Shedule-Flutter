package com.lilystudio.wheretosleepinnju.widget;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Widget 数据存储。
 *
 * 对标 iOS 端 {@code WidgetDataManager}。iOS 通过 App Group 的 UserDefaults 在
 * 宿主 App 与 Widget Extension 之间共享数据；Android 的 AppWidgetProvider 与
 * 宿主 App 同属一个进程组、共享同一份 SharedPreferences，因此这里直接使用
 * 独立的 SharedPreferences 文件，避免与 Flutter 插件写入的 key 冲突。
 */
public class WidgetDataStore {

    private static final String TAG = "WidgetDataStore";

    /** 独立存储文件，不与 shared_preferences 插件（FlutterSharedPreferences）混用。 */
    private static final String PREFS_NAME = "nju_schedule_widget";

    static final String KEY_WIDGET_DATA = "widget_data";
    static final String KEY_LAST_UPDATE_TIME = "last_update_time";
    static final String KEY_ARRIVED_COURSE_ID = "arrived_course_id";
    static final String KEY_ARRIVED_COURSE_TIME = "arrived_course_time";

    private WidgetDataStore() {
    }

    private static SharedPreferences prefs(Context context) {
        return context.getApplicationContext()
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    /**
     * 保存 Flutter 下发的 Widget 数据。
     *
     * @param jsonString 完整的 WidgetScheduleData JSON 文本
     * @return 是否保存成功
     */
    public static boolean saveWidgetData(Context context, String jsonString) {
        if (jsonString == null || jsonString.isEmpty()) {
            Log.w(TAG, "saveWidgetData: empty payload, ignored");
            return false;
        }

        // 写入前先校验可解析，避免把坏数据落盘后 Widget 永久白屏。
        try {
            new JSONObject(jsonString);
        } catch (JSONException e) {
            Log.e(TAG, "saveWidgetData: invalid json, ignored", e);
            return false;
        }

        boolean committed = prefs(context).edit()
                .putString(KEY_WIDGET_DATA, jsonString)
                .putLong(KEY_LAST_UPDATE_TIME, System.currentTimeMillis())
                .commit();

        if (committed) {
            Log.i(TAG, "saveWidgetData: saved " + jsonString.length() + " chars");
        } else {
            Log.e(TAG, "saveWidgetData: commit failed");
        }
        return committed;
    }

    /** 读取原始 JSON 文本，未保存过时返回 null。 */
    public static String loadRawWidgetData(Context context) {
        return prefs(context).getString(KEY_WIDGET_DATA, null);
    }

    /** 读取并解析 Widget 数据，无数据或解析失败时返回 null。 */
    public static WidgetScheduleData loadWidgetData(Context context) {
        String raw = loadRawWidgetData(context);
        if (raw == null || raw.isEmpty()) {
            Log.w(TAG, "loadWidgetData: no data stored yet");
            return null;
        }

        try {
            WidgetScheduleData data = WidgetScheduleData.fromJson(new JSONObject(raw));
            if (data == null) {
                Log.e(TAG, "loadWidgetData: parsed to null (missing timeTemplate?)");
            }
            return data;
        } catch (JSONException e) {
            Log.e(TAG, "loadWidgetData: parse failed", e);
            return null;
        }
    }

    public static long getLastUpdateTime(Context context) {
        return prefs(context).getLong(KEY_LAST_UPDATE_TIME, 0L);
    }

    /** 记录"我已到达"的课程，用于让小组件维持上课中状态。 */
    public static void setArrivedCourse(Context context, String courseId) {
        prefs(context).edit()
                .putString(KEY_ARRIVED_COURSE_ID, courseId)
                .putLong(KEY_ARRIVED_COURSE_TIME, System.currentTimeMillis())
                .apply();
    }

    public static String getArrivedCourseId(Context context) {
        return prefs(context).getString(KEY_ARRIVED_COURSE_ID, null);
    }

    public static long getArrivedCourseTime(Context context) {
        return prefs(context).getLong(KEY_ARRIVED_COURSE_TIME, 0L);
    }

    public static void clearArrivedCourse(Context context) {
        prefs(context).edit()
                .remove(KEY_ARRIVED_COURSE_ID)
                .remove(KEY_ARRIVED_COURSE_TIME)
                .apply();
    }

    public static void clearAll(Context context) {
        prefs(context).edit().clear().apply();
        Log.i(TAG, "clearAll: widget data cleared");
    }

    public static boolean hasData(Context context) {
        return prefs(context).contains(KEY_WIDGET_DATA);
    }
}
