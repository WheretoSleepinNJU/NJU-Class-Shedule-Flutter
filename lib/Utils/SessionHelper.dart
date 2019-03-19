import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


class DataUtils {
  static final String SP_SESSION = "SESSION";
  static Future<String> getAccessToken() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString(SP_SESSION);
  }
  static Future<bool> setAccessToken(String session) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return await sp.setString(SP_SESSION, session);
  }
}

class SessionHelper {
  static final SessionHelper _singleton = new SessionHelper._internal();
  factory SessionHelper() {
    return _singleton;
  }
  SessionHelper._internal();
  String session;
  void setSession(String session){
    print(session);
    if (session != this.session){
      this.session = session ;
      var result = DataUtils.setAccessToken(session);
      print("setSession");
      print(result);
    }
  }
  Future<String> getSession() async{
    if (null == this.session){
      String jsession = await DataUtils.getAccessToken();
      print("getSession");
      print(jsession);
      this.session = jsession;
    }
    return session;
  }
}