import 'package:flutter/material.dart';
import '../../Resources/Url.dart';
import '../../Utils/HttpUtil.dart';
import '../../Resources/Constant.dart';
import '../../Utils/CourseParser.dart';

class ImportPresenter {
  HttpUtil httpUtil = new HttpUtil();

  Future<Image> getCaptcha(double num) async {
//    String response = await httpUtil.getWithCookie(Url.URL_NJU_HOST);
//    print(response);
    await httpUtil.getWithCookie(Url.URL_NJU_HOST);
    List cookies = httpUtil.getCookies();
    print(cookies);
    return Image.network(
        'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp?TimeCode=' +
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
    print(response);
    if (response.contains('验证码错误！'))
      return Constant.CAPTCHA_ERROR;
    else if (response.contains('密码错误！')) return Constant.PASSWORD_ERROR;
    else return Constant.LOGIN_CORRECT;
//    response.then((String response) {
////      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }

  getClasses(BuildContext context) async {
    String url = Url.URL_NJU_HOST + Url.ClassInfo;
    String response = await httpUtil.get(url);
//    print(response);
    CourseParser cp = new CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    await cp.parseCourse(rst);
//    print(rst);
//    Future<String> response = httpUtil.get(url);
//    response.then((String response) {
//      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }
}
