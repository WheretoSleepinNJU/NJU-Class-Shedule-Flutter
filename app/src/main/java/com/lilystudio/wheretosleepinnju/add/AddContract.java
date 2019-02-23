package com.lilystudio.wheretosleepinnju.add;

import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;
import com.lilystudio.wheretosleepinnju.data.bean.Course;

/**
 * Created by mnnyang on 17-11-3.
 */

public interface AddContract {
    interface Presenter extends BasePresenter {
        void addCourse(Course course);
        void removeCourse(int courseId);
        void updateCourse(Course course);
    }

    interface View extends BaseView<AddContract.Presenter> {
        void showAddFail(String msg);
        void onAddSucceed(Course course);
        void onDelSucceed();
        void onUpdateSucceed(Course course);
    }
}
