package com.lilystudio.wheretosleepinnju.conf;

import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;

/**
 * Created by mnnyang on 17-11-3.
 */

public interface ConfContract {
    interface Presenter extends BasePresenter {
    }

    interface View extends BaseView<ConfContract.Presenter> {
        void confBgImage();
    }
}
