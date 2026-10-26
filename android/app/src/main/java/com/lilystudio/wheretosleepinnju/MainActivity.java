package com.lilystudio.wheretosleepinnju;

import androidx.annotation.NonNull;
import com.lilystudio.wheretosleepinnju.liveactivity.CourseActivityEngine;
import com.lilystudio.wheretosleepinnju.widget.WidgetDataChannel;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private WidgetDataChannel widgetDataChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        com.lilystudio.wheretosleepinnju.liveactivity.CourseLiveActivityBridge.initialize(this);
        widgetDataChannel = new WidgetDataChannel(this);
        widgetDataChannel.register(flutterEngine.getDartExecutor().getBinaryMessenger());
    }

    @Override
    protected void onResume() {
        super.onResume();
        CourseActivityEngine.setAppForeground(true);
        CourseActivityEngine.reconcile(this, true);
    }

    @Override
    protected void onPause() {
        CourseActivityEngine.setAppForeground(false);
        super.onPause();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                          @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 7103) CourseActivityEngine.reconcile(this, true);
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (widgetDataChannel != null) {
            widgetDataChannel.unregister();
            widgetDataChannel = null;
        }
        super.cleanUpFlutterEngine(flutterEngine);
    }
}
