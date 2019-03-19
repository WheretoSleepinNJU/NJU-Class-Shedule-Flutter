import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'SessionHelper.dart';

//import 'package:http/http.dart' as http;
//import 'package:sky_engine/_http/http.dart' as http;

class HttpUtil {

  List _Cookies = [];
//  Map _Headers = {};

  List getCookies(){
    return _Cookies;
  }
  Future<HttpClientResponse> get(String url, Map jsonMap) async {
//    String session = await new SessionHelper().getSession();
//    print(session);
//    HttpClient httpClient = new HttpClient();
//    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
//    request.headers.set('content-type', 'application/json');
//    if (null != session) {
//      String qwq = session.toString();
//      request.headers.add('Cookie', 'JSESSIONID=' + session.toString());
//    }
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    request.headers.set('content-type', 'application/json');
    request.headers.add('Cookie', _Cookies.toString());
    HttpClientResponse response = await request.close();
    if(response.cookies.length != 0) {
      _Cookies = response.cookies;
    }
//    _Headers = response.headers.forEach(k, v) => _Headers.add(k,v);
    httpClient.close();
    return response;
//    return reply;
  }

  Future<String> post(String url, Map jsonMap) async {
//    String session = await new SessionHelper().getSession();
//    print(session);
//    HttpClient httpClient = new HttpClient();
//    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
//    request.headers.set('content-type', 'application/json');
//    if (null != session) {
//      String qwq = session.toString();
//      request.headers.add('Cookie', 'JSESSIONID=' + session.toString());
//    }

//    HttpClient httpClient = new HttpClient();
//    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
//    request.headers.set('content-type', 'application/x-www-form-urlencoded');
//    request.headers.add('Cookie', _Cookies.toString());
//    String params = '';
//    jsonMap.forEach((k,v) => params += k + '=' + v + '&');
//    params = params.substring(0, params.length - 1);
//    request.write(params);
////    request.write(Uri.encodeQueryComponent(json.encode(jsonMap)));
//    HttpClientResponse response = await request.close();
//    if(response.cookies.length != 0){
//      _Cookies = response.cookies;
//    }
//    httpClient.close();
//    return response;

    Dio dio = new Dio();
    Response response = await dio.post(url,
      data: jsonMap,
      options: Options(
        contentType: ContentType.parse("application/x-www-form-urlencoded"),
        headers: {
          'Cookie': _Cookies.toString()
        },
      )
    );
    return response.data.toString();

//    HttpClient httpClient = new HttpClient();
//    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
//    request.headers.set('content-type', 'application/json');
//    request.headers.add('Cookie', _Cookies.toString());
//    request.write(json.encode(jsonMap));
//    HttpClientResponse response = await request.close();
//    if(response.cookies.length != 0){
//      _Cookies = response.cookies;
//    }

    // todo - you should check the response.statusCode
//    String reply = await response.transform(utf8.decoder).join();
//    String header = response.headers.toString();
//    Map<String, dynamic> resultMap = json.decode(reply);
//    if (null != resultMap) {
//      if (0 == resultMap['ret'] || "success" == resultMap['msg']) {
//        var jsessionId = resultMap['jsessionId'];
//        print(jsessionId);
//        if (jsessionId.length > 0) {
//          new SessionHelper().setSession(jsessionId);
//        }
//      } else {}
//    }

//    return reply;
  }
}

//class HttpUtil{
//
//  HttpUtil(String url){
//  }
//
//  Future<Response> get(String url){
//    return http.get(url);
//  }
//
//  Future<Response> post(String url, var data){
//    return http.post(url, body: data);
//  }
//}

//class HttpUtil{
//  Dio dio;
//  CookieJar cookiejar;
//  List<Cookie> cookies;
////  HttpUtil(){
////    dio = new Dio();
////    dio.interceptors.add(CookieManager(CookieJar()));
////  }
//
//  HttpUtil(String url){
//    dio = new Dio();
//    cookiejar = new CookieJar();
////    dio.interceptors.add(CookieManager(cookiejar));
//    dio.interceptors.add(CookieManager(CookieJar()));
//    dio.head(url);
////    cookies = cookiejar.loadForRequest(Uri.parse(url));
//  }
//
//  Future<Response> get(String url){
//    return dio.get(url);
//  }
//
//  Future<Response> post(String url, var data){
//    return dio.post(url, data: data);
//  }
//
////  Future<Image> getImage(String url) async{
//  Future<Uint8List> getImage(String url) async{
//    Response response = await dio.get(url);
//    var qwq = response.data;
//
//    List<int> list = qwq.codeUnits;
//    var encoded = base64.encode(list);
//    Uint8List qaq = Uint8List.fromList(list);
//    return qaq;
////    return Image.memory(qaq);
//  }
//
////  List<Cookie> getCookie (){
////    return cookies;
////  }
//
//}

//class Session {
//  Map<String, String> headers = {};
//
//  Future<Map> get(String url) async {
//    http.Response response = await http.get(url, headers: headers);
//    updateCookie(response);
//    return json.decode(response.body);
//  }
//
//  Future<Map> post(String url, dynamic data) async {
//    http.Response response = await http.post(url, body: data, headers: headers);
//    updateCookie(response);
//    return json.decode(response.body);
//  }
//
//  void updateCookie(http.Response response) {
//    String rawCookie = response.headers['set-cookie'];
//    if (rawCookie != null) {
//      int index = rawCookie.indexOf(';');
//      headers['cookie'] =
//      (index == -1) ? rawCookie : rawCookie.substring(0, index);
//    }
//  }
//}
