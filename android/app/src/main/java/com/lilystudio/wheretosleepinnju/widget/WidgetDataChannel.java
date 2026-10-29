package com.lilystudio.wheretosleepinnju.widget;

import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.app.Activity;
import com.lilystudio.wheretosleepinnju.liveactivity.CourseLiveActivityBridge;
import com.lilystudio.wheretosleepinnju.liveactivity.CourseActivityEngine;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Widget 数据通道。
 *
 * 对接 Flutter 端 {@code lib/core/widget_data/communication/native_data_bridge.dart}，
 * 与 iOS 端 {@code AppDelegate} 暴露的方法保持同名同语义。
 */
public class WidgetDataChannel implements MethodChannel.MethodCallHandler {

    private static final String TAG = "WidgetDataChannel";

    /** 必须与 Flutter 端 NativeDataBridge._channel 完全一致。 */
    private static final String CHANNEL_NAME = "com.wheretosleepinnju/widget_data";

    private final Context context;
    private final Activity activity;
    private MethodChannel channel;

    public WidgetDataChannel(Context context) {
        this.context = context.getApplicationContext();
        this.activity = context instanceof Activity ? (Activity) context : null;
    }

    public void register(BinaryMessenger messenger) {
        channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        Log.i(TAG, "register: channel ready");
    }

    public void unregister() {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (CourseLiveActivityBridge.handle(activity, context, call, result)) return;
        switch (call.method) {
            case "sendWidgetData":
                handleSendWidgetData(call, result);
                break;
            case "refreshWidgets":
                ScheduleWidgetProvider.refreshAllWidgets(context);
                result.success(true);
                break;
            case "getDataStatus":
                result.success(buildDataStatus());
                break;
            case "getPlatformInfo":
                result.success(buildPlatformInfo());
                break;
            case "debugReadWidgetData":
                handleDebugReadWidgetData(result);
                break;
            case "clearCache":
                WidgetDataStore.clearAll(context);
                CourseActivityEngine.clear(context);
                ScheduleWidgetProvider.refreshAllWidgets(context);
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    // ------------------------------------------------------------------

    private void handleSendWidgetData(MethodCall call, MethodChannel.Result result) {
        Object rawArgs = call.argument("data");
        if (!(rawArgs instanceof Map)) {
            Log.e(TAG, "sendWidgetData: missing 'data' field");
            result.error("INVALID_DATA", "Missing 'data' field", null);
            return;
        }

        String json = mapToJsonString((Map<?, ?>) rawArgs);
        if (json == null) {
            result.error("SERIALIZE_ERROR", "Failed to serialize widget data", null);
            return;
        }

        boolean saved = WidgetDataStore.saveWidgetData(context, json);
        if (!saved) {
            result.error("SAVE_ERROR", "Failed to persist widget data", null);
            return;
        }

        CourseActivityEngine.onWidgetData(context);
        ScheduleWidgetProvider.refreshAllWidgets(context);
        Log.i(TAG, "sendWidgetData: saved and widgets refreshed");
        result.success(true);
    }

    private void handleDebugReadWidgetData(MethodChannel.Result result) {
        String raw = WidgetDataStore.loadRawWidgetData(context);
        if (raw == null) {
            result.error("NO_DATA", "No widget_data found", null);
            return;
        }
        try {
            result.success(jsonToMap(new JSONObject(raw)));
        } catch (JSONException e) {
            result.error("PARSE_ERROR", e.getMessage(), null);
        }
    }

    private Map<String, Object> buildDataStatus() {
        Map<String, Object> status = new HashMap<>();
        status.putAll(CourseLiveActivityBridge.status(context));
        status.put("hasWidgetData", WidgetDataStore.hasData(context));
        status.put("lastUpdateTime", WidgetDataStore.getLastUpdateTime(context));
        status.put("widgetCount", countPlacedWidgets());
        return status;
    }

    private Map<String, Object> buildPlatformInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("platform", "android");
        info.put("version", Build.VERSION.RELEASE);
        info.put("model", Build.MODEL);
        info.put("supportsWidgets", true);
        info.put("supportsLiveActivities", true);
        info.putAll(CourseLiveActivityBridge.status(context));
        info.put("widgetCount", countPlacedWidgets());
        return info;
    }

    private int countPlacedWidgets() {
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        int[] ids = manager.getAppWidgetIds(
                new ComponentName(context, ScheduleWidgetProvider.class));
        return ids == null ? 0 : ids.length;
    }

    // ------------------------------------------------------------------
    // Map <-> JSON
    // ------------------------------------------------------------------

    /**
     * 把 MethodChannel 传来的 Map 转成 JSON 文本。
     * 注意：Dart 的 null 会变成 Java null，直接放进 JSONObject 会丢键，
     * 这里显式转成 JSONObject.NULL，保证与 iOS 收到的结构一致。
     */
    private static String mapToJsonString(Map<?, ?> map) {
        try {
            return toJsonObject(map).toString();
        } catch (JSONException e) {
            Log.e(TAG, "mapToJsonString failed", e);
            return null;
        }
    }

    private static JSONObject toJsonObject(Map<?, ?> map) throws JSONException {
        JSONObject json = new JSONObject();
        for (Map.Entry<?, ?> entry : map.entrySet()) {
            Object key = entry.getKey();
            if (key == null) {
                continue;
            }
            json.put(String.valueOf(key), toJsonValue(entry.getValue()));
        }
        return json;
    }

    private static Object toJsonValue(Object value) throws JSONException {
        if (value == null) {
            return JSONObject.NULL;
        }
        if (value instanceof Map) {
            return toJsonObject((Map<?, ?>) value);
        }
        if (value instanceof Iterable) {
            org.json.JSONArray array = new org.json.JSONArray();
            for (Object item : (Iterable<?>) value) {
                array.put(toJsonValue(item));
            }
            return array;
        }
        return value;
    }

    private static Map<String, Object> jsonToMap(JSONObject json) throws JSONException {
        Map<String, Object> map = new HashMap<>();
        java.util.Iterator<String> keys = json.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            Object value = json.get(key);
            if (value == JSONObject.NULL) {
                map.put(key, null);
            } else if (value instanceof JSONObject) {
                map.put(key, jsonToMap((JSONObject) value));
            } else if (value instanceof org.json.JSONArray) {
                map.put(key, jsonToList((org.json.JSONArray) value));
            } else {
                map.put(key, value);
            }
        }
        return map;
    }

    private static java.util.List<Object> jsonToList(org.json.JSONArray array) throws JSONException {
        java.util.List<Object> list = new java.util.ArrayList<>();
        for (int i = 0; i < array.length(); i++) {
            Object value = array.get(i);
            if (value == JSONObject.NULL) {
                list.add(null);
            } else if (value instanceof JSONObject) {
                list.add(jsonToMap((JSONObject) value));
            } else if (value instanceof org.json.JSONArray) {
                list.add(jsonToList((org.json.JSONArray) value));
            } else {
                list.add(value);
            }
        }
        return list;
    }
}
