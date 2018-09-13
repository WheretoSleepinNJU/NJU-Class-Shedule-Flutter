package com.idealclover.wheretosleepinnju.about;

import com.idealclover.wheretosleepinnju.R;
import com.idealclover.wheretosleepinnju.app.Url;
import com.idealclover.wheretosleepinnju.app.app;
import com.idealclover.wheretosleepinnju.data.bean.Version;
import com.idealclover.wheretosleepinnju.http.HttpCallback;
import com.idealclover.wheretosleepinnju.utils.LogUtil;
import com.idealclover.wheretosleepinnju.utils.ToastUtils;
import com.idealclover.wheretosleepinnju.utils.VersionUpdate;

/**
 * Created by xxyangyoulin on 2018/3/13.
 * Changed by idealclover on 18-09-06
 */

public class AboutPresenter implements AboutContract.Presenter {
    private AboutContract.View mView;

    public AboutPresenter(AboutContract.View mView) {
        this.mView = mView;
    }

    @Override
    public void start() {

    }

    @Override
    public void checkUpdate() {
        mView.showNotice(app.mContext.getString(R.string.checking_for_updates));

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
                    mView.showUpdateVersionInfo(version);
                } else {
                    mView.showNotice(app.mContext.getString(R.string.already_the_latest_version));
                }
            }

            @Override
            public void onFail(String errMsg) {
                LogUtil.e(this, errMsg);
                ToastUtils.show(app.mContext.getString(R.string.access_err));
            }
        });
    }
}
