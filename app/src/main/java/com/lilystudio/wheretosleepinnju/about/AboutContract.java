package com.lilystudio.wheretosleepinnju.about;

import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;

/**
 * Created by mnnyang on 17-11-3.
 */

public interface AboutContract {
    interface Presenter extends BasePresenter {
        void checkUpdate();
    }

    interface View extends BaseView<AboutContract.Presenter> {
        void showNotice(String notice);
    }
}
