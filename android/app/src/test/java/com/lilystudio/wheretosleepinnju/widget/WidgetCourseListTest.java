package com.lilystudio.wheretosleepinnju.widget;

import static org.junit.Assert.*;
import org.junit.Test;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class WidgetCourseListTest {
    private List<WidgetCourse> courses(String prefix, int count) {
        List<WidgetCourse> result = new ArrayList<>();
        for (int i = 0; i < count; i++) result.add(new WidgetCourse(prefix + i,
                prefix + i, "教室", "老师", i + 1, 1, 1, "#0095F9", "nju",
                null, null, null));
        return result;
    }

    private WidgetStateResolver.WidgetState state(WidgetStateResolver.DisplayState display,
                                                 int current, int next) {
        List<WidgetCourse> today = courses("today", 12), tomorrow = courses("tomorrow", 9);
        WidgetScheduleData data = new WidgetScheduleData("2.0", null, "nju", "南京大学",
                null, 1, 1, "测试学期", today, tomorrow, null, 12, true, true,
                "sqlite", 21, null, null, null);
        return new WidgetStateResolver.WidgetState(data, display,
                current < 0 ? null : today.get(current), next < 0 ? null : today.get(next),
                null, new Date());
    }

    @Test public void retainsAllUpcomingCoursesBeyondPreviousLimits() {
        List<WidgetCourse> list = WidgetCourseList.forState(
                state(WidgetStateResolver.DisplayState.BEFORE_FIRST_CLASS, -1, 0));
        assertEquals(12, list.size());
        assertEquals("today11", list.get(11).id);
    }

    @Test public void includesCurrentAndAllFollowingCourses() {
        List<WidgetCourse> list = WidgetCourseList.forState(
                state(WidgetStateResolver.DisplayState.IN_CLASS, 3, 4));
        assertEquals(9, list.size());
        assertEquals("today3", list.get(0).id);
        assertEquals("today11", list.get(8).id);
    }

    @Test public void approachingAndBetweenSkipEndedCourses() {
        for (WidgetStateResolver.DisplayState display : new WidgetStateResolver.DisplayState[]{
                WidgetStateResolver.DisplayState.APPROACHING_CLASS,
                WidgetStateResolver.DisplayState.BETWEEN_CLASSES}) {
            List<WidgetCourse> list = WidgetCourseList.forState(state(display, -1, 4));
            assertEquals(8, list.size());
            assertEquals("today4", list.get(0).id);
        }
    }

    @Test public void tomorrowDoesNotUseTodaysAnchorOrTruncate() {
        List<WidgetCourse> list = WidgetCourseList.forState(
                state(WidgetStateResolver.DisplayState.TOMORROW_PREVIEW, -1, -1));
        assertEquals(9, list.size());
        assertEquals("tomorrow8", list.get(8).id);
    }

    @Test public void endedAndMissingDataNeverShowOldCourses() {
        for (WidgetStateResolver.DisplayState display : new WidgetStateResolver.DisplayState[]{
                WidgetStateResolver.DisplayState.CLASSES_ENDED,
                WidgetStateResolver.DisplayState.ERROR}) {
            assertTrue(WidgetCourseList.forState(state(display, 1, 2)).isEmpty());
        }
        assertTrue(WidgetCourseList.forState(new WidgetStateResolver.WidgetState(null,
                WidgetStateResolver.DisplayState.ERROR, null, null, "无数据", new Date())).isEmpty());
    }
}
