package com.lilystudio.wheretosleepinnju;

import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import com.umeng.analytics.MobclickAgent;
import com.lilystudio.wheretosleepinnju.widget.WidgetDataChannel;

public class MainActivity extends FlutterActivity {

    private WidgetDataChannel widgetDataChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // 注册桌面小组件数据通道，对应 iOS 端 AppDelegate.setupWidgetDataChannel()
        widgetDataChannel = new WidgetDataChannel(getApplicationContext());
        widgetDataChannel.register(flutterEngine.getDartExecutor().getBinaryMessenger());
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (widgetDataChannel != null) {
            widgetDataChannel.unregister();
            widgetDataChannel = null;
        }
        super.cleanUpFlutterEngine(flutterEngine);
    }

//    @Override
//    public void configureFlutterEngine(FlutterEngine flutterEngine) {
//        GeneratedPluginRegistrant.registerWith(flutterEngine);
//    }
//
//    @Override
//    protected void onCreate(Bundle savedInstanceState) {
//        super.onCreate(savedInstanceState);
//        com.lilystudio.wheretosleepinnju.UmengSdkPlugin.setContext(this);
//        android.util.Log.i("UMLog", "onCreate@MainActivity");
//    }
//
//    @Override
//    protected void onPause() {
//        super.onPause();
//        MobclickAgent.onPause(this);
//        android.util.Log.i("UMLog", "onPause@MainActivity");
//    }
//
//    @Override
//    protected void onResume() {
//        super.onResume();
//        MobclickAgent.onResume(this);
//        android.util.Log.i("UMLog", "onResume@MainActivity");
//    }
}
