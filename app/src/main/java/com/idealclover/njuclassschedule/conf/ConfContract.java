package com.idealclover.njuclassschedule.conf;

import com.idealclover.njuclassschedule.BasePresenter;
import com.idealclover.njuclassschedule.BaseView;

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
