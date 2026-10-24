package com.lilystudio.wheretosleepinnju.widget;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;

import java.util.Calendar;
import java.util.Date;
import java.util.List;

/**
 * 小组件核心逻辑单测：数据解析、课程定位、状态判定与跨天归一化。
 *
 * 断言依据是 iOS 端 ScheduleWidget.swift 的既有行为，确保两端表现一致。
 */
public class WidgetStateResolverTest {

    // ------------------------------------------------------------------
    // 构造测试数据
    // ------------------------------------------------------------------

    /** 南京大学常见作息，12 个节次。 */
    private static JSONArray buildPeriods() throws Exception {
        String[][] times = {
                {"08:00", "08:50"}, {"09:00", "09:50"},
                {"10:10", "11:00"}, {"11:10", "12:00"},
                {"14:00", "14:50"}, {"15:00", "15:50"},
                {"16:10", "17:00"}, {"17:10", "18:00"},
                {"18:30", "19:20"}, {"19:30", "20:20"},
                {"20:30", "21:20"}, {"21:30", "22:20"},
        };
        JSONArray periods = new JSONArray();
        for (String[] time : times) {
            JSONObject period = new JSONObject();
            period.put("startTime", time[0]);
            period.put("endTime", time[1]);
            periods.put(period);
        }
        return periods;
    }

    private static JSONObject buildCourse(String id, String name, int startPeriod,
                                          int periodCount, int weekDay) throws Exception {
        JSONObject course = new JSONObject();
        course.put("id", id);
        course.put("name", name);
        course.put("classroom", "仙I-101");
        course.put("teacher", "张三");
        course.put("startPeriod", startPeriod);
        course.put("periodCount", periodCount);
        course.put("weekDay", weekDay);
        course.put("color", "#FF5722");
        course.put("schoolId", "nju");
        course.put("weeks", new JSONArray(new int[]{1, 2, 3, 4, 5}));
        return course;
    }

    private static JSONObject buildData(JSONArray todayCourses,
                                        JSONArray tomorrowCourses,
                                        int currentWeek,
                                        int currentWeekDay,
                                        String lastUpdateTime) throws Exception {
        JSONObject template = new JSONObject();
        template.put("schoolId", "nju");
        template.put("schoolName", "南京大学");
        template.put("schoolNameEn", "Nanjing University");
        template.put("periods", buildPeriods());

        JSONObject data = new JSONObject();
        data.put("version", "2.0");
        data.put("timestamp", lastUpdateTime);
        data.put("schoolId", "nju");
        data.put("schoolName", "南京大学");
        data.put("timeTemplate", template);
        data.put("currentWeek", currentWeek);
        data.put("currentWeekDay", currentWeekDay);
        data.put("semesterName", "2026学年");
        data.put("todayCourses", todayCourses);
        data.put("tomorrowCourses", tomorrowCourses);
        data.put("weekSchedule", new JSONObject());
        data.put("weekCourseCount", todayCourses.length());
        data.put("hasCoursesToday", todayCourses.length() > 0);
        data.put("hasCoursesTomorrow", tomorrowCourses.length() > 0);
        data.put("dataSource", "sqlite");
        data.put("totalCourses", todayCourses.length());
        data.put("lastUpdateTime", lastUpdateTime);
        return data;
    }

