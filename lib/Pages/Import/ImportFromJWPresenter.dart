import 'package:flutter/material.dart';
import '../../Resources/Url.dart';
import '../../Utils/HttpUtil.dart';
import '../../Resources/Constant.dart';
import '../../Utils/CourseParser.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseTableModel.dart';
import '../../Models/CourseModel.dart';

class ImportFromJWPresenter {
  HttpUtil httpUtil = HttpUtil();

  Future<Image> getCaptcha(double num) async {
    await httpUtil.getWithCookie(Url.URL_NJU_HOST);
    String cookies = httpUtil.getCookies();
    return Image.network(
        'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp?TimeCode=' +
//        'http://cer.nju.edu.cn/amserver/verify/image.jsp?' +
            num.toString() +
            '100',
        headers: {"Cookie": cookies.toString()});
  }

  Future<int> login(String usr, String pwd, String captcha) async {
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
    String response = await httpUtil.post(url, {
      'userName': usr,
      'password': pwd,
      'ValidateCode': captcha,
    });
//    print(response);
    if (response.contains('验证码错误！') || response.contains('验证码已过期，请重新登录！')) {
      return Constant.CAPTCHA_ERROR;
    } else if (response.contains('密码错误！')) {
      return Constant.PASSWORD_ERROR;
    } else if (response.contains('用户名错误！')) {
      return Constant.USERNAME_ERROR;
    } else {
      return Constant.LOGIN_CORRECT;
    }
//    response.then((String response) {
////      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }

  Future<bool> getClasses(BuildContext context) async {
    String url = Url.URL_NJU_HOST + Url.ClassInfo;
    String response = await httpUtil.get(url);
//    print(response);
    CourseParser cp = CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    try {
      await cp.parseCourse(rst);
      return true;
    } catch (e) {
      return false;
    }
//    print(rst);
//    Future<String> response = httpUtil.get(url);
//    response.then((String response) {
//      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }

  Future<bool> getDemoClasses(BuildContext context) async {
    // same in CourseParser.dart
    CourseTableProvider courseTableProvider = CourseTableProvider();
    CourseTable courseTable =
        await courseTableProvider.insert(CourseTable('Demo课表'));
    // 减1的原因：SQL中id从1开始计
    MainStateModel.of(context).changeclassTable(courseTable.id!);
    CourseProvider courseProvider = CourseProvider();
    await courseProvider.insert(Course(
        courseTable.id, "自动导入", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
        classroom: 'QAQ'));
    await courseProvider.insert(Course(
        courseTable.id, "手动导入", "[1,2,3,4,5,6,7]", 4, 2, 3, 1,
        classroom: '仙林校区不知道哪个教室'));
    await courseProvider.insert(Course(
        courseTable.id, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
        classroom: 'QAQ'));
    return true;
  }
}
