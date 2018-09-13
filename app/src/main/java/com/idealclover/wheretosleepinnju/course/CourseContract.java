package com.idealclover.wheretosleepinnju.course;


import android.graphics.Bitmap;

import com.idealclover.wheretosleepinnju.BasePresenter;
import com.idealclover.wheretosleepinnju.BaseView;
import com.idealclover.wheretosleepinnju.data.bean.Course;

import java.util.ArrayList;

/**
 * Created by mnnyang on 17-10-3.
 */

public interface CourseContract {
    interface Presenter extends BasePresenter {
        void loadBackground();
        void updateCourseViewData(int csNameId);
        void deleteCourse(int courseId);
    }

    interface View extends BaseView<Presenter> {
        void initFirstStart();
        void setBackground(Bitmap background);
        void setCourseData(ArrayList<Course> courses);
        void updateCoursePreference();
        void updateOtherPreference();
    }


}
