import 'package:flutter/material.dart';
import '../../Resources/Url.dart';
import '../../Utils/HttpUtil.dart';
import '../../Utils/CourseParser.dart';

class ImportPresenter {
  HttpUtil httpUtil = new HttpUtil();

  Future<Image> getCaptcha() async {
    String response = await httpUtil.getWithCookie(Url.URL_NJU_HOST);
//    print(response);
    List cookies = httpUtil.getCookies();
    print(cookies);
    return Image.network('http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
        headers: {"Cookie": cookies.toString()});
  }

  login(String usr, String pwd, String captcha) async {
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
    String response = await httpUtil.post(url, {
      'userName': usr,
      'password': pwd,
      'ValidateCode': captcha,
    });
//    print(response);
//    response.then((String response) {
////      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }

  getClasses() async{
    String url = Url.URL_NJU_HOST + Url.ClassInfo;
    String response = await httpUtil.get(url);
//    print(response);
    CourseParser cp = new CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName);
    await cp.parseCourse(rst);
    print(rst);
//    Future<String> response = httpUtil.get(url);
//    response.then((String response) {
//      print(response);
//    }, onError: (e) {
//      print(e);
//    });
  }
}
