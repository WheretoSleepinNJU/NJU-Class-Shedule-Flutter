package com.lilystudio.wheretosleepinnju.widget;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * 学校作息时间模板。
 *
 * 对标 iOS 端 {@code SchoolTimeTemplate}，节次为 1-based。
 */
public class SchoolTimeTemplate {

    /** 单节课的起止时间，形如 "08:00" / "08:50"。 */
    public static class ClassPeriod {
        public final String startTime;
        public final String endTime;

        public ClassPeriod(String startTime, String endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }

    public final String schoolId;
    public final String schoolName;
    public final String schoolNameEn;
    public final List<ClassPeriod> periods;

    public SchoolTimeTemplate(String schoolId,
                              String schoolName,
                              String schoolNameEn,
                              List<ClassPeriod> periods) {
        this.schoolId = schoolId;
        this.schoolName = schoolName;
        this.schoolNameEn = schoolNameEn;
        this.periods = periods == null ? new ArrayList<ClassPeriod>() : periods;
    }

    public static SchoolTimeTemplate fromJson(JSONObject json) {
        if (json == null) {
            return null;
        }

        List<ClassPeriod> periods = new ArrayList<>();
        JSONArray periodsArray = json.optJSONArray("periods");
        if (periodsArray != null) {
            for (int i = 0; i < periodsArray.length(); i++) {
                JSONObject periodJson = periodsArray.optJSONObject(i);
                if (periodJson == null) {
                    continue;
                }
                String start = JsonUtils.optString(periodJson, "startTime", null);
                String end = JsonUtils.optString(periodJson, "endTime", null);
                if (start == null || end == null) {
                    continue;
                }
                periods.add(new ClassPeriod(start, end));
            }
        }

        return new SchoolTimeTemplate(
                JsonUtils.optString(json, "schoolId", ""),
                JsonUtils.optString(json, "schoolName", ""),
                JsonUtils.optString(json, "schoolNameEn", ""),
                periods
        );
    }

    /** 取单个节次的时间段，越界返回 null。 */
    public ClassPeriod getPeriod(int periodNumber) {
        if (periodNumber <= 0 || periodNumber > periods.size()) {
            return null;
        }
        return periods.get(periodNumber - 1);
    }

    /**
     * 取跨若干节次的合并时间段：起点取 startPeriod 的开始时间，终点取最后一节的结束时间。
     * 与 iOS 端 {@code getPeriodRange} 行为一致，越界返回 null。
     */
    public ClassPeriod getPeriodRange(int startPeriod, int periodCount) {
        if (startPeriod <= 0 || startPeriod > periods.size()) {
            return null;
        }
        int endPeriod = startPeriod + periodCount - 1;
        if (endPeriod > periods.size() || endPeriod < startPeriod) {
            return null;
        }
        return new ClassPeriod(
                periods.get(startPeriod - 1).startTime,
                periods.get(endPeriod - 1).endTime
        );
    }

    public boolean isEmpty() {
        return periods.isEmpty();
    }
}
