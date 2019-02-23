package com.lilystudio.wheretosleepinnju.about;
import com.tencent.bugly.beta.Beta;

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
        Beta.checkUpgrade();
    }
}
