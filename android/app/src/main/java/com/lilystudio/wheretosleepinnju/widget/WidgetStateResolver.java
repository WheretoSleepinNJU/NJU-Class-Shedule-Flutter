package com.lilystudio.wheretosleepinnju.widget;

import android.content.Context;
import android.util.Log;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * Widget 状态解析器。
 *
 * 完整对标 iOS 端 {@code ios/ScheduleWidget/ScheduleWidget.swift} 的逻辑：
 * 课程定位（当前课 / 下一节课）、七种显示状态判定、以及数据过期时的跨天归一化。
 */
public class WidgetStateResolver {

    private static final String TAG = "WidgetStateResolver";

    /** "已到达"状态的兜底有效期，与 iOS 端一致为 30 分钟。 */
    private static final long ARRIVED_VALID_DURATION_MS = 30 * 60 * 1000L;

    /** 显示状态，与 iOS 端 {@code WidgetDisplayState} 一一对应。 */
    public enum DisplayState {
        BEFORE_FIRST_CLASS,
        BETWEEN_CLASSES,
        APPROACHING_CLASS,
        IN_CLASS,
        CLASSES_ENDED,
        TOMORROW_PREVIEW,
        ERROR
    }

    /** 一次渲染所需的全部信息。 */
    public static class WidgetState {
        public final WidgetScheduleData data;
        public final DisplayState displayState;
        public final WidgetCourse currentCourse;
        public final WidgetCourse nextCourse;
        public final String errorMessage;
        public final Date referenceDate;

        WidgetState(WidgetScheduleData data,
                    DisplayState displayState,
                    WidgetCourse currentCourse,
                    WidgetCourse nextCourse,
                    String errorMessage,
                    Date referenceDate) {
            this.data = data;
            this.displayState = displayState;
            this.currentCourse = currentCourse;
            this.nextCourse = nextCourse;
            this.errorMessage = errorMessage;
            this.referenceDate = referenceDate;
        }

        public boolean hasData() {
            return data != null;
        }

        public SchoolTimeTemplate timeTemplate() {
            return data == null ? null : data.timeTemplate;
        }

        public List<WidgetCourse> todayCourses() {
            return data == null ? Collections.<WidgetCourse>emptyList() : data.todayCourses;
        }

        public List<WidgetCourse> tomorrowCourses() {
            return data == null ? Collections.<WidgetCourse>emptyList() : data.tomorrowCourses;
        }
    }

    private WidgetStateResolver() {
    }

    // ------------------------------------------------------------------
    // 入口
    // ------------------------------------------------------------------

    public static WidgetState resolve(Context context) {
        return resolve(context, new Date());
    }

    public static WidgetState resolve(Context context, Date now) {
        WidgetScheduleData raw = WidgetDataStore.loadWidgetData(context);
        if (raw == null) {
            return new WidgetState(null, DisplayState.ERROR, null, null, "打开应用更新数据", now);
        }

        WidgetScheduleData data = normalizeForCurrentDay(raw, now);

        WidgetCourse arrivedCourse = resolveArrivedCourse(context, data, now);

        WidgetCourse currentCourse;
        WidgetCourse nextCourse;
        if (arrivedCourse != null) {
            currentCourse = arrivedCourse;
            nextCourse = courseAfter(data.todayCourses, arrivedCourse);
        } else {
            currentCourse = findCurrentCourse(data, now);
            nextCourse = findNextCourse(data, now);
        }

        DisplayState state = determineDisplayState(data, currentCourse, nextCourse,
                arrivedCourse != null, now);

        return new WidgetState(data, state, currentCourse, nextCourse, null, now);
    }

    // ------------------------------------------------------------------
    // 课程定位
    // ------------------------------------------------------------------

    /** 查找当前正在上的课：开始时间 <= now < 结束时间。 */
    static WidgetCourse findCurrentCourse(WidgetScheduleData data, Date now) {
        SchoolTimeTemplate template = data.timeTemplate;
        for (WidgetCourse course : data.todayCourses) {
            SchoolTimeTemplate.ClassPeriod period =
                    template.getPeriodRange(course.startPeriod, course.periodCount);
            if (period == null) {
                continue;
            }
            Date start = parseTimeOnDate(period.startTime, now);
            Date end = parseTimeOnDate(period.endTime, now);
            if (start == null || end == null) {
                continue;
            }
            if (!now.before(start) && now.before(end)) {
                return course;
            }
        }
        return null;
    }

    /** 查找下一节课：开始时间严格晚于 now 的课程中最早的一节。 */
    static WidgetCourse findNextCourse(WidgetScheduleData data, Date now) {
        SchoolTimeTemplate template = data.timeTemplate;
        WidgetCourse next = null;
        Date nextStart = null;

        for (WidgetCourse course : data.todayCourses) {
            SchoolTimeTemplate.ClassPeriod period =
                    template.getPeriodRange(course.startPeriod, course.periodCount);
            if (period == null) {
                continue;
            }
            Date start = parseTimeOnDate(period.startTime, now);
            if (start == null || !start.after(now)) {
                continue;
            }
            if (nextStart == null || start.before(nextStart)) {
                next = course;
                nextStart = start;
            }
        }
        return next;
    }

    /** 取 target 在今日课程序列中的下一节课。 */
    private static WidgetCourse courseAfter(List<WidgetCourse> courses, WidgetCourse target) {
        int index = indexOfCourse(courses, target);
        if (index < 0 || index + 1 >= courses.size()) {
            return null;
        }
        return courses.get(index + 1);
    }

    public static int indexOfCourse(List<WidgetCourse> courses, WidgetCourse target) {
        if (courses == null || target == null) {
            return -1;
        }
        for (int i = 0; i < courses.size(); i++) {
            WidgetCourse course = courses.get(i);
            if (course != null && course.id != null && course.id.equals(target.id)) {
                return i;
            }
        }
        return -1;
    }

    // ------------------------------------------------------------------
    // 状态判定（顺序与 iOS 端 determineDisplayState 完全一致）
    // ------------------------------------------------------------------

    static DisplayState determineDisplayState(WidgetScheduleData data,
                                              WidgetCourse currentCourse,
                                              WidgetCourse nextCourse,
                                              boolean hasArrivedCourse,
                                              Date now) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(now);
        int currentHour = calendar.get(Calendar.HOUR_OF_DAY);

        int tomorrowPreviewHour = data.resolveTomorrowPreviewHour();
        int approachingMinutes = data.resolveApproachingMinutes();

        // 1. 晚间之后优先显示明日预览
        if (currentHour >= tomorrowPreviewHour && !data.tomorrowCourses.isEmpty()) {
            return DisplayState.TOMORROW_PREVIEW;
        }

        // 2. 正在上课（"我已到达"优先）
        if (hasArrivedCourse || currentCourse != null) {
            return DisplayState.IN_CLASS;
        }

        // 3. 即将上课
        if (nextCourse != null) {
            Integer minutesUntil = minutesUntilCourse(nextCourse, data.timeTemplate, now);
            if (minutesUntil != null && minutesUntil > 0 && minutesUntil <= approachingMinutes) {
                return DisplayState.APPROACHING_CLASS;
            }
        }

        // 4. 今日还有课：区分第一节课前与课间
        if (nextCourse != null) {
            List<WidgetCourse> todayCourses = data.todayCourses;
            if (!todayCourses.isEmpty()) {
                WidgetCourse first = todayCourses.get(0);
                if (first.id != null && first.id.equals(nextCourse.id)) {
                    return DisplayState.BEFORE_FIRST_CLASS;
                }
            }
            return DisplayState.BETWEEN_CLASSES;
        }

