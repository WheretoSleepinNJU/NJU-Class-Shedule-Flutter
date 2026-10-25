package com.lilystudio.wheretosleepinnju.widget;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.widget.RemoteViews;
import android.os.Build;
import android.content.ComponentName;
import android.util.SizeF;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 课表桌面小组件。
 *
 * 对标 iOS 端 {@code ScheduleWidget}：读取共享数据 → 解析显示状态 → 渲染对应尺寸的视图，
 * 并在下一个状态转换点安排刷新。
 */
public class ScheduleWidgetProvider extends AppWidgetProvider {

    private static final String TAG = "ScheduleWidgetProvider";

    /** Flutter 侧下发新数据后主动触发的刷新。 */
    public static final String ACTION_REFRESH =
            "com.lilystudio.wheretosleepinnju.widget.ACTION_REFRESH";

    /** AlarmManager 到点唤醒的刷新。 */
    public static final String ACTION_SCHEDULED_UPDATE =
            "com.lilystudio.wheretosleepinnju.widget.ACTION_SCHEDULED_UPDATE";

    /** 点击"我已到达"。 */
    public static final String ACTION_COURSE_ARRIVED =
            "com.lilystudio.wheretosleepinnju.widget.ACTION_COURSE_ARRIVED";

    public static final String EXTRA_COURSE_ID = "course_id";

    /** 尺寸判定阈值（dp），用于在三套布局之间切换。 */
    private static final int MEDIUM_MIN_WIDTH_DP = 220;
    private static final int LARGE_MIN_HEIGHT_DP = 220;

    // ------------------------------------------------------------------
    // 对外入口
    // ------------------------------------------------------------------

    /** 供 App 侧（MethodChannel）调用：立即刷新全部小组件。 */
    public static void refreshAllWidgets(Context context) {
        Context appContext = context.getApplicationContext();
        AppWidgetManager manager = AppWidgetManager.getInstance(appContext);
        int[] ids = allWidgetIds(appContext, manager);

        if (ids == null || ids.length == 0) {
            Log.i(TAG, "refreshAllWidgets: no widget placed on launcher");
            return;
        }

        for (int id : ids) {
            updateWidget(appContext, manager, id);
        }
        WidgetUpdateScheduler.scheduleNext(appContext);
        Log.i(TAG, "refreshAllWidgets: refreshed " + ids.length + " widget(s)");
    }

