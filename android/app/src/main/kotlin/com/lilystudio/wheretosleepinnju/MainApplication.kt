package com.lilystudio.wheretosleepinnju;

import io.flutter.app.FlutterApplication
import com.umeng.commonsdk.UMConfigure
import com.umeng.analytics.MobclickAgent

class MainApplication : FlutterApplication() {
    //    SharedPreferencesHelper sharedPreferencesHelper;
    override fun onCreate() {
        super.onCreate()

        //友盟预初始化
        UMConfigure.preInit(getApplicationContext(), "5f8ef217fac90f1c19a7b0f3", "Umeng")
        UMConfigure.init(this, "5f8ef217fac90f1c19a7b0f3", "Umeng", UMConfigure.DEVICE_TYPE_PHONE, "")
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
        android.util.Log.i("UMLog", "UMConfigure.init@MainApplication")
        UMConfigure.setLogEnabled(true)
    }
}
