package com.lilystudio.wheretosleepinnju.widget;

import org.json.JSONObject;

/**
 * JSON 读取工具。
 *
 * 说明：org.json 的 {@code optString(name, fallback)} 在遇到显式的 JSON null 时
 * 会返回字符串 "null" 而不是 fallback（因为 JSONObject.NULL 可被 String.valueOf 转换）。
 * Flutter 端 {@code WidgetCourse.toJson()} 会把 classroom / teacher 等可空字段
 * 序列化为 JSON null，因此必须先用 {@code isNull} 判断，否则界面上会显示 "null"。
 */
final class JsonUtils {

    private JsonUtils() {
    }

    static String optString(JSONObject json, String name, String fallback) {
        if (json == null || json.isNull(name)) {
            return fallback;
        }
        String value = json.optString(name, null);
        if (value == null) {
            return fallback;
        }
        value = value.trim();
        if (value.isEmpty()) {
            return fallback;
        }
        return value;
    }

    static Integer optInteger(JSONObject json, String name) {
        if (json == null || json.isNull(name)) {
            return null;
        }
        if (!json.has(name)) {
            return null;
        }
        return json.optInt(name);
    }
}
