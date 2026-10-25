package com.lilystudio.wheretosleepinnju.widget;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Complete collection for the displayed day; the launcher handles scrolling. */
final class WidgetCourseList {
    private WidgetCourseList() {}

    static List<WidgetCourse> forState(WidgetStateResolver.WidgetState state) {
        if (!state.hasData()) return Collections.emptyList();
        if (state.displayState == WidgetStateResolver.DisplayState.TOMORROW_PREVIEW) {
            return new ArrayList<>(state.tomorrowCourses());
        }
        if (state.displayState == WidgetStateResolver.DisplayState.CLASSES_ENDED
                || state.displayState == WidgetStateResolver.DisplayState.ERROR) {
            return Collections.emptyList();
        }
        WidgetCourse anchor = state.displayState == WidgetStateResolver.DisplayState.IN_CLASS
                ? state.currentCourse : state.nextCourse;
        if (anchor == null) return Collections.emptyList();
        int index = WidgetStateResolver.indexOfCourse(state.todayCourses(), anchor);
        if (index < 0) return Collections.singletonList(anchor);
        return new ArrayList<>(state.todayCourses().subList(index, state.todayCourses().size()));
    }
}
