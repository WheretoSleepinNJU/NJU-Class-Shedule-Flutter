package com.lilystudio.wheretosleepinnju.widget;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.widget.RemoteViews;

import com.lilystudio.wheretosleepinnju.R;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * 小组件渲染器：把 {@link WidgetStateResolver.WidgetState} 画成 RemoteViews。
 *
 * 对标 iOS 端 SmallWidgetView / MediumWidgetView / LargeWidgetView 三套视图，
 * 状态与文案保持一致。RemoteViews 不支持自定义 View，因此课程卡片通过
 * {@code addView} 动态装配子布局实现。
 */
public class WidgetRenderer {

    /** 小组件尺寸档位，对应 iOS 的 WidgetFamily。 */
    public enum SizeClass {
        SMALL,
        MEDIUM,
        LARGE
    }

    /** 中尺寸右栏最多展示的课程数，与 iOS 端保持一致。 */
    private static final int MEDIUM_RIGHT_MAX_COURSES = 3;

    /** 大尺寸最多展示的后续课程数。 */
    private static final int LARGE_MAX_FOLLOWING_COURSES = 4;

    private WidgetRenderer() {
    }

    // ------------------------------------------------------------------
    // 入口
    // ------------------------------------------------------------------

    public static RemoteViews render(Context context,
                                     WidgetStateResolver.WidgetState state,
                                     SizeClass sizeClass) {
        switch (sizeClass) {
            case LARGE:
                return renderLarge(context, state);
            case MEDIUM:
                return renderMedium(context, state);
            case SMALL:
            default:
                return renderSmall(context, state);
        }
    }

    // ------------------------------------------------------------------
    // 小尺寸
    // ------------------------------------------------------------------

