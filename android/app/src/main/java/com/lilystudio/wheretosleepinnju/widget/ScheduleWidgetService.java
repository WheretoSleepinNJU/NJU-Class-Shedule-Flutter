package com.lilystudio.wheretosleepinnju.widget;

import android.content.Intent;
import android.widget.RemoteViews;
import android.widget.RemoteViewsService;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Collection adapter, available on all supported Android versions. */
public class ScheduleWidgetService extends RemoteViewsService {
    static final String EXTRA_SIZE = "widget_size";

    @Override
    public RemoteViewsFactory onGetViewFactory(Intent intent) {
        WidgetRenderer.SizeClass size;
        try {
            size = WidgetRenderer.SizeClass.valueOf(intent.getStringExtra(EXTRA_SIZE));
        } catch (Exception ignored) {
            size = WidgetRenderer.SizeClass.SMALL;
        }
        return new CourseFactory(size);
    }

    private class CourseFactory implements RemoteViewsFactory {
        private final WidgetRenderer.SizeClass size;
        private WidgetStateResolver.WidgetState state;
        private List<WidgetCourse> courses = Collections.emptyList();

        CourseFactory(WidgetRenderer.SizeClass size) { this.size = size; }
        @Override public void onCreate() { onDataSetChanged(); }
        @Override public synchronized void onDataSetChanged() {
            state = WidgetStateResolver.resolve(getApplicationContext());
            List<WidgetCourse> all = WidgetCourseList.forState(state);
            courses = size == WidgetRenderer.SizeClass.MEDIUM && !all.isEmpty()
                    ? new ArrayList<>(all.subList(1, all.size())) : all;
        }
        @Override public synchronized void onDestroy() { courses = Collections.emptyList(); }
        @Override public synchronized int getCount() { return courses.size(); }
        @Override public synchronized RemoteViews getViewAt(int position) {
            if (position < 0 || position >= courses.size()) return null;
            return WidgetRenderer.courseRow(getApplicationContext(), courses.get(position),
                    state.timeTemplate(), size, position);
        }
        @Override public RemoteViews getLoadingView() { return null; }
        @Override public int getViewTypeCount() { return 3; }
        @Override public long getItemId(int position) { return position; }
        @Override public boolean hasStableIds() { return false; }
    }
}
