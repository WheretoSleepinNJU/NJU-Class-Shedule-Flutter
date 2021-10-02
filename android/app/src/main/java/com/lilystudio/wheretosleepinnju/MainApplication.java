package com.lilystudio.wheretosleepinnju;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import io.flutter.app.FlutterApplication;
import com.umeng.commonsdk.UMConfigure;
import com.umeng.analytics.MobclickAgent;

public class MainApplication extends FlutterApplication {
//    SharedPreferencesHelper sharedPreferencesHelper;
    @Override
    public void onCreate() {
        super.onCreate();
//        sharedPreferencesHelper=new SharedPreferencesHelper(this,"umeng");

        //设置LOG开关，默认为false
//        UMConfigure.setLogEnabled(true);

        //友盟预初始化
        UMConfigure.preInit(getApplicationContext(),"5f8ef217fac90f1c19a7b0f3","Umeng");

        /**
         * 打开app首次隐私协议授权，以及sdk初始化，判断逻辑请查看SplashTestActivity
         */
        //判断是否同意隐私协议，uminit为1时为已经同意，直接初始化umsdk
//        if(sharedPreferencesHelper.getSharedPreference("uminit","").equals("1")){
        //友盟正式初始化
//        UmInitConfig umInitConfig=new UmInitConfig();
//        umInitConfig.UMinit(getApplicationContext());
//        }

//        super.onCreate();
        UMConfigure.init(this, "5f8ef217fac90f1c19a7b0f3", "Umeng", UMConfigure.DEVICE_TYPE_PHONE, "");
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO);
        android.util.Log.i("UMLog", "UMConfigure.init@MainApplication");
        UMConfigure.setLogEnabled(true);
    }
}