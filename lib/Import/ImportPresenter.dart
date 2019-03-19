import 'package:flutter/material.dart';
import '../Resources/Url.dart';
import '../Utils/Http.dart';

class ImportPresenter {
  HttpUtil httpUtil = new HttpUtil();

  Future<Image> getCaptcha() async {
    String response = await httpUtil.getWithCookie(Url.URL_NJU_HOST);
    List Cookies = httpUtil.getCookies();
    print(Cookies);
    return Image.network('http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
        headers: {"Cookie": Cookies.toString()});
  }

  login(String usr, String pwd, String captcha) {
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
    Future<String> response = httpUtil.post(url, {
      'userName': usr,
      'password': pwd,
      'ValidateCode': captcha,
    });
    response.then((String response) {
      print(response);
    }, onError: (e) {
      print(e);
    });
  }
}
