package com.lilystudio.wheretosleepinnju.widget;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * Widget 课表数据包。
 *
 * 对标 iOS 端 {@code WidgetScheduleData}，字段来自 Flutter 端
 * {@code WidgetScheduleData.toJson()}，通过 MethodChannel 下发。
 */
public class WidgetScheduleData {

    public static final int DEFAULT_APPROACHING_MINUTES = 15;
    public static final int DEFAULT_TOMORROW_PREVIEW_HOUR = 21;

    public final String version;
    public final String timestamp;
    public final String schoolId;
    public final String schoolName;
    public final SchoolTimeTemplate timeTemplate;
    public final int currentWeek;
    public final int currentWeekDay;
    public final String semesterName;
    public final List<WidgetCourse> todayCourses;
    public final List<WidgetCourse> tomorrowCourses;
    /** key 为星期（1-7），与 iOS 端一致，JSON 中是字符串键。 */
    public final Map<Integer, List<WidgetCourse>> weekSchedule;
    public final int weekCourseCount;
    public final boolean hasCoursesToday;
    public final boolean hasCoursesTomorrow;
    public final String dataSource;
    public final int totalCourses;
    public final String lastUpdateTime;
    public final Integer approachingMinutes;
    public final Integer tomorrowPreviewHour;

    public WidgetScheduleData(String version,
                              String timestamp,
                              String schoolId,
                              String schoolName,
                              SchoolTimeTemplate timeTemplate,
                              int currentWeek,
                              int currentWeekDay,
                              String semesterName,
                              List<WidgetCourse> todayCourses,
                              List<WidgetCourse> tomorrowCourses,
                              Map<Integer, List<WidgetCourse>> weekSchedule,
                              int weekCourseCount,
                              boolean hasCoursesToday,
                              boolean hasCoursesTomorrow,
                              String dataSource,
                              int totalCourses,
                              String lastUpdateTime,
                              Integer approachingMinutes,
                              Integer tomorrowPreviewHour) {
        this.version = version;
        this.timestamp = timestamp;
        this.schoolId = schoolId;
        this.schoolName = schoolName;
        this.timeTemplate = timeTemplate;
        this.currentWeek = currentWeek;
        this.currentWeekDay = currentWeekDay;
        this.semesterName = semesterName;
        this.todayCourses = todayCourses == null ? new ArrayList<WidgetCourse>() : todayCourses;
        this.tomorrowCourses = tomorrowCourses == null ? new ArrayList<WidgetCourse>() : tomorrowCourses;
        this.weekSchedule = weekSchedule == null
                ? new HashMap<Integer, List<WidgetCourse>>() : weekSchedule;
        this.weekCourseCount = weekCourseCount;
        this.hasCoursesToday = hasCoursesToday;
        this.hasCoursesTomorrow = hasCoursesTomorrow;
        this.dataSource = dataSource;
        this.totalCourses = totalCourses;
        this.lastUpdateTime = lastUpdateTime;
        this.approachingMinutes = approachingMinutes;
        this.tomorrowPreviewHour = tomorrowPreviewHour;
    }

    public static WidgetScheduleData fromJson(JSONObject json) {
        if (json == null) {
            return null;
        }

        SchoolTimeTemplate template = SchoolTimeTemplate.fromJson(json.optJSONObject("timeTemplate"));
        if (template == null) {
            // 没有时间模板时后续所有时间计算都无从谈起，直接视为无效数据。
            return null;
        }

        Map<Integer, List<WidgetCourse>> weekSchedule = new HashMap<>();
        JSONObject weekScheduleJson = json.optJSONObject("weekSchedule");
        if (weekScheduleJson != null) {
            Iterator<String> keys = weekScheduleJson.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                try {
                    int weekDay = Integer.parseInt(key);
                    weekSchedule.put(weekDay,
                            WidgetCourse.listFromJson(weekScheduleJson.optJSONArray(key)));
                } catch (NumberFormatException ignored) {
                    // 非法键直接跳过，不影响其余数据
                }
            }
        }

        List<WidgetCourse> todayCourses =
                WidgetCourse.listFromJson(json.optJSONArray("todayCourses"));
        List<WidgetCourse> tomorrowCourses =
                WidgetCourse.listFromJson(json.optJSONArray("tomorrowCourses"));

        return new WidgetScheduleData(
                JsonUtils.optString(json, "version", "2.0"),
                JsonUtils.optString(json, "timestamp", null),
                JsonUtils.optString(json, "schoolId", ""),
                JsonUtils.optString(json, "schoolName", ""),
                template,
                json.optInt("currentWeek", 1),
                json.optInt("currentWeekDay", 1),
                JsonUtils.optString(json, "semesterName", ""),
                todayCourses,
                tomorrowCourses,
                weekSchedule,
                json.optInt("weekCourseCount", 0),
                json.optBoolean("hasCoursesToday", !todayCourses.isEmpty()),
                json.optBoolean("hasCoursesTomorrow", !tomorrowCourses.isEmpty()),
                JsonUtils.optString(json, "dataSource", "local"),
                json.optInt("totalCourses", 0),
                JsonUtils.optString(json, "lastUpdateTime", null),
                JsonUtils.optInteger(json, "approachingMinutes"),
                JsonUtils.optInteger(json, "tomorrowPreviewHour")
        );
    }

    public int resolveApproachingMinutes() {
        if (approachingMinutes == null || approachingMinutes <= 0) {
            return DEFAULT_APPROACHING_MINUTES;
        }
        return approachingMinutes;
    }

    public int resolveTomorrowPreviewHour() {
        if (tomorrowPreviewHour == null || tomorrowPreviewHour < 0 || tomorrowPreviewHour > 23) {
            return DEFAULT_TOMORROW_PREVIEW_HOUR;
        }
        return tomorrowPreviewHour;
    }

    public List<WidgetCourse> coursesForWeekDay(int weekDay) {
        List<WidgetCourse> courses = weekSchedule.get(weekDay);
        return courses == null ? Collections.<WidgetCourse>emptyList() : courses;
    }

    /** 基于当前实例复制并替换今日 / 明日课程，用于跨天归一化。 */
    public WidgetScheduleData copyWithDay(int newCurrentWeek,
                                          int newCurrentWeekDay,
                                          List<WidgetCourse> newTodayCourses,
                                          List<WidgetCourse> newTomorrowCourses) {
        return new WidgetScheduleData(
                version,
                timestamp,
                schoolId,
                schoolName,
                timeTemplate,
                newCurrentWeek,
                newCurrentWeekDay,
                semesterName,
                newTodayCourses,
                newTomorrowCourses,
                weekSchedule,
                weekCourseCount,
                newTodayCourses != null && !newTodayCourses.isEmpty(),
                newTomorrowCourses != null && !newTomorrowCourses.isEmpty(),
                dataSource,
                totalCourses,
                lastUpdateTime,
                approachingMinutes,
                tomorrowPreviewHour
        );
    }
}