        // 5. 今日课程已结束
        return DisplayState.CLASSES_ENDED;
    }

    /** 距离课程开始还有多少分钟，无法计算时返回 null。 */
    public static Integer minutesUntilCourse(WidgetCourse course,
                                             SchoolTimeTemplate template,
                                             Date from) {
        if (course == null || template == null) {
            return null;
        }
        SchoolTimeTemplate.ClassPeriod period =
                template.getPeriodRange(course.startPeriod, course.periodCount);
        if (period == null) {
            return null;
        }
        Date start = parseTimeOnDate(period.startTime, from);
        if (start == null) {
            return null;
        }
        long diffMs = start.getTime() - from.getTime();
        return (int) (diffMs / 60000L);
    }

    // ------------------------------------------------------------------
    // "我已到达"
    // ------------------------------------------------------------------

    private static WidgetCourse resolveArrivedCourse(Context context,
                                                     WidgetScheduleData data,
                                                     Date now) {
        String arrivedId = WidgetDataStore.getArrivedCourseId(context);
        long arrivedTime = WidgetDataStore.getArrivedCourseTime(context);
        if (arrivedId == null || arrivedTime <= 0) {
            return null;
        }

        WidgetCourse arrived = null;
        for (WidgetCourse course : data.todayCourses) {
            if (arrivedId.equals(course.id)) {
                arrived = course;
                break;
            }
        }
        if (arrived == null) {
            WidgetDataStore.clearArrivedCourse(context);
            return null;
        }

        // 跨天的到达状态无效
        if (!isSameDay(new Date(arrivedTime), now)) {
            WidgetDataStore.clearArrivedCourse(context);
            return null;
        }

        // 课程已结束则清除
        SchoolTimeTemplate.ClassPeriod period =
                data.timeTemplate.getPeriodRange(arrived.startPeriod, arrived.periodCount);
        if (period != null) {
            Date end = parseTimeOnDate(period.endTime, now);
            if (end != null && now.after(end)) {
                WidgetDataStore.clearArrivedCourse(context);
                return null;
            }
        }

        // 兜底：超过 30 分钟视为过期
        if (now.getTime() - arrivedTime >= ARRIVED_VALID_DURATION_MS) {
            WidgetDataStore.clearArrivedCourse(context);
            return null;
        }

        return arrived;
    }

    // ------------------------------------------------------------------
    // 跨天归一化（对标 iOS normalizedWidgetDataForCurrentDay）
    // ------------------------------------------------------------------

    /**
     * App 长时间未打开时，落盘数据里的 todayCourses 可能仍是若干天前的。
     * 这里按当前真实日期重新推算今日 / 明日课程，避免小组件展示过期课表。
     */
    static WidgetScheduleData normalizeForCurrentDay(WidgetScheduleData data, Date now) {
        int currentWeekDay = isoWeekDay(now);

        Date dataDate = parseIsoDate(data.lastUpdateTime);
        int elapsedDays = 0;
        if (dataDate != null) {
            elapsedDays = Math.max(0, daysBetween(startOfDay(dataDate), startOfDay(now)));
        }

        // 星期未变且不足一周，说明数据仍然新鲜
        if (data.currentWeekDay == currentWeekDay && elapsedDays < 7) {
            return data;
        }

        int dayShift = elapsedDays > 0
                ? elapsedDays
                : ((currentWeekDay - data.currentWeekDay + 7) % 7);

        int effectiveWeek = data.currentWeek + ((data.currentWeekDay - 1 + dayShift) / 7);
        int tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
        int tomorrowWeek = currentWeekDay == 7 ? effectiveWeek + 1 : effectiveWeek;

        List<WidgetCourse> todayCourses =
                resolveCourses(data, currentWeekDay, effectiveWeek, dayShift);
        List<WidgetCourse> tomorrowCourses =
                resolveCourses(data, tomorrowWeekDay, tomorrowWeek, dayShift + 1);

        Log.i(TAG, "normalizeForCurrentDay: " + data.currentWeek + "-" + data.currentWeekDay
                + " -> " + effectiveWeek + "-" + currentWeekDay
                + " (shift=" + dayShift + ")");

        return data.copyWithDay(effectiveWeek, currentWeekDay, todayCourses, tomorrowCourses);
    }

    private static List<WidgetCourse> resolveCourses(WidgetScheduleData data,
                                                     int targetWeekDay,
                                                     int targetWeek,
                                                     int dayShiftFromSource) {
        List<WidgetCourse> candidates;
        if (dayShiftFromSource == 1) {
            // 只过了一天时，源数据的 tomorrowCourses 就是最准确的快照
            candidates = data.tomorrowCourses;
        } else {
            candidates = data.coursesForWeekDay(targetWeekDay);
        }

        List<WidgetCourse> result = new ArrayList<>();
        for (WidgetCourse course : candidates) {
            if (course.isActiveInWeek(targetWeek)) {
                result.add(course);
            }
        }
        sortByStartPeriod(result);
        return result;
    }

    public static void sortByStartPeriod(List<WidgetCourse> courses) {
        Collections.sort(courses, new Comparator<WidgetCourse>() {
            @Override
            public int compare(WidgetCourse a, WidgetCourse b) {
                return Integer.compare(a.startPeriod, b.startPeriod);
            }
        });
    }

    // ------------------------------------------------------------------
    // 时间工具
    // ------------------------------------------------------------------

    /**
     * 把 "HH:mm" 映射到指定日期的当天时刻。
     * 返回 null 表示格式非法。
     */
    public static Date parseTimeOnDate(String timeString, Date date) {
        if (timeString == null) {
            return null;
        }
        String[] parts = timeString.trim().split(":");
        if (parts.length < 2) {
            return null;
        }
        try {
            int hour = Integer.parseInt(parts[0].trim());
            int minute = Integer.parseInt(parts[1].trim());
            if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
                return null;
            }
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(date);
            calendar.set(Calendar.HOUR_OF_DAY, hour);
            calendar.set(Calendar.MINUTE, minute);
            calendar.set(Calendar.SECOND, 0);
            calendar.set(Calendar.MILLISECOND, 0);
            return calendar.getTime();
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** "08:00" -> "8:00"，与 iOS 端展示格式一致。 */
    public static String formatTime(String timeString) {
        if (timeString == null) {
            return null;
        }
        String[] parts = timeString.split(":");
        if (parts.length != 2) {
            return timeString;
        }
        try {
            int hour = Integer.parseInt(parts[0].trim());
            return hour + ":" + parts[1].trim();
        } catch (NumberFormatException e) {
            return timeString;
        }
    }

    /** 星期几，周一=1 ... 周日=7（ISO-8601）。 */
    public static int isoWeekDay(Date date) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        // Calendar.SUNDAY = 1 ... Calendar.SATURDAY = 7
        return ((calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1;
    }

    static Date startOfDay(Date date) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTime();
    }

    static boolean isSameDay(Date a, Date b) {
        return startOfDay(a).getTime() == startOfDay(b).getTime();
    }

    /**
     * 两个"日初"之间相差的天数。
     * 用毫秒差再按天取整会在夏令时切换日出错，这里逐日推进以保证准确。
     */
    static int daysBetween(Date from, Date to) {
        if (!to.after(from)) {
            return 0;
        }
        Calendar cursor = Calendar.getInstance();
        cursor.setTime(from);
        int days = 0;
        while (cursor.getTime().before(to) && days < 3660) {
            cursor.add(Calendar.DAY_OF_MONTH, 1);
            days++;
        }
        return days;
    }

    /** 解析 Dart {@code DateTime.toIso8601String()} 产出的时间串。 */
    static Date parseIsoDate(String value) {
        if (value == null || value.isEmpty()) {
            return null;
        }
        String[] patterns = {
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
        };
        String normalized = value.endsWith("Z")
                ? value.substring(0, value.length() - 1)
                : value;
        for (String pattern : patterns) {
            try {
                SimpleDateFormat format = new SimpleDateFormat(pattern, Locale.US);
                return format.parse(normalized);
            } catch (ParseException ignored) {
                // 尝试下一种格式
            }
        }
        Log.w(TAG, "parseIsoDate: unrecognized format: " + value);
        return null;
    }
}
