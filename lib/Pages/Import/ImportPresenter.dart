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
//    下面这行代码记得取消注释
    await httpUtil.getWithCookie(Url.URL_NJU_HOST);
    List cookies = httpUtil.getCookies();
//    print(cookies);
    print('http://cer.nju.edu.cn/amserver/verify/image.jsp?' +
        num.toString() +
        '100');
    return Image.network(
        'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp?TimeCode=' +
//        'http://cer.nju.edu.cn/amserver/verify/image.jsp?' +
          num.toString() +
          '100',
        headers: {"Cookie": cookies.toString()}
      );
  }

  Future<int> login(String usr, String pwd, String captcha) async {
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
    String response = await httpUtil.post(url, {
      'userName': usr,
      'password': pwd,
      'ValidateCode': captcha,
    });
//    print(response);
    if (response.contains('验证码错误！') || response.contains('验证码已过期，请重新登录！'))
      return Constant.CAPTCHA_ERROR;
    else if (response.contains('密码错误！')) return Constant.PASSWORD_ERROR;
    else if (response.contains('用户名错误！')) return Constant.USERNAME_ERROR;
    else return Constant.LOGIN_CORRECT;
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
    CourseParser cp = new CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    try{
      await cp.parseCourse(rst);
      return true;
    } catch(e) {
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
}
