package com.lilystudio.wheretosleepinnju;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import io.flutter.app.FlutterApplication;
import com.umeng.commonsdk.UMConfigure;
import com.umeng.analytics.MobclickAgent;

public class MainApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        UMConfigure.init(this, "5f8ef217fac90f1c19a7b0f3", "Umeng", UMConfigure.DEVICE_TYPE_PHONE, "");
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO);
        android.util.Log.i("UMLog", "UMConfigure.init@MainApplication");
//        UMConfigure.setLogEnabled(true);
    }
}