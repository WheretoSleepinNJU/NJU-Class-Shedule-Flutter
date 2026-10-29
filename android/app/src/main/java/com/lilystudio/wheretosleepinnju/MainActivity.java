package com.lilystudio.wheretosleepinnju;

import androidx.annotation.NonNull;
import com.lilystudio.wheretosleepinnju.liveactivity.CourseActivityEngine;
import com.lilystudio.wheretosleepinnju.widget.WidgetDataChannel;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.RenderMode;
import com.lilystudio.wheretosleepinnju.compose.AdaptiveChromeHost;
import android.os.Build;
import android.os.Bundle;
import android.view.MotionEvent;
import androidx.core.view.WindowCompat;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private WidgetDataChannel widgetDataChannel;
    private AdaptiveChromeHost adaptiveChromeHost;
    private MethodChannel composeSupportChannel;

    @NonNull
    @Override
    public RenderMode getRenderMode() {
        return Build.VERSION.SDK_INT >= 33
                ? RenderMode.texture : super.getRenderMode();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WindowCompat.enableEdgeToEdge(getWindow());
        if (Build.VERSION.SDK_INT >= 33
                && adaptiveChromeHost != null) {
            adaptiveChromeHost.enableSharedGpuRoot();
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        com.lilystudio.wheretosleepinnju.liveactivity.CourseLiveActivityBridge.initialize(this);
        composeSupportChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "nju/compose-support");
        composeSupportChannel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("isSupported") || call.method.equals("supportsTitleBar")) {
                result.success(adaptiveChromeHost != null && adaptiveChromeHost.isSupported());
            }
            else result.notImplemented();
        });
        if (Build.VERSION.SDK_INT >= 33) {
            adaptiveChromeHost = new AdaptiveChromeHost(this, flutterEngine);
        }
        widgetDataChannel = new WidgetDataChannel(this);
        widgetDataChannel.register(flutterEngine.getDartExecutor().getBinaryMessenger());
    }

    @Override
    protected void onResume() {
        super.onResume();
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        if (adaptiveChromeHost != null) adaptiveChromeHost.setResumed(true);
        CourseActivityEngine.setAppForeground(true);
        CourseActivityEngine.reconcile(this, true);
    }

    @Override
    protected void onPause() {
        if (adaptiveChromeHost != null) adaptiveChromeHost.setResumed(false);
        CourseActivityEngine.setAppForeground(false);
        super.onPause();
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent event) {
        if (adaptiveChromeHost != null) adaptiveChromeHost.onWindowTouch(event);
        return super.dispatchTouchEvent(event);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        if (adaptiveChromeHost != null) adaptiveChromeHost.onWindowFocusChanged(hasFocus);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                          @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 7103) CourseActivityEngine.reconcile(this, true);
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (adaptiveChromeHost != null) {
            adaptiveChromeHost.dispose();
            adaptiveChromeHost = null;
        }
        if (composeSupportChannel != null) {
            composeSupportChannel.setMethodCallHandler(null);
            composeSupportChannel = null;
        }
        if (widgetDataChannel != null) {
            widgetDataChannel.unregister();
            widgetDataChannel = null;
        }
        super.cleanUpFlutterEngine(flutterEngine);
    }
}
