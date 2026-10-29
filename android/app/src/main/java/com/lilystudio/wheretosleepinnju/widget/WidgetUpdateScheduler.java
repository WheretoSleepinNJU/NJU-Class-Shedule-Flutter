package com.lilystudio.wheretosleepinnju.widget;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * 小组件刷新调度。
 *
 * iOS 端在 {@code getTimeline} 里一次性生成未来若干个状态转换时间点，交由系统按时切换。
 * Android 没有 Timeline 机制，这里改为：每次刷新时算出"下一个会导致状态变化的时刻"
 * （课程开始 / 结束 / 即将上课 / 明日预览 / 次日零点），用 AlarmManager 精确唤醒一次，
 * 唤醒后重绘并再次排下一个闹钟，效果等价且不浪费电量。
 */
public class WidgetUpdateScheduler {

    private static final String TAG = "WidgetUpdateScheduler";

    /** 兜底刷新间隔：算不出转换点时（例如无课）最长 1 小时后再看一次。 */
    private static final long FALLBACK_INTERVAL_MS = 60 * 60 * 1000L;

    private WidgetUpdateScheduler() {
    }

    /** 计算并登记下一次刷新。 */
    public static void scheduleNext(Context context) {
        Date now = new Date();
        Date nextTime = calculateNextTransition(context, now);

        AlarmManager alarmManager =
                (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) {
            Log.w(TAG, "scheduleNext: AlarmManager unavailable");
            return;
        }

        PendingIntent pendingIntent = buildPendingIntent(context);
        long triggerAt = nextTime.getTime();

        try {
            // 优先精确唤醒，保证"上课中"这类状态准点切换；
            // Android 12+ 未授予精确闹钟权限时自动退回非精确唤醒，不影响功能，只是可能有几分钟延迟。
            if (canScheduleExactAlarms(alarmManager)) {
                alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC, triggerAt, pendingIntent);
            } else {
                alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC, triggerAt, pendingIntent);
            }
            Log.i(TAG, "scheduleNext: next refresh at " + nextTime);
        } catch (SecurityException e) {
            // 部分 ROM 会对精确闹钟额外收权，降级处理而不是崩溃
            Log.w(TAG, "scheduleNext: exact alarm denied, fallback to inexact", e);
            alarmManager.set(AlarmManager.RTC, triggerAt, pendingIntent);
        }
    }

    /** 取消已登记的刷新（最后一个小组件被移除时调用）。 */
    public static void cancel(Context context) {
        AlarmManager alarmManager =
                (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) {
            return;
        }
        alarmManager.cancel(buildPendingIntent(context));
        Log.i(TAG, "cancel: scheduled refresh cancelled");
    }

    private static boolean canScheduleExactAlarms(AlarmManager alarmManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return alarmManager.canScheduleExactAlarms();
        }
        return true;
    }

    private static PendingIntent buildPendingIntent(Context context) {
        Intent intent = new Intent(context, ScheduleWidgetProvider.class);
        intent.setAction(ScheduleWidgetProvider.ACTION_SCHEDULED_UPDATE);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getBroadcast(context, 1001, intent, flags);
    }

    /**
     * 找出下一个会改变显示状态的时刻。
     * 对标 iOS 端 {@code calculateStateTransitions}，取其中最近的一个。
     */
    static Date calculateNextTransition(Context context, Date now) {
        WidgetScheduleData data = WidgetDataStore.loadWidgetData(context);
        Date midnight = nextMidnight(now);

        if (data == null) {
            return earlier(new Date(now.getTime() + FALLBACK_INTERVAL_MS), midnight);
        }

        WidgetScheduleData normalized = WidgetStateResolver.normalizeForCurrentDay(data, now);
        List<Date> transitions = new ArrayList<>();

        SchoolTimeTemplate template = normalized.timeTemplate;
        int approachingMinutes = normalized.resolveApproachingMinutes();
        int tomorrowPreviewHour = normalized.resolveTomorrowPreviewHour();

        for (WidgetCourse course : normalized.todayCourses) {
            SchoolTimeTemplate.ClassPeriod period =
                    template.getPeriodRange(course.startPeriod, course.periodCount);
            if (period == null) {
                continue;
            }

            Date start = WidgetStateResolver.parseTimeOnDate(period.startTime, now);
            if (start != null && start.after(now)) {
                transitions.add(start);

                // 进入"即将上课"的时刻
                Date approaching = new Date(start.getTime() - approachingMinutes * 60_000L);
                if (approaching.after(now)) {
                    transitions.add(approaching);
                }
            }

            Date end = WidgetStateResolver.parseTimeOnDate(period.endTime, now);
            if (end != null && end.after(now)) {
                transitions.add(end);
            }
        }

        // 明日预览切换点
        Calendar preview = Calendar.getInstance();
        preview.setTime(now);
        preview.set(Calendar.HOUR_OF_DAY, tomorrowPreviewHour);
        preview.set(Calendar.MINUTE, 0);
        preview.set(Calendar.SECOND, 0);
        preview.set(Calendar.MILLISECOND, 0);
        if (preview.getTime().after(now)) {
            transitions.add(preview.getTime());
        }

        // 次日零点：重置为新的一天
        transitions.add(midnight);

        Collections.sort(transitions);
        for (Date candidate : transitions) {
            if (candidate.after(now)) {
                return candidate;
            }
        }

        return midnight;
    }

    private static Date nextMidnight(Date now) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(now);
        calendar.add(Calendar.DAY_OF_MONTH, 1);
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 5);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTime();
    }

    private static Date earlier(Date a, Date b) {
        return a.before(b) ? a : b;
    }
}
