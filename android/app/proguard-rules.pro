-keep class com.umeng.** {*;}

-keep class com.uc.** {*;}

-keepclassmembers class * {
   public <init> (org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keep class com.zui.** {*;}
-keep class com.miui.** {*;}
-keep class com.heytap.** {*;}
-keep class a.** {*;}
-keep class com.vivo.** {*;}

# 桌面小组件：AppWidgetProvider 由系统按 Manifest 中的类名反射实例化，
# 混淆或裁剪后桌面会直接加载失败，必须整体保留。
-keep class com.lilystudio.wheretosleepinnju.widget.** { *; }
-keep class * extends android.appwidget.AppWidgetProvider { *; }

# Shizuku starts this class by its public no-argument constructor via app_process.
-keep class com.lilystudio.wheretosleepinnju.liveactivity.IslandShizukuService { *; }
-keep class com.lilystudio.wheretosleepinnju.liveactivity.IIslandFirewall** { *; }
