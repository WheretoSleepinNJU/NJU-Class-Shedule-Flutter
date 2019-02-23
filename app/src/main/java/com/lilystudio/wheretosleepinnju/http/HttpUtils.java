package com.lilystudio.wheretosleepinnju.http;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.lilystudio.wheretosleepinnju.R;
import com.lilystudio.wheretosleepinnju.app.Url;
import com.lilystudio.wheretosleepinnju.app.app;
import com.lilystudio.wheretosleepinnju.utils.spec.ParseCourse;
import com.lilystudio.wheretosleepinnju.utils.LogUtil;
import com.zhy.http.okhttp.OkHttpUtils;
import com.zhy.http.okhttp.callback.FileCallBack;
import com.zhy.http.okhttp.callback.StringCallback;

import java.io.File;

import okhttp3.Call;

/**
 * Created by mnnyang on 17-10-19.
 * Changed by idealclover on 18-07-07
 */

public class HttpUtils {
    public static final String ACCESS_ERR = "抱歉,访问出错,请重试";
    public static final String ACCESS_ERR2 = "ERROR";

    private HttpUtils() {
    }

    private static class Holder {
        private static final HttpUtils HTTP_UTILS = new HttpUtils();
    }

    public static HttpUtils newInstance() {
        return Holder.HTTP_UTILS;
    }


    public void testUrl(String url, final HttpCallback<String> callback) {
        OkHttpUtils.get().url(url).build().execute(new StringCallback() {
            @Override
            public void onError(Call call, Exception e, int id) {
                callback.onFail(e.getMessage());
                e.printStackTrace();
            }

            @Override
            public void onResponse(String response, int id) {
                callback.onSuccess(response);
            }
        });
    }

    public void loadCaptcha(final File dir, final String schoolUrl, final HttpCallback<Bitmap> callback) {
        OkHttpUtils.get().url(schoolUrl + Url.CheckCode).build().execute(
                new FileCallBack(dir.getAbsolutePath(), "loadCaptcha.jpg") {
                    @Override
                    public void onError(Call call, Exception e, int id) {
                        e.printStackTrace();
                        callback.onFail(ACCESS_ERR);
                    }

                    @Override
                    public void onResponse(File response, int id) {
                        Bitmap bitmap = BitmapFactory.decodeFile(
                                dir.getAbsolutePath() + "/loadCaptcha.jpg");
                        callback.onSuccess(bitmap);
                    }
                });
    }

    public void login(final String schoolUrl, final String xh, String passwd, String catpcha,
                      final String courseTime, final String term,
                      final HttpCallback<String> callback) {
        OkHttpUtils.post().url(schoolUrl + Url.LoginUrl)
                .addParams("userName", xh)
                .addParams("password", passwd)
                .addParams("ValidateCode", catpcha)
                .build().execute(new StringCallback() {
            @Override
            public void onError(Call call, Exception e, int id) {
                e.printStackTrace();
                callback.onFail(ACCESS_ERR);
            }

            @Override
            public void onResponse(String response, int id) {
                LogUtil.e(this, response);

                if (response.contains(app.mContext.getString(R.string.captcha_err))) {
                    callback.onFail(app.mContext.getString(R.string.captcha_err));
                } else if (response.contains(app.mContext.getString(R.string.pwd_err))) {
                    callback.onFail(app.mContext.getString(R.string.pwd_err));
                } else if (response.contains(app.mContext.getString(R.string.timeout_err))) {
                    callback.onFail(app.mContext.getString(R.string.timeout_err));
                } else {
                    toImpt(xh, schoolUrl, callback);
                }
            }
        });
    }

    /**
     * get normal
     *
     * @param xh
     * @param callback
     */
    public void toImpt(String xh, String schoolUrl, final HttpCallback<String> callback) {
        LogUtil.d(this, "get normal+" + xh);
        OkHttpUtils.get().url(schoolUrl + Url.ClassInfo)
                .build()
                .execute(new StringCallback() {
                    @Override
                    public void onError(Call call, Exception e, int id) {
                        e.printStackTrace();
                        callback.onFail(ACCESS_ERR2);
                    }

                    @Override
                    public void onResponse(String response, int id) {
                        Url.VIEWSTATE_POST_CODE = ParseCourse.parseViewStateCode(response);
                        callback.onSuccess(response);
                    }
                });
    }

    /**
     * 上传解析失败的课表html
     *
     * @param tag
     * @param html
     */
    public void uploadParsingFailedTable(Object tag, String html) {
        String newTag = LogUtil.getNewTag(tag);

    }
}