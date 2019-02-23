package com.lilystudio.wheretosleepinnju.utils;

import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;

import com.lilystudio.wheretosleepinnju.R;
import com.lilystudio.wheretosleepinnju.app.app;
import com.lilystudio.wheretosleepinnju.data.bean.Version;
import com.lilystudio.wheretosleepinnju.http.HttpCallback;


public class CheckUpdateUtil {

    public static Context context;

    public static void init(Context context) {
        CheckUpdateUtil.context = context.getApplicationContext();
    }

    public void checkUpdate(final Activity activity) {
//        showNotice(app.mContext.getString(R.string.checking_for_updates));

        final VersionUpdate versionUpdate = new VersionUpdate();
        versionUpdate.checkUpdate(new HttpCallback<Version>() {
            @Override
            public void onSuccess(Version version) {
                if (version == null) {
                    LogUtil.e(this, "version object is null");
                    return;
                }
                int localVersion = versionUpdate.getLocalVersion(app.mContext);

                LogUtil.d(this, String.valueOf(version.getCode()));
                if (version.getVersion() > localVersion) {
                    showUpdateVersionInfo(activity, version);
                } else {
//                    showNotice(app.mContext.getString(R.string.already_the_latest_version));
                }
            }

            @Override
            public void onFail(String errMsg) {
                LogUtil.e(this, errMsg);
//                ToastUtils.show(app.mContext.getString(R.string.access_update_err));
            }
        });
    }

    public void showNotice(String notice) {
        ToastUtils.show(notice);
    }

    public void showUpdateVersionInfo(Activity activity, Version version) {
        final String link = version.getLink();
        DialogHelper dialogHelper = new DialogHelper();
        dialogHelper.showNormalDialog(activity, app.mContext.getString(R.string.now_version), version.getMsg(), new DialogListener() {
            public void onPositive(DialogInterface dialog, int which) {
                super.onPositive(dialog, which);
                VersionUpdate.goToMarket(context, link);
            }
        });
    }


}
