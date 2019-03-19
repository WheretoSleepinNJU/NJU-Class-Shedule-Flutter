import 'package:dio/dio.dart';
//import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../Resources/Url.dart';
import 'dart:typed_data';
import '../Utils/Http.dart';
import 'dart:io';
import 'dart:convert';

class ImportPresenter {
  HttpUtil httpUtil = new HttpUtil();
//  HttpUtil httpUtil = new HttpUtil(Url.URL_NJU_HOST);

////  Future<Uint8List> getCaptcha(){
  Future<Image> getCaptcha() async{
    HttpClientResponse response = await httpUtil.get(Url.URL_NJU_HOST, {});
    List Cookies = httpUtil.getCookies();
    print(Cookies);
    return Image.network(
      'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
        headers: {"Cookie": Cookies.toString()}
//      headers: {"Set-Cookie": Cookies[1]},
    );
//    return http.getImage('http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp');
//    Uint8List qwq = await httpUtil.getImage('http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp');
//    return Image.memory(qwq);
  }

  login(String usr, String pwd, String captcha){
    String url = Url.URL_NJU_HOST + Url.LoginUrl;
//    Dio dio = new Dio();
//    Future<Response> response = httpUtil.post(url, {
////    Future<Response> response = Requests.post(url, body: {
//      'userName': usr,
//      'password': pwd,
//      'ValidateCode': captcha,
//    });
//    response.then((Response response) {
//      var data = response.data.toString();
//      print(data);
//    }, onError: (e) {
//      print(e);
//    });
    Future<String> response = httpUtil.post(url, {
//    Future<Response> response = Requests.post(url, body: {
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