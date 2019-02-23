package com.lilystudio.wheretosleepinnju.setting;


import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;

/**
 * Created by mnnyang on 17-10-3.
 */

public interface SettingContract {
    interface Presenter extends BasePresenter {
        void feedback();
    }

    interface View extends BaseView<Presenter> {
        void showNotice(String notice);
    }
}
