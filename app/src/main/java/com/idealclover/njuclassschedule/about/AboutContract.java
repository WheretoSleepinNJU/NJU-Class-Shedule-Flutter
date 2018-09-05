package com.idealclover.njuclassschedule.about;

import com.idealclover.njuclassschedule.BasePresenter;
import com.idealclover.njuclassschedule.BaseView;
import com.idealclover.njuclassschedule.data.bean.Course;
import com.idealclover.njuclassschedule.data.bean.Version;

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
