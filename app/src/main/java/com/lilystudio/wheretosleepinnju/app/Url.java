package com.lilystudio.wheretosleepinnju.app;

/**
 * Created by mnnyang on 17-10-23.
 * Changed by idealclover on 18-07-07
 */

public class Url {

    /**
     * 南京大学正方教务管理系统
     */
    public static final String URL_NJU_HOST = "http://elite.nju.edu.cn/jiaowu/";

//    dev更新地址
//    public static final String URL_CHECK_UPDATE_APP = "https://raw.githubusercontent.com/idealclover/NJU-Class-Shedule-Android/dev/check.json";
//    测试版更新地址
//    public static final String URL_CHECK_UPDATE_APP = "https://clover-1254951786.cos.ap-shanghai.myqcloud.com/RELEASE/check.json";
//    正式版更新地址
    public static final String URL_CHECK_UPDATE_APP = "https://raw.githubusercontent.com/idealclover/NJU-Class-Shedule-Android/master/check.json";
//    检查更新失败
//    public static final String URL_CHECK_UPDATE_APP = "https://raw.githubusercontent.com/idealclover/NJU-Class-Shedule-Android/master/qwq.json";

    public static final String CheckCode = "ValidateCode.jsp";
    public static final String ClassInfo = "student/teachinginfo/courseList.do?method=currentTermCourse";
    public static final String LoginUrl = "login.do";

//    public static final String PARAM_XH = "xh";
//    public static final String PARAM_XND = "xnd";
//    public static final String PARAM_XQD = "xqd";

    public static final String __VIEWSTATE = "__VIEWSTATE";
    public static String VIEWSTATE_POST_CODE = "";
//    public static String VIEWSTATE_LOGIN_CODE = "";
}