    // ------------------------------------------------------------------
    // 生命周期
    // ------------------------------------------------------------------

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId);
        }
        WidgetUpdateScheduler.scheduleNext(context);
    }

    @Override
    public void onAppWidgetOptionsChanged(Context context,
                                          AppWidgetManager appWidgetManager,
                                          int appWidgetId,
                                          Bundle newOptions) {
        // 用户拉伸小组件后需要按新尺寸重绘
        updateWidget(context, appWidgetManager, appWidgetId);
    }

    @Override
    public void onEnabled(Context context) {
        WidgetUpdateScheduler.scheduleNext(context);
    }

    @Override
    public void onDisabled(Context context) {
        // Each provider receives onDisabled independently. Keep the other size alive.
        if (allWidgetIds(context, AppWidgetManager.getInstance(context)).length == 0) {
            WidgetUpdateScheduler.cancel(context);
        } else {
            WidgetUpdateScheduler.scheduleNext(context);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);

        String action = intent == null ? null : intent.getAction();
        if (action == null) {
            return;
        }

        switch (action) {
            case ACTION_REFRESH:
            case ACTION_SCHEDULED_UPDATE:
            case Intent.ACTION_TIME_CHANGED:
            case Intent.ACTION_TIMEZONE_CHANGED:
            case Intent.ACTION_DATE_CHANGED:
            case Intent.ACTION_BOOT_COMPLETED:
                // 系统时间 / 时区 / 日期变化都会影响状态判定，需要整体重绘
                refreshAllWidgets(context);
                break;

            case ACTION_COURSE_ARRIVED:
                handleArrived(context, intent.getStringExtra(EXTRA_COURSE_ID));
                break;

            default:
                break;
        }
    }

    // ------------------------------------------------------------------
    // 内部逻辑
    // ------------------------------------------------------------------

    private static void updateWidget(Context context,
                                     AppWidgetManager appWidgetManager,
                                     int appWidgetId) {
        try {
            WidgetStateResolver.WidgetState state = WidgetStateResolver.resolve(context);
            WidgetRenderer.SizeClass sizeClass =
                    resolveSizeClass(appWidgetManager, appWidgetId);
            RemoteViews views;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Map<SizeF, RemoteViews> layouts = new LinkedHashMap<>();
                layouts.put(new SizeF(110, 110), WidgetRenderer.render(context, state,
                        WidgetRenderer.SizeClass.SMALL, appWidgetId));
                layouts.put(new SizeF(MEDIUM_MIN_WIDTH_DP, 110), WidgetRenderer.render(context, state,
                        WidgetRenderer.SizeClass.MEDIUM, appWidgetId));
                layouts.put(new SizeF(MEDIUM_MIN_WIDTH_DP, LARGE_MIN_HEIGHT_DP),
                        WidgetRenderer.render(context, state, WidgetRenderer.SizeClass.LARGE, appWidgetId));
                views = new RemoteViews(layouts);
            } else {
                views = WidgetRenderer.render(context, state, sizeClass, appWidgetId);
            }
            appWidgetManager.updateAppWidget(appWidgetId, views);
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId,
                    com.lilystudio.wheretosleepinnju.R.id.widget_course_container);
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId,
                    com.lilystudio.wheretosleepinnju.R.id.widget_right_container);
        } catch (Exception e) {
            // 小组件里抛异常会被系统标记为"无法加载"，这里兜底渲染错误态
            Log.e(TAG, "updateWidget failed for id=" + appWidgetId, e);
            try {
                WidgetStateResolver.WidgetState errorState =
                        WidgetStateResolver.resolve(context, new java.util.Date());
                appWidgetManager.updateAppWidget(appWidgetId,
                        WidgetRenderer.render(context, errorState, WidgetRenderer.SizeClass.SMALL,
                                appWidgetId));
            } catch (Exception ignored) {
                Log.e(TAG, "updateWidget fallback also failed", ignored);
            }
        }
    }

    /** 根据桌面实际给到的尺寸挑选布局，对应 iOS 的 systemSmall / Medium / Large。 */
    private static WidgetRenderer.SizeClass resolveSizeClass(AppWidgetManager appWidgetManager,
                                                             int appWidgetId) {
        Bundle options = appWidgetManager.getAppWidgetOptions(appWidgetId);
        if (options == null) {
            return WidgetRenderer.SizeClass.SMALL;
        }

        int minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0);
        int minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0);

        if (minWidth <= 0) {
            android.appwidget.AppWidgetProviderInfo info = appWidgetManager.getAppWidgetInfo(appWidgetId);
            return info != null && info.provider.getClassName().equals(
                    ScheduleMediumWidgetProvider.class.getName())
                    ? WidgetRenderer.SizeClass.MEDIUM : WidgetRenderer.SizeClass.SMALL;
        }

        boolean wide = minWidth >= MEDIUM_MIN_WIDTH_DP;
        boolean tall = minHeight >= LARGE_MIN_HEIGHT_DP;

        if (wide && tall) {
            return WidgetRenderer.SizeClass.LARGE;
        }
        if (wide) {
            return WidgetRenderer.SizeClass.MEDIUM;
        }
        return WidgetRenderer.SizeClass.SMALL;
    }

    private static int[] allWidgetIds(Context context, AppWidgetManager manager) {
        ArrayList<Integer> ids = new ArrayList<>();
        for (Class<?> provider : new Class<?>[]{ScheduleWidgetProvider.class,
                ScheduleMediumWidgetProvider.class}) {
            for (int id : manager.getAppWidgetIds(new ComponentName(context, provider))) ids.add(id);
        }
        int[] result = new int[ids.size()];
        for (int i = 0; i < ids.size(); i++) result[i] = ids.get(i);
        return result;
    }

    /**
     * 处理"我已到达"：记录状态并打开 App。
     * 对标 iOS 端 AppDelegate 的 {@code handleArrivedDeepLink}。
     */
    private static void handleArrived(Context context, String courseId) {
        if (courseId == null || courseId.isEmpty()) {
            Log.w(TAG, "handleArrived: missing course id");
            return;
        }

        WidgetDataStore.setArrivedCourse(context, courseId);
        Log.i(TAG, "handleArrived: course " + courseId);

        refreshAllWidgets(context);

        // 与 iOS 行为一致，点击后打开应用
        Intent launch = new Intent(Intent.ACTION_VIEW, Uri.parse("ncs://arrived/" + courseId));
        launch.setPackage(context.getPackageName());
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        try {
            context.startActivity(launch);
        } catch (Exception e) {
            Log.w(TAG, "handleArrived: cannot launch app", e);
        }
    }
}