    private static RemoteViews renderSmall(Context context,
                                           WidgetStateResolver.WidgetState state) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_schedule_small);
        views.removeAllViews(R.id.widget_course_container);
        resetCommonVisibility(views);

        bindDateHeader(context, views, state);
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context));

        if (!state.hasData()) {
            showEmpty(context, views, state.errorMessage, context.getString(R.string.widget_tap_to_open));
            return views;
        }

        SchoolTimeTemplate template = state.timeTemplate();

        switch (state.displayState) {
            case IN_CLASS: {
                WidgetCourse current = state.currentCourse;
                if (current == null) {
                    showClassesEnded(context, views);
                    break;
                }
                Integer remaining = remainingCountIncludingCurrent(state);
                setStatus(views,
                        context.getString(R.string.widget_state_in_class),
                        context.getColor(R.color.widget_success),
                        remaining == null ? null
                                : context.getString(R.string.widget_today_remaining_count, remaining));

                addDetailedCard(context, views, R.id.widget_course_container, current, template);
                if (state.nextCourse != null) {
                    addCompactCard(context, views, R.id.widget_course_container,
                            state.nextCourse, template, 8);
                }
                break;
            }

            case APPROACHING_CLASS: {
                WidgetCourse next = state.nextCourse;
                if (next == null) {
                    showClassesEnded(context, views);
                    break;
                }
                setStatus(views, context.getString(R.string.widget_state_next),
                        context.getColor(R.color.widget_warning), null);
                addDetailedCard(context, views, R.id.widget_course_container, next, template);
                showArrivedButton(context, views, next.id);
                break;
            }

            case BEFORE_FIRST_CLASS:
            case BETWEEN_CLASSES: {
                List<WidgetCourse> remaining = remainingCoursesFromNext(state);
                if (remaining.isEmpty()) {
                    showClassesEnded(context, views);
                    break;
                }
                boolean isBetween = state.displayState == WidgetStateResolver.DisplayState.BETWEEN_CLASSES;
                setStatus(views,
                        isBetween
                                ? context.getString(R.string.widget_state_next)
                                : context.getString(R.string.widget_today_course_count, remaining.size()),
                        context.getColor(R.color.widget_text_secondary), null);

                addDetailedCard(context, views, R.id.widget_course_container, remaining.get(0), template);
                if (remaining.size() > 1) {
                    addCompactCard(context, views, R.id.widget_course_container,
                            remaining.get(1), template, 8);
                }
                break;
            }

            case TOMORROW_PREVIEW: {
                List<WidgetCourse> tomorrow = state.tomorrowCourses();
                if (tomorrow.isEmpty()) {
                    showClassesEnded(context, views);
                    break;
                }
                setStatus(views,
                        context.getString(R.string.widget_tomorrow_course_count, tomorrow.size()),
                        context.getColor(R.color.widget_text_secondary), null);

                addDetailedCard(context, views, R.id.widget_course_container, tomorrow.get(0), template);
                if (tomorrow.size() > 1) {
                    addCompactCard(context, views, R.id.widget_course_container,
                            tomorrow.get(1), template, 8);
                }
                break;
            }

            case CLASSES_ENDED:
            case ERROR:
            default:
                showClassesEnded(context, views);
                break;
        }

        return views;
    }

    // ------------------------------------------------------------------
    // 中尺寸
    // ------------------------------------------------------------------

    private static RemoteViews renderMedium(Context context,
                                            WidgetStateResolver.WidgetState state) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_schedule_medium);
        views.removeAllViews(R.id.widget_course_container);
        views.removeAllViews(R.id.widget_right_container);
        resetCommonVisibility(views);

        bindDateHeader(context, views, state);
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context));

        if (!state.hasData()) {
            showEmpty(context, views, state.errorMessage, context.getString(R.string.widget_tap_to_open));
            showRightEmpty(context, views, context.getString(R.string.widget_rest_well));
            return views;
        }

        SchoolTimeTemplate template = state.timeTemplate();

        // ---- 左栏 ----
        WidgetCourse leftCourse = null;
        switch (state.displayState) {
            case IN_CLASS: {
                leftCourse = state.currentCourse;
                Integer remaining = remainingCountIncludingCurrent(state);
                setStatus(views, context.getString(R.string.widget_state_in_class),
                        context.getColor(R.color.widget_success),
                        remaining == null ? null
                                : context.getString(R.string.widget_remaining_count, remaining));
                break;
            }
            case APPROACHING_CLASS: {
                leftCourse = state.nextCourse;
                setStatus(views, context.getString(R.string.widget_state_next),
                        context.getColor(R.color.widget_warning), null);
                break;
            }
            case BEFORE_FIRST_CLASS:
            case BETWEEN_CLASSES: {
                List<WidgetCourse> remaining = remainingCoursesFromNext(state);
                if (!remaining.isEmpty()) {
                    leftCourse = remaining.get(0);
                    boolean isBetween =
                            state.displayState == WidgetStateResolver.DisplayState.BETWEEN_CLASSES;
                    setStatus(views,
                            isBetween
                                    ? context.getString(R.string.widget_state_next)
                                    : context.getString(R.string.widget_today_course_count, remaining.size()),
                            context.getColor(R.color.widget_text_secondary), null);
                }
                break;
            }
            case TOMORROW_PREVIEW: {
                List<WidgetCourse> tomorrow = state.tomorrowCourses();
                if (!tomorrow.isEmpty()) {
                    leftCourse = tomorrow.get(0);
                    setStatus(views,
                            context.getString(R.string.widget_tomorrow_course_count, tomorrow.size()),
                            context.getColor(R.color.widget_text_secondary), null);
                }
                break;
            }
            default:
                break;
        }

        if (leftCourse == null) {
            showClassesEnded(context, views);
        } else {
            addDetailedCard(context, views, R.id.widget_course_container, leftCourse, template);
        }

        // ---- 右栏 ----
        renderMediumRight(context, views, state, template);
        return views;
    }

    private static void renderMediumRight(Context context,
                                          RemoteViews views,
                                          WidgetStateResolver.WidgetState state,
                                          SchoolTimeTemplate template) {
        switch (state.displayState) {
            case APPROACHING_CLASS: {
                if (state.nextCourse != null) {
                    // 右栏整体让位给"我已到达"按钮
                    views.setViewVisibility(R.id.widget_right_title, android.view.View.GONE);
                    views.setViewVisibility(R.id.widget_right_container, android.view.View.GONE);
                    views.setViewVisibility(R.id.widget_right_more, android.view.View.GONE);
                    views.setViewVisibility(R.id.widget_right_empty, android.view.View.GONE);
                    showArrivedButton(context, views, state.nextCourse.id);
                } else {
                    showRightEmpty(context, views, context.getString(R.string.widget_rest_well));
                }
                return;
            }

            case TOMORROW_PREVIEW: {
                List<WidgetCourse> tomorrow = state.tomorrowCourses();
                List<WidgetCourse> rest = dropFirst(tomorrow);
                if (rest.isEmpty()) {
                    showRightEmpty(context, views, context.getString(R.string.widget_rest_well));
                } else {
                    fillRightList(context, views, rest, template);
                }
                return;
            }

            case CLASSES_ENDED:
            case ERROR: {
                showRightEmpty(context, views, context.getString(R.string.widget_rest_well));
                return;
            }

            default: {
                // 从"当前课或下一节课"起算，右栏展示其后的剩余课程
                List<WidgetCourse> todayCourses = state.todayCourses();
                WidgetCourse anchor = state.currentCourse != null
                        ? state.currentCourse : state.nextCourse;
                if (anchor == null) {
                    showRightEmpty(context, views, context.getString(R.string.widget_thats_all));
                    return;
                }

                int index = WidgetStateResolver.indexOfCourse(todayCourses, anchor);
                if (index < 0 || index + 1 >= todayCourses.size()) {
                    showRightEmpty(context, views, context.getString(R.string.widget_thats_all));
                    return;
                }

                List<WidgetCourse> rest =
                        new ArrayList<>(todayCourses.subList(index + 1, todayCourses.size()));
                fillRightList(context, views, rest, template);
            }
        }
    }

    private static void fillRightList(Context context,
                                      RemoteViews views,
                                      List<WidgetCourse> courses,
                                      SchoolTimeTemplate template) {
        views.setViewVisibility(R.id.widget_right_title, android.view.View.VISIBLE);
        views.setViewVisibility(R.id.widget_right_container, android.view.View.VISIBLE);
        views.setViewVisibility(R.id.widget_right_empty, android.view.View.GONE);

        int shown = Math.min(courses.size(), MEDIUM_RIGHT_MAX_COURSES);
        for (int i = 0; i < shown; i++) {
            addCompactCard(context, views, R.id.widget_right_container,
                    courses.get(i), template, i == 0 ? 0 : 4);
        }

        if (courses.size() > shown) {
            views.setViewVisibility(R.id.widget_right_more, android.view.View.VISIBLE);
            views.setTextViewText(R.id.widget_right_more,
                    context.getString(R.string.widget_more_courses, courses.size() - shown));
        } else {
            views.setViewVisibility(R.id.widget_right_more, android.view.View.GONE);
        }
    }

    private static void showRightEmpty(Context context, RemoteViews views, String text) {
        views.setViewVisibility(R.id.widget_right_title, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_container, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_more, android.view.View.GONE);
        views.setViewVisibility(R.id.widget_right_empty, android.view.View.VISIBLE);
        views.setTextViewText(R.id.widget_right_empty_text, text);
    }

    // ------------------------------------------------------------------
    // 大尺寸
    // ------------------------------------------------------------------

    private static RemoteViews renderLarge(Context context,
                                           WidgetStateResolver.WidgetState state) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_schedule_large);
        views.removeAllViews(R.id.widget_course_container);
        resetCommonVisibility(views);

        bindDateHeader(context, views, state);
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context));

        if (!state.hasData()) {
            showEmpty(context, views, state.errorMessage, context.getString(R.string.widget_tap_to_open));
            return views;
        }

        SchoolTimeTemplate template = state.timeTemplate();

        switch (state.displayState) {
            case IN_CLASS: {
                WidgetCourse current = state.currentCourse;
                if (current == null) {
                    showClassesEnded(context, views);
                    break;
                }
                Integer remaining = remainingCountIncludingCurrent(state);
                setStatus(views, context.getString(R.string.widget_state_in_class),
                        context.getColor(R.color.widget_success),
                        remaining == null ? null
                                : context.getString(R.string.widget_today_remaining_count, remaining));

                addLargeCard(context, views, current, template);
                appendFollowingCourses(context, views, state.todayCourses(), current, template,
                        Integer.MAX_VALUE);
                break;
            }

            case APPROACHING_CLASS: {
                WidgetCourse next = state.nextCourse;
                if (next == null) {
                    showClassesEnded(context, views);
                    break;
                }
                setStatus(views, context.getString(R.string.widget_state_next),
                        context.getColor(R.color.widget_warning), null);
                addLargeCard(context, views, next, template);
                appendFollowingCourses(context, views, state.todayCourses(), next, template,
                        LARGE_MAX_FOLLOWING_COURSES);
                showArrivedButton(context, views, next.id);
                break;
            }

            case BEFORE_FIRST_CLASS:
            case BETWEEN_CLASSES: {
                List<WidgetCourse> remaining = remainingCoursesFromNext(state);
                if (remaining.isEmpty()) {
                    showClassesEnded(context, views);
                    break;
                }
                boolean isBetween =
                        state.displayState == WidgetStateResolver.DisplayState.BETWEEN_CLASSES;
                setStatus(views,
                        isBetween
                                ? context.getString(R.string.widget_state_next)
                                : context.getString(R.string.widget_today_course_count, remaining.size()),
                        context.getColor(R.color.widget_text_secondary), null);

                addLargeCard(context, views, remaining.get(0), template);
                for (int i = 1; i < remaining.size(); i++) {
                    addCompactCard(context, views, R.id.widget_course_container,
                            remaining.get(i), template, i == 1 ? 6 : 4);
                }
                break;
            }

            case TOMORROW_PREVIEW: {
                List<WidgetCourse> tomorrow = state.tomorrowCourses();
                if (tomorrow.isEmpty()) {
                    showClassesEnded(context, views);
                    break;
                }
                setStatus(views,
                        context.getString(R.string.widget_tomorrow_course_count, tomorrow.size()),
                        context.getColor(R.color.widget_text_secondary), null);

                addLargeCard(context, views, tomorrow.get(0), template);
                for (int i = 1; i < tomorrow.size(); i++) {
                    addCompactCard(context, views, R.id.widget_course_container,
                            tomorrow.get(i), template, i == 1 ? 6 : 4);
                }
                break;
            }

            case CLASSES_ENDED:
            case ERROR:
            default:
                showClassesEnded(context, views);
                break;
        }

        return views;
    }

    /** 在强调卡片之后追加后续课程的紧凑卡片。 */
    private static void appendFollowingCourses(Context context,
                                               RemoteViews views,
                                               List<WidgetCourse> allCourses,
                                               WidgetCourse anchor,
                                               SchoolTimeTemplate template,
                                               int limit) {
        int index = WidgetStateResolver.indexOfCourse(allCourses, anchor);
        if (index < 0 || index + 1 >= allCourses.size()) {
            return;
        }
        List<WidgetCourse> following =
                new ArrayList<>(allCourses.subList(index + 1, allCourses.size()));
        int shown = Math.min(following.size(), limit);
        for (int i = 0; i < shown; i++) {
            addCompactCard(context, views, R.id.widget_course_container,
                    following.get(i), template, i == 0 ? 6 : 4);
        }
        if (following.size() > shown) {
            views.setViewVisibility(R.id.widget_right_more, android.view.View.VISIBLE);
            views.setTextViewText(R.id.widget_right_more,
                    context.getString(R.string.widget_more_courses, following.size() - shown));
        }
    }

    // ------------------------------------------------------------------
    // 卡片装配
    // ------------------------------------------------------------------

    private static void addDetailedCard(Context context,
                                        RemoteViews parent,
                                        int containerId,
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

        parent.addView(containerId, card);
    }

    private static void addCompactCard(Context context,
                                       RemoteViews parent,
                                       int containerId,
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

        parent.addView(containerId, card);
    }

    private static void addLargeCard(Context context,
                                     RemoteViews parent,
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

        parent.addView(R.id.widget_course_container, card);
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

    // ------------------------------------------------------------------
    // 文案构造
    // ------------------------------------------------------------------

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

    // ------------------------------------------------------------------
    // 课程集合工具
    // ------------------------------------------------------------------

    /** 从下一节课开始的今日剩余课程。 */
    private static List<WidgetCourse> remainingCoursesFromNext(
            WidgetStateResolver.WidgetState state) {
        List<WidgetCourse> result = new ArrayList<>();
        WidgetCourse next = state.nextCourse;
        if (next == null) {
            return result;
        }

        List<WidgetCourse> todayCourses = state.todayCourses();
        int index = WidgetStateResolver.indexOfCourse(todayCourses, next);
        if (index < 0) {
            result.add(next);
            return result;
        }
        result.addAll(todayCourses.subList(index, todayCourses.size()));
        return result;
    }

    /** 含当前课在内的今日剩余课程数。 */
    private static Integer remainingCountIncludingCurrent(
            WidgetStateResolver.WidgetState state) {
        if (state.currentCourse == null) {
            return null;
        }
        List<WidgetCourse> todayCourses = state.todayCourses();
        int index = WidgetStateResolver.indexOfCourse(todayCourses, state.currentCourse);
        if (index < 0) {
            return null;
        }
        return todayCourses.size() - index;
    }

    private static List<WidgetCourse> dropFirst(List<WidgetCourse> courses) {
        if (courses == null || courses.size() <= 1) {
            return new ArrayList<>();
        }
        return new ArrayList<>(courses.subList(1, courses.size()));
    }

    // ------------------------------------------------------------------
    // 点击意图
    // ------------------------------------------------------------------

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
