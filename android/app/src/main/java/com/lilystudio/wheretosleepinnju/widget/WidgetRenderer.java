package com.lilystudio.wheretosleepinnju.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.widget.RemoteViews;
import com.lilystudio.wheretosleepinnju.MainActivity;
import com.lilystudio.wheretosleepinnju.R;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/** Header and current-course summary, backed by a scrolling remote collection. */
public class WidgetRenderer {
    public enum SizeClass { SMALL, MEDIUM, LARGE }

    public static RemoteViews render(Context context, WidgetStateResolver.WidgetState state,
                                     SizeClass size, int widgetId) {
        int layout = size == SizeClass.SMALL ? R.layout.widget_schedule_small
                : size == SizeClass.MEDIUM ? R.layout.widget_schedule_medium
                : R.layout.widget_schedule_large;
        RemoteViews views = new RemoteViews(context.getPackageName(), layout);
        resetCommonVisibility(views);
        bindDateHeader(context, views, state);
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context));
        if (size == SizeClass.MEDIUM) views.removeAllViews(R.id.widget_course_container);

        List<WidgetCourse> courses = WidgetCourseList.forState(state);
        if (!state.hasData() || courses.isEmpty()) {
            showEmpty(context, views, state.hasData()
                    ? context.getString(R.string.widget_classes_ended) : state.errorMessage,
                    state.hasData() ? null : context.getString(R.string.widget_tap_to_open));
            if (size == SizeClass.MEDIUM) showRightEmpty(context, views);
            return views;
        }

        switch (state.displayState) {
            case IN_CLASS:
                setStatus(views, context.getString(R.string.widget_state_in_class),
                        context.getColor(R.color.widget_success),
                        context.getString(R.string.widget_remaining_count, courses.size()));
                break;
            case APPROACHING_CLASS:
                setStatus(views, context.getString(R.string.widget_state_next),
                        context.getColor(R.color.widget_warning), null);
                showArrivedButton(context, views, courses.get(0).id);
                break;
            case TOMORROW_PREVIEW:
                setStatus(views, context.getString(R.string.widget_tomorrow_course_count, courses.size()),
                        context.getColor(R.color.widget_text_secondary), null);
                break;
            case BETWEEN_CLASSES:
                setStatus(views, context.getString(R.string.widget_state_next),
                        context.getColor(R.color.widget_text_secondary), null);
                break;
            default:
                setStatus(views, context.getString(R.string.widget_today_course_count, courses.size()),
                        context.getColor(R.color.widget_text_secondary), null);
        }

        int listId = size == SizeClass.MEDIUM ? R.id.widget_right_container
                : R.id.widget_course_container;
        if (size == SizeClass.MEDIUM) {
            views.addView(R.id.widget_course_container,
                    detailedCard(context, courses.get(0), state.timeTemplate()));
            views.setViewVisibility(R.id.widget_right_more, android.view.View.GONE);
            views.setViewVisibility(R.id.widget_right_empty, android.view.View.GONE);
            views.setViewVisibility(R.id.widget_right_container, android.view.View.VISIBLE);
            views.setViewVisibility(R.id.widget_right_title, android.view.View.VISIBLE);
            if (courses.size() == 1) showRightEmpty(context, views);
        }
        bindCollection(context, views, listId, size, widgetId);
        return views;
    }

    private static void showRightEmpty(Context context, RemoteViews views) {
        views.setViewVisibility(R.id.widget_right_title, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_container, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_more, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_empty, android.view.View.VISIBLE);
        views.setTextViewText(R.id.widget_right_empty_text,
                context.getString(R.string.widget_thats_all));
    }

    private static void bindCollection(Context context, RemoteViews views, int listId,
                                       SizeClass size, int widgetId) {
        Intent service = new Intent(context, ScheduleWidgetService.class);
        service.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId);
        service.putExtra(ScheduleWidgetService.EXTRA_SIZE, size.name());
        // Intent extras do not participate in adapter identity. Keep each widget and
        // responsive layout isolated so resizing cannot reuse another list's factory.
        service.setData(Uri.parse("ncs-widget://courses/" + widgetId + "/" + size.name()));
        views.setRemoteAdapter(listId, service);
        Intent launch = new Intent(context, MainActivity.class);
        launch.setAction(Intent.ACTION_VIEW);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) flags |= PendingIntent.FLAG_MUTABLE;
        views.setPendingIntentTemplate(listId,
                PendingIntent.getActivity(context, widgetId, launch, flags));
    }

    static RemoteViews courseRow(Context context, WidgetCourse course,
                                  SchoolTimeTemplate template, SizeClass size, int position) {
        RemoteViews row;
        int root;
        if (position == 0 && size == SizeClass.SMALL) {
            row = detailedCard(context, course, template);
            root = R.id.course_card_root;
        } else if (position == 0 && size == SizeClass.LARGE) {
            row = largeCard(context, course, template);
            root = R.id.course_large_root;
        } else {
            row = compactCard(context, course, template, 0);
            root = R.id.course_compact_root;
        }
        row.setOnClickFillInIntent(root,
                new Intent(Intent.ACTION_VIEW, Uri.parse("ncs://course/" + course.id)));
        return row;
    }

    private static RemoteViews detailedCard(Context context,
                                        WidgetCourse course,
                                        SchoolTimeTemplate template) {
        RemoteViews card = new RemoteViews(context.getPackageName(),
                R.layout.widget_item_course_detailed);

        int color = WidgetColorUtils.courseColor(course);
        card.setInt(R.id.course_card_root, "setBackgroundColor",
                WidgetColorUtils.cardBackgroundColor(color));
        card.setInt(R.id.course_card_stripe, "setBackgroundColor", color);

        card.setTextViewText(R.id.course_card_name, course.name);

        String location = buildLocationText(course);
        if (location == null) {
            card.setViewVisibility(R.id.course_card_location, android.view.View.GONE);
        } else {
            card.setViewVisibility(R.id.course_card_location, android.view.View.VISIBLE);
            card.setTextViewText(R.id.course_card_location, location);
            card.setTextViewTextSize(R.id.course_card_location,
                    android.util.TypedValue.COMPLEX_UNIT_SP,
                    classroomFontSize(course.classroom, 11f));
        }

        String timeRange = buildTimeRangeText(context, course, template, true);
        if (timeRange == null) {
            card.setViewVisibility(R.id.course_card_time, android.view.View.GONE);
        } else {
            card.setViewVisibility(R.id.course_card_time, android.view.View.VISIBLE);
            card.setTextViewText(R.id.course_card_time, timeRange);
        }

        return card;
    }

    private static RemoteViews compactCard(Context context,
                                       WidgetCourse course,
                                       SchoolTimeTemplate template,
                                       int topMarginDp) {
        RemoteViews card = new RemoteViews(context.getPackageName(),
                R.layout.widget_item_course_compact);

        int color = WidgetColorUtils.courseColor(course);
        card.setInt(R.id.course_compact_root, "setBackgroundColor",
                WidgetColorUtils.compactBackgroundColor(color));
        card.setInt(R.id.course_compact_stripe, "setBackgroundColor", color);

        card.setTextViewText(R.id.course_compact_name, course.name);
        card.setTextViewText(R.id.course_compact_detail, buildCompactDetailText(context, course, template));

        if (topMarginDp > 0) {
            // RemoteViews 无法直接改 margin，用顶部内边距模拟卡片间距
            applyTopSpacing(card, R.id.course_compact_root, context, topMarginDp);
        }

        return card;
    }

    private static RemoteViews largeCard(Context context,
                                     WidgetCourse course,
                                     SchoolTimeTemplate template) {
        RemoteViews card = new RemoteViews(context.getPackageName(),
                R.layout.widget_item_course_large);

        int color = WidgetColorUtils.courseColor(course);
        card.setInt(R.id.course_large_root, "setBackgroundColor",
                WidgetColorUtils.cardBackgroundColor(color));
        card.setInt(R.id.course_large_stripe, "setBackgroundColor", color);

        card.setTextViewText(R.id.course_large_name, course.name);

        String location = buildLocationText(course);
        if (location == null) {
            card.setViewVisibility(R.id.course_large_location, android.view.View.INVISIBLE);
        } else {
            card.setViewVisibility(R.id.course_large_location, android.view.View.VISIBLE);
            card.setTextViewText(R.id.course_large_location, location);
            card.setTextViewTextSize(R.id.course_large_location,
                    android.util.TypedValue.COMPLEX_UNIT_SP,
                    classroomFontSize(course.classroom, 13f));
        }

        SchoolTimeTemplate.ClassPeriod period = template == null
                ? null : template.getPeriodRange(course.startPeriod, course.periodCount);
        if (period == null) {
            card.setTextViewText(R.id.course_large_start_time,
                    context.getString(R.string.widget_period_index, course.startPeriod));
            card.setViewVisibility(R.id.course_large_end_time, android.view.View.GONE);
        } else {
            card.setTextViewText(R.id.course_large_start_time,
                    WidgetStateResolver.formatTime(period.startTime));
            card.setViewVisibility(R.id.course_large_end_time, android.view.View.VISIBLE);
            card.setTextViewText(R.id.course_large_end_time,
                    WidgetStateResolver.formatTime(period.endTime));
        }

        return card;
    }

    private static void applyTopSpacing(RemoteViews card, int viewId, Context context, int dp) {
        int px = (int) (dp * context.getResources().getDisplayMetrics().density);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            card.setViewLayoutMargin(viewId, RemoteViews.MARGIN_TOP,
                    dp, android.util.TypedValue.COMPLEX_UNIT_DIP);
        } else {
            // 低版本退化为外层容器的 padding，视觉上等价
            card.setViewPadding(viewId, 0, px, 0, 0);
        }
    }

    /** "教室 · 教师"，两者皆空时返回 null。 */
    private static String buildLocationText(WidgetCourse course) {
        boolean hasClassroom = course.hasClassroom();
        boolean hasTeacher = course.hasTeacher();
        if (hasClassroom && hasTeacher) {
            return course.classroom + " · " + course.teacher;
        }
        if (hasClassroom) {
            return course.classroom;
        }
        if (hasTeacher) {
            return course.teacher;
        }
        return null;
    }

    /** 紧凑卡片的 "时间 · 教室 · 教师"。 */
    private static String buildCompactDetailText(Context context,
                                                 WidgetCourse course,
                                                 SchoolTimeTemplate template) {
        List<String> parts = new ArrayList<>();
        String time = buildTimeRangeText(context, course, template, false);
        if (time != null) {
            parts.add(time);
        }
        if (course.hasClassroom()) {
            parts.add(course.classroom);
        }
        if (course.hasTeacher()) {
            parts.add(course.teacher);
        }
        return join(parts, " · ");
    }

    /**
     * 时间文案。detailed 为 true 时返回 "8:00 - 9:50"，否则只返回开始时间。
     * 没有时间模板时退化为 "第 N 节"，与 iOS 端一致。
     */
    private static String buildTimeRangeText(Context context,
                                             WidgetCourse course,
                                             SchoolTimeTemplate template,
                                             boolean detailed) {
        SchoolTimeTemplate.ClassPeriod period = template == null
                ? null : template.getPeriodRange(course.startPeriod, course.periodCount);

        if (period == null) {
            if (detailed && course.periodCount > 1) {
                return context.getString(R.string.widget_period_range,
                        course.startPeriod, course.startPeriod + course.periodCount - 1);
            }
            return context.getString(R.string.widget_period_index, course.startPeriod);
        }

        String start = WidgetStateResolver.formatTime(period.startTime);
        if (!detailed) {
            return start;
        }
        return start + " - " + WidgetStateResolver.formatTime(period.endTime);
    }

    /** 教室名过长时缩小字号，对标 iOS 的 calculateClassroomFontSize。 */
    private static float classroomFontSize(String classroom, float baseSize) {
        if (classroom == null) {
            return baseSize;
        }
        if (classroom.length() > 15) {
            return baseSize - 2f;
        }
        if (classroom.length() > 10) {
            return baseSize - 1f;
        }
        return baseSize;
    }

    private static String join(List<String> parts, String separator) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < parts.size(); i++) {
            if (i > 0) {
                builder.append(separator);
            }
            builder.append(parts.get(i));
        }
        return builder.toString();
    }

    // ------------------------------------------------------------------
    // 通用区块
    // ------------------------------------------------------------------

    private static void bindDateHeader(Context context,
                                       RemoteViews views,
                                       WidgetStateResolver.WidgetState state) {
        Date date = state.referenceDate == null ? new Date() : state.referenceDate;

        views.setTextViewText(R.id.widget_date,
                new SimpleDateFormat("M.d", Locale.getDefault()).format(date));
        views.setTextViewText(R.id.widget_weekday, weekdayText(date));

        if (state.hasData()) {
            views.setViewVisibility(R.id.widget_week_index, android.view.View.VISIBLE);
            views.setTextViewText(R.id.widget_week_index,
                    context.getString(R.string.widget_week_index, state.data.currentWeek));
        } else {
            views.setViewVisibility(R.id.widget_week_index, android.view.View.GONE);
        }
    }

    private static String weekdayText(Date date) {
        String[] names = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};
        int weekDay = WidgetStateResolver.isoWeekDay(date);
        if (weekDay >= 1 && weekDay <= 7) {
            return names[weekDay - 1];
        }
        return "";
    }

    private static void setStatus(RemoteViews views, String label, int color, String trailing) {
        views.setViewVisibility(R.id.widget_status_row, android.view.View.VISIBLE);
        views.setTextViewText(R.id.widget_status_label, label);
        views.setTextColor(R.id.widget_status_label, color);

        if (trailing == null) {
            views.setViewVisibility(R.id.widget_status_trailing, android.view.View.GONE);
        } else {
            views.setViewVisibility(R.id.widget_status_trailing, android.view.View.VISIBLE);
            views.setTextViewText(R.id.widget_status_trailing, trailing);
        }
    }

    /**
     * 复位各区块的可见性。
     *
     * Launcher 对同一个 layoutId 会走 RemoteViews.reapply 复用既有 View 树，
     * 上一次渲染设置的 GONE 不会自动还原。若不显式复位，先展示过空状态的小组件
     * 在重新有课后会一直空着。
     */
    private static void resetCommonVisibility(RemoteViews views) {
        views.setViewVisibility(R.id.widget_status_row, android.view.View.VISIBLE);
        views.setViewVisibility(R.id.widget_course_container, android.view.View.VISIBLE);
        views.setViewVisibility(R.id.widget_empty_container, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_empty_subtitle, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_status_trailing, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_arrived_button, android.view.View.GONE);
    }

    private static void showClassesEnded(Context context, RemoteViews views) {
        showEmpty(context, views, context.getString(R.string.widget_classes_ended), null);
    }

    private static void showEmpty(Context context,
                                  RemoteViews views,
                                  String title,
                                  String subtitle) {
        views.setViewVisibility(R.id.widget_status_row, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_course_container, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_arrived_button, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_empty_container, android.view.View.VISIBLE);
        views.setTextViewText(R.id.widget_empty_title,
                title == null ? context.getString(R.string.widget_classes_ended) : title);

        if (subtitle == null) {
            views.setViewVisibility(R.id.widget_empty_subtitle, android.view.View.GONE);
        } else {
            views.setViewVisibility(R.id.widget_empty_subtitle, android.view.View.VISIBLE);
            views.setTextViewText(R.id.widget_empty_subtitle, subtitle);
        }
    }

    private static void showArrivedButton(Context context, RemoteViews views, String courseId) {
        views.setViewVisibility(R.id.widget_arrived_button, android.view.View.VISIBLE);
        views.setOnClickPendingIntent(R.id.widget_arrived_button, arrivedIntent(context, courseId));
    }

    /** 点击卡片打开 App，对标 iOS 的 widgetURL(ncs://course/...)。 */
    private static PendingIntent openAppIntent(Context context) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("ncs://course"));
        intent.setPackage(context.getPackageName());
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        return PendingIntent.getActivity(context, 0, intent, pendingIntentFlags());
    }

    /** "我已到达"，对标 iOS 的 Link(ncs://arrived/{courseId})。 */
    private static PendingIntent arrivedIntent(Context context, String courseId) {
        Intent intent = new Intent(context, ScheduleWidgetProvider.class);
        intent.setAction(ScheduleWidgetProvider.ACTION_COURSE_ARRIVED);
        intent.putExtra(ScheduleWidgetProvider.EXTRA_COURSE_ID, courseId);
        // data 唯一化，避免不同课程复用同一个 PendingIntent
        intent.setData(Uri.parse("ncs://arrived/" + courseId));
        return PendingIntent.getBroadcast(context, 0, intent, pendingIntentFlags());
    }

    private static int pendingIntentFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.FLAG_UPDATE_CURRENT;
    }
}