    private static Date at(int hour, int minute) {
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.HOUR_OF_DAY, hour);
        calendar.set(Calendar.MINUTE, minute);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTime();
    }

    /** 构造今天有两门课（第1-2节、第5-6节）的数据。 */
    private static WidgetScheduleData todayWithTwoCourses() throws Exception {
        Date now = new Date();
        int weekDay = WidgetStateResolver.isoWeekDay(now);

        JSONArray today = new JSONArray();
        today.put(buildCourse("c1", "高等数学", 1, 2, weekDay));
        today.put(buildCourse("c2", "数据结构", 5, 2, weekDay));

        JSONArray tomorrow = new JSONArray();
        tomorrow.put(buildCourse("c3", "操作系统", 3, 2, weekDay == 7 ? 1 : weekDay + 1));

        WidgetScheduleData data = WidgetScheduleData.fromJson(
                buildData(today, tomorrow, 3, weekDay, isoNow()));
        assertNotNull("测试数据应能被解析", data);
        return data;
    }

    private static String isoNow() {
        return new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US)
                .format(new Date());
    }

    // ------------------------------------------------------------------
    // 解析
    // ------------------------------------------------------------------

    @Test
    public void parsesWidgetData() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        assertEquals("nju", data.schoolId);
        assertEquals(3, data.currentWeek);
        assertEquals(2, data.todayCourses.size());
        assertEquals(12, data.timeTemplate.periods.size());
        assertTrue(data.hasCoursesToday);
    }

    /**
     * Flutter 会把 classroom / teacher 序列化成 JSON null，
     * org.json 的 optString 会把它读成字符串 "null"，必须被拦住。
     */
    @Test
    public void jsonNullDoesNotBecomeLiteralNullString() throws Exception {
        JSONObject course = buildCourse("c1", "体育", 1, 2, 1);
        course.put("classroom", JSONObject.NULL);
        course.put("teacher", JSONObject.NULL);

        WidgetCourse parsed = WidgetCourse.fromJson(course);

        assertNull("classroom 为 JSON null 时应解析为 null", parsed.classroom);
        assertNull("teacher 为 JSON null 时应解析为 null", parsed.teacher);
        assertFalse(parsed.hasClassroom());
        assertFalse(parsed.hasTeacher());
    }

    @Test
    public void periodRangeSpansMultiplePeriods() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        // 第 1-2 节：08:00 开始，09:50 结束
        SchoolTimeTemplate.ClassPeriod range = data.timeTemplate.getPeriodRange(1, 2);
        assertNotNull(range);
        assertEquals("08:00", range.startTime);
        assertEquals("09:50", range.endTime);

        // 越界应返回 null 而不是抛异常
        assertNull(data.timeTemplate.getPeriodRange(12, 3));
        assertNull(data.timeTemplate.getPeriodRange(0, 1));
    }

    // ------------------------------------------------------------------
    // 课程定位
    // ------------------------------------------------------------------

    @Test
    public void findsCurrentCourseDuringClass() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        // 08:30 处于第 1-2 节课中间
        WidgetCourse current = WidgetStateResolver.findCurrentCourse(data, at(8, 30));
        assertNotNull(current);
        assertEquals("c1", current.id);
    }

    @Test
    public void noCurrentCourseDuringBreak() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        // 12:30 已下课、下一节 14:00 才开始
        assertNull(WidgetStateResolver.findCurrentCourse(data, at(12, 30)));
    }

    @Test
    public void findsEarliestUpcomingCourse() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        WidgetCourse next = WidgetStateResolver.findNextCourse(data, at(7, 0));
        assertNotNull(next);
        assertEquals("最早的下一节课应为第 1 节", "c1", next.id);

        WidgetCourse afternoon = WidgetStateResolver.findNextCourse(data, at(12, 30));
        assertNotNull(afternoon);
        assertEquals("c2", afternoon.id);

        // 全天课程结束后没有下一节
        assertNull(WidgetStateResolver.findNextCourse(data, at(20, 0)));
    }

    // ------------------------------------------------------------------
    // 状态判定
    // ------------------------------------------------------------------

    @Test
    public void stateIsInClassWhileCourseOngoing() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        Date now = at(8, 30);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.IN_CLASS, state);
    }

    @Test
    public void stateIsApproachingWithinConfiguredWindow() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        // 默认提前量 15 分钟，07:50 距第一节课 10 分钟
        Date now = at(7, 50);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.APPROACHING_CLASS, state);
    }

    @Test
    public void stateIsBeforeFirstClassWhenFarFromStart() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        Date now = at(6, 30);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.BEFORE_FIRST_CLASS, state);
    }

    @Test
    public void stateIsBetweenClassesAfterFirstCourse() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        Date now = at(12, 30);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.BETWEEN_CLASSES, state);
    }

    @Test
    public void stateIsClassesEndedAfterLastCourse() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        // 16:00 已过最后一节（第 5-6 节 15:50 结束），且早于明日预览时间 21:00
        Date now = at(16, 0);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.CLASSES_ENDED, state);
    }

    @Test
    public void stateIsTomorrowPreviewAfterConfiguredHour() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        // 默认 21:00 之后进入明日预览
        Date now = at(21, 30);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                WidgetStateResolver.findCurrentCourse(data, now),
                WidgetStateResolver.findNextCourse(data, now),
                false,
                now);

        assertEquals(WidgetStateResolver.DisplayState.TOMORROW_PREVIEW, state);
    }

    @Test
    public void arrivedCourseForcesInClassState() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        // 07:50 本应是"即将上课"，标记已到达后应切到"上课中"
        Date now = at(7, 50);

        WidgetStateResolver.DisplayState state = WidgetStateResolver.determineDisplayState(
                data,
                null,
                WidgetStateResolver.findNextCourse(data, now),
                true,
                now);

        assertEquals(WidgetStateResolver.DisplayState.IN_CLASS, state);
    }

    // ------------------------------------------------------------------
    // 跨天归一化
    // ------------------------------------------------------------------

    @Test
    public void freshDataIsNotRewritten() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        WidgetScheduleData normalized =
                WidgetStateResolver.normalizeForCurrentDay(data, new Date());

        assertEquals("当天数据不应被改写", data.currentWeekDay, normalized.currentWeekDay);
        assertEquals(data.todayCourses.size(), normalized.todayCourses.size());
    }

    /** App 隔了一天没打开：昨天的 tomorrowCourses 应当成为今天的课表。 */
    @Test
    public void staleOneDayDataPromotesTomorrowCourses() throws Exception {
        Date now = new Date();
        int todayWeekDay = WidgetStateResolver.isoWeekDay(now);
        int yesterdayWeekDay = todayWeekDay == 1 ? 7 : todayWeekDay - 1;

        JSONArray yesterdayCourses = new JSONArray();
        yesterdayCourses.put(buildCourse("old", "昨日课程", 1, 2, yesterdayWeekDay));

        JSONArray todayCourses = new JSONArray();
        todayCourses.put(buildCourse("new", "今日课程", 3, 2, todayWeekDay));

        Calendar yesterday = Calendar.getInstance();
        yesterday.add(Calendar.DAY_OF_MONTH, -1);
        String yesterdayIso = new java.text.SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US).format(yesterday.getTime());

        WidgetScheduleData stale = WidgetScheduleData.fromJson(
                buildData(yesterdayCourses, todayCourses, 3, yesterdayWeekDay, yesterdayIso));
        assertNotNull(stale);

        WidgetScheduleData normalized = WidgetStateResolver.normalizeForCurrentDay(stale, now);

        assertEquals("星期应更新为今天", todayWeekDay, normalized.currentWeekDay);
        assertEquals(1, normalized.todayCourses.size());
        assertEquals("昨天的 tomorrowCourses 应成为今天的课表",
                "new", normalized.todayCourses.get(0).id);
    }

    @Test
    public void coursesAreFilteredByWeek() throws Exception {
        JSONObject course = buildCourse("c1", "选修课", 1, 2, 1);
        course.put("weeks", new JSONArray(new int[]{1, 2, 3}));
        WidgetCourse parsed = WidgetCourse.fromJson(course);

        assertTrue(parsed.isActiveInWeek(2));
        assertFalse(parsed.isActiveInWeek(9));
    }

    @Test
    public void emptyWeeksMeansEveryWeek() throws Exception {
        JSONObject course = buildCourse("c1", "全周课", 1, 2, 1);
        course.put("weeks", new JSONArray());
        WidgetCourse parsed = WidgetCourse.fromJson(course);

        assertTrue("周次列表为空应视为每周都上", parsed.isActiveInWeek(15));
    }

    // ------------------------------------------------------------------
    // 时间工具
    // ------------------------------------------------------------------

    @Test
    public void formatTimeStripsLeadingZero() {
        assertEquals("8:00", WidgetStateResolver.formatTime("08:00"));
        assertEquals("14:30", WidgetStateResolver.formatTime("14:30"));
    }

    @Test
    public void parseTimeOnDateRejectsMalformedInput() {
        Date now = new Date();
        assertNull(WidgetStateResolver.parseTimeOnDate("not-a-time", now));
        assertNull(WidgetStateResolver.parseTimeOnDate("25:00", now));
        assertNull(WidgetStateResolver.parseTimeOnDate(null, now));
        assertNotNull(WidgetStateResolver.parseTimeOnDate("08:00", now));
    }

    @Test
    public void minutesUntilCourseIsAccurate() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        Integer minutes = WidgetStateResolver.minutesUntilCourse(
                data.todayCourses.get(0), data.timeTemplate, at(7, 45));

        assertNotNull(minutes);
        assertEquals(15, minutes.intValue());
    }

    @Test
    public void isoWeekDayIsMondayBased() {
        Calendar calendar = Calendar.getInstance();
        // 2026-09-14 是周一
        calendar.set(2026, Calendar.SEPTEMBER, 14, 12, 0, 0);
        assertEquals(1, WidgetStateResolver.isoWeekDay(calendar.getTime()));

        // 2026-09-20 是周日
        calendar.set(2026, Calendar.SEPTEMBER, 20, 12, 0, 0);
        assertEquals(7, WidgetStateResolver.isoWeekDay(calendar.getTime()));
    }

    @Test
    public void sortsCoursesByStartPeriod() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();
        List<WidgetCourse> courses = new java.util.ArrayList<>(data.todayCourses);
        java.util.Collections.reverse(courses);

        WidgetStateResolver.sortByStartPeriod(courses);

        assertEquals(1, courses.get(0).startPeriod);
        assertEquals(5, courses.get(1).startPeriod);
    }

    @Test
    public void missingTimeTemplateIsRejected() throws Exception {
        JSONObject data = buildData(new JSONArray(), new JSONArray(), 1, 1, isoNow());
        data.remove("timeTemplate");

        assertNull("缺少时间模板的数据应被判为无效", WidgetScheduleData.fromJson(data));
    }

    @Test
    public void configurationFallsBackToDefaults() throws Exception {
        WidgetScheduleData data = todayWithTwoCourses();

        // 未下发配置时使用与 iOS 一致的默认值
        assertEquals(15, data.resolveApproachingMinutes());
        assertEquals(21, data.resolveTomorrowPreviewHour());
    }
}
