package com.idealclover.wheretosleepinnju.about;

import com.idealclover.wheretosleepinnju.BasePresenter;
import com.idealclover.wheretosleepinnju.BaseView;
import com.idealclover.wheretosleepinnju.data.bean.Course;
import com.idealclover.wheretosleepinnju.data.bean.Version;

/**
 * Created by mnnyang on 17-11-3.
 */

public interface AboutContract {
    interface Presenter extends BasePresenter {
        void checkUpdate();
    }

    interface View extends BaseView<AboutContract.Presenter> {
        void showNotice(String notice);
        void showUpdateVersionInfo(Version version);
    }
}
