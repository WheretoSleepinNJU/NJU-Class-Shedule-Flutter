import 'package:dio/dio.dart';
import '../Resources/Url.dart';

class ImportPresenter {
  login(String usr, String pwd, String captcha){
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
    Dio dio = new Dio();
    Future<Response> response = dio.post(url, data: {
      'userName': usr,
      'password': pwd,
      'ValidateCode': captcha,
    });
    response.then((Response response) {
      var data = response.data.toString();
      print(data);
    }, onError: (e) {
      print(e);
    });
  }
}