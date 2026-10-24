package com.lilystudio.wheretosleepinnju.widget;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Widget 课程模型。
 *
 * 与 iOS 端 {@code ios/Runner/WidgetDataModels.swift} 中的 {@code WidgetCourse}
 * 以及 Flutter 端 {@code lib/core/widget_data/models/widget_course.dart} 保持字段一致。
 */
public class WidgetCourse {

    public final String id;
    public final String name;
    public final String classroom;
    public final String teacher;
    public final int startPeriod;
    public final int periodCount;
    public final int weekDay;
    public final String color;
    public final String schoolId;
    public final List<Integer> weeks;
    public final String courseType;
    public final String notes;

    public WidgetCourse(String id,
                        String name,
                        String classroom,
                        String teacher,
                        int startPeriod,
                        int periodCount,
                        int weekDay,
                        String color,
                        String schoolId,
                        List<Integer> weeks,
                        String courseType,
                        String notes) {
        this.id = id;
        this.name = name;
        this.classroom = classroom;
        this.teacher = teacher;
        this.startPeriod = startPeriod;
        this.periodCount = periodCount;
        this.weekDay = weekDay;
        this.color = color;
        this.schoolId = schoolId;
        this.weeks = weeks == null ? new ArrayList<Integer>() : weeks;
        this.courseType = courseType;
        this.notes = notes;
    }

    public static WidgetCourse fromJson(JSONObject json) {
        if (json == null) {
            return null;
        }

        List<Integer> weeks = new ArrayList<>();
        JSONArray weeksArray = json.optJSONArray("weeks");
        if (weeksArray != null) {
            for (int i = 0; i < weeksArray.length(); i++) {
                weeks.add(weeksArray.optInt(i));
            }
        }

        return new WidgetCourse(
                JsonUtils.optString(json, "id", ""),
                JsonUtils.optString(json, "name", "未知课程"),
                JsonUtils.optString(json, "classroom", null),
                JsonUtils.optString(json, "teacher", null),
                json.optInt("startPeriod", 1),
                json.optInt("periodCount", 1),
                json.optInt("weekDay", 1),
                JsonUtils.optString(json, "color", null),
                JsonUtils.optString(json, "schoolId", ""),
                weeks,
                JsonUtils.optString(json, "courseType", null),
                JsonUtils.optString(json, "notes", null)
        );
    }

    public static List<WidgetCourse> listFromJson(JSONArray array) {
        List<WidgetCourse> courses = new ArrayList<>();
        if (array == null) {
            return courses;
        }
        for (int i = 0; i < array.length(); i++) {
            WidgetCourse course = fromJson(array.optJSONObject(i));
            if (course != null) {
                courses.add(course);
            }
        }
        return courses;
    }

    /** 课程是否在指定周次上课。周次列表为空时视为每周都上。 */
    public boolean isActiveInWeek(int week) {
        return weeks.isEmpty() || weeks.contains(week);
    }

    public boolean hasClassroom() {
        return classroom != null && !classroom.trim().isEmpty();
    }

    public boolean hasTeacher() {
        return teacher != null && !teacher.trim().isEmpty();
    }

    @Override
    public String toString() {
        return "WidgetCourse{" + name + ", weekDay=" + weekDay
                + ", startPeriod=" + startPeriod + ", periodCount=" + periodCount + "}";
    }
}
