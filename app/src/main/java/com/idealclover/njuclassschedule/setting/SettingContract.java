package com.idealclover.njuclassschedule.setting;


import com.idealclover.njuclassschedule.BasePresenter;
import com.idealclover.njuclassschedule.BaseView;
import com.idealclover.njuclassschedule.data.bean.Course;
import com.idealclover.njuclassschedule.http.HttpCallback;

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
