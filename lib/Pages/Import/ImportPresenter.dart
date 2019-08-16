import 'package:flutter/material.dart';
import '../../Resources/Url.dart';
import '../../Utils/Http.dart';

class ImportPresenter {
  HttpUtil httpUtil = new HttpUtil();

  Future<Image> getCaptcha() async {
    String response = await httpUtil.getWithCookie(Url.URL_NJU_HOST);
    print(response);
    List cookies = httpUtil.getCookies();
    print(cookies);
    return Image.network('http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
        headers: {"Cookie": cookies.toString()});
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
