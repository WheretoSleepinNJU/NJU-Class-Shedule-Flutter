package com.lilystudio.wheretosleepinnju.impt;


import android.widget.ImageView;

import com.lilystudio.wheretosleepinnju.BasePresenter;
import com.lilystudio.wheretosleepinnju.BaseView;
import com.lilystudio.wheretosleepinnju.data.bean.CourseTime;

/**
 * Created by mnnyang on 17-10-3.
 */

public interface ImptContract {
    interface Presenter extends BasePresenter {

        void importCustomCourses(String courseTime, String term);

        void importDefaultCourses(String courseTime, String term);

        void loadCourseTimeAndTerm(String xh, String pwd, String captcha);

        void getCaptcha();
    }

    interface View extends BaseView<Presenter> {
        ImageView getCaptchaIV();

        void showImpting();

        void hideImpting();

        void captchaIsLoading(boolean isLoading);

        void showErrToast(String errMsg, boolean reLoad);

        void showSucceed();

        void showCourseTimeDialog(CourseTime times);
    }

    interface Model {
        void getCaptcha(ImageView iv);
    }
}
