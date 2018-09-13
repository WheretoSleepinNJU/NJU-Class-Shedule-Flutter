package com.idealclover.wheretosleepinnju.utils;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;

import com.google.gson.Gson;
import com.idealclover.wheretosleepinnju.app.Url;
import com.idealclover.wheretosleepinnju.data.bean.Version;
import com.idealclover.wheretosleepinnju.http.HttpCallback;
import com.zhy.http.okhttp.OkHttpUtils;
import com.zhy.http.okhttp.callback.StringCallback;

import okhttp3.Call;

/**
 * Created by mnnyang on 17-11-7.
 * Changed by idealclover on 18-09-06
 */

public class VersionUpdate {

    public void checkUpdate(final HttpCallback<Version> callback) {
        OkHttpUtils.get().url(Url.URL_CHECK_UPDATE_APP)
                .build().execute(new StringCallback() {
            @Override
            public void onError(Call call, Exception e, int id) {
                e.printStackTrace();
                callback.onFail(e.getMessage());
            }

            @Override
            public void onResponse(String response, int id) {
                try {
                    Gson gson = new Gson();
                    Version version = gson.fromJson(response, Version.class);
                    callback.onSuccess(version);
                } catch (Exception e) {
                    e.printStackTrace();
                    callback.onFail("parse error");
                }
            }
        });
    }

    /**
     * 获取本地软件版本号
     */
    public int getLocalVersion(Context ctx) {
        int localVersion = 0;
        try {
            PackageInfo packageInfo = ctx.getApplicationContext()
                    .getPackageManager()
                    .getPackageInfo(ctx.getPackageName(), 0);
            localVersion = packageInfo.versionCode;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        return localVersion;
    }

    /**
     * 获取本地软件版本号名称
     */
    public String getLocalVersionName(Context ctx) {
        String localVersion = "";
        try {
            PackageInfo packageInfo = ctx.getApplicationContext()
                    .getPackageManager()
                    .getPackageInfo(ctx.getPackageName(), 0);
            localVersion = packageInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }

        return localVersion;
    }

    public static  void goToMarket(Context context, String link) {
//        String packageName ="com.idealclover.njuclassschedule";
        String packageName ="com.idealclover.wheretosleepinnju";
//        Uri uri = Uri.parse("market://details?id=" + packageName);
        Uri uri = Uri.parse(link);
        Intent goToMarket = new Intent(Intent.ACTION_VIEW, uri);
        try {
            context.startActivity(goToMarket);
        } catch (ActivityNotFoundException e) {
            e.printStackTrace();
        }
    }
}
