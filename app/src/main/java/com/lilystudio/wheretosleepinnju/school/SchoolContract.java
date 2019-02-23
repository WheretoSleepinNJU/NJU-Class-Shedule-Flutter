package com.lilystudio.wheretosleepinnju.school;


import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;

/**
 * Created by mnnyang on 17-10-3.
 */

public interface SchoolContract {
    interface Presenter extends BasePresenter {
        void testUrl(String url);
    }

    interface View extends BaseView<Presenter> {
        void showNotice(String notice);

        void showInputDialog();

        void testingUrl(boolean bool);

        void testUrlFailed(String url);

        void testUrlSucceed(String url);
    }
}
