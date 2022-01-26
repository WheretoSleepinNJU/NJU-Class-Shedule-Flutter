import 'dart:async';
import 'package:dio/dio.dart';

class HttpUtil {
//  List _Cookies = [];
  String _cookies = '';
  Dio? dio;

  HttpUtil() {
    dio = Dio();
    //TODO: built-in CookieJar
//    dio.interceptors.add(CookieManager(CookieJar()));
  }

  String getCookies() {
    return _cookies;
  }

  setCookies(String cookies) {
    _cookies = cookies;
  }

  Future<String> getWithCookie(String url) async {
    Response response = await _get(url);

    //TODO: WHY HERE WILL BE CALLED TWICE?
    if (response.headers['set-cookie'] != null) {
      _cookies = response.headers['set-cookie'].toString();
    }
    return response.data.toString();
  }

  Future<String> get(String url) async {
    Response response = await _get(url);
    return response.data.toString();
  }

  Future<Response> _get(String url) async {
    Response response = await dio!.get(url,
        options: Options(
          headers: {'Cookie': _cookies},
        ));
    return response;
  }

  Future<String> post(String url, Map jsonMap) async {
    Response response = await dio!.post(url,
        data: jsonMap,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Cookie': _cookies},
        ));
    return response.data.toString();
  }
}
