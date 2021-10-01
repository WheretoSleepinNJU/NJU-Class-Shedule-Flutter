import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import 'dart:async';
import '../../generated/l10n.dart';
import '../../Resources/Url.dart';
import '../../Utils/HttpUtil.dart';
import '../../Resources/Constant.dart';
import '../../Utils/CourseParser.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;

  ImportFromBEView({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImportFromBEViewState();
  }
}

JavascriptChannel snackbarJavascriptChannel(BuildContext context) {
  return JavascriptChannel(
    name: 'SnackbarJSChannel',
    onMessageReceived: (JavascriptMessage message) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(message.message),
      ));
    },
  );
}

class ImportFromBEViewState extends State<ImportFromBEView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _webViewController;
  final CookieManager cookieManager = CookieManager();

  static const Map config = {
    "title": "统一认证登录",
    "initialUrl":
        "https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp",
    "redirectUrl": "http://elite.nju.edu.cn/jiaowu/login.do",
    "targetUrl":
        "http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse",
    "extractJS": '''
function scheduleHtmlParser(){let WEEK_WITH_BIAS=["","周一","周二","周三","周四","周五","周六","周日"];let name=document.querySelector("body > div:nth-child(10) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1)").textContent;let rst={'name':name,'courses':[]};let table_1=document.getElementsByClassName("TABLE_TR_01");let table_2=document.getElementsByClassName("TABLE_TR_02");let table=table_1.concat(table_2);table.forEach(e=>{let state=e.children[6].innerText;if(state.includes('已退选'))return;let course_name=e.children[1].innerText;let class_number=e.children[0].innerText;let teacher=e.children[3].innerText;let test_time=e.children[8].innerText;let test_location=e.children[9].innerText;let course_info=e.children[10].innerText;let info_str=e.children[4].innerText;let info_list=info_str.split('\\n');info_list.forEach(i=>{let week_time=0;let strs=i.split(' ');let start_time=0;let time_count=0;let weeks=[];for(let z=0;z<WEEK_WITH_BIAS.length;z++){if(WEEK_WITH_BIAS[z]==strs[0])week_time=z}let pattern1=new RegExp('第(\\\\d{1,2})-(\\\\d{1,2})节','i');strs.forEach(w=>{let r=pattern1.exec(w);if(r){start_time=parseInt(r[1]);time_count=parseInt(r[2])-parseInt(r[1])}});let pattern2=new RegExp('(\\\\d{1,2})-(\\\\d{1,2})周','i');strs.forEach(x=>{let s=pattern2.exec(x);if(s){if(strs.includes('单周')){for(let z=parseInt(s[1]);z<=parseInt(s[2]);z+=2)weeks.push(z)}else if(strs.includes('双周')){for(let z=parseInt(s[1]);z<=parseInt(s[2]);z+=2)weeks.push(z)}else{for(let z=parseInt(s[1]);z<=parseInt(s[2]);z++)weeks.push(z)}}});let pattern3=new RegExp('第(\\\\d{1,2})周','i');strs.forEach(y=>{let t=pattern3.exec(y);if(t){weeks.push(parseInt(t[1]))}});rst['courses'].push({"name":course_name,"classroom":"仙Ⅰ-109","class_number":class_number,"teacher":teacher,"test_time":test_time,"test_location":test_location,"link":null,"weeks":weeks,"week_time":week_time,"start_time":start_time,"time_count":time_count,"import_type":1,"info":course_info,"data":null})})});return JSON.stringify(rst)}scheduleHtmlParser();
    '''
  };

  // static const Map config = {
  //   "title": "统一认证登录",
  //   "initialUrl": "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/index.do",
  //   "redirectUrl": "",
  //   "targetUrl": "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/grablessons.do",
  //   "preExtractJS": "document.getElementsByClassName('yxkc-window-btn')[0].click()",
  //   "delayTime": 3,
  //   "extractJS": "document.body.innerHTML"
  // };

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(config['title']),
        actions: <Widget>[ManualMenu(_controller.future)],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl: config['initialUrl'],
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _webViewController = webViewController;
              _controller.complete(webViewController);
              // await cookieManager.clearCookies();
            },
            javascriptChannels: <JavascriptChannel>[
              snackbarJavascriptChannel(context),
            ].toSet(),
            onPageFinished: (url) {
              if (config['redirectUrl'] != '' &&
                  url.startsWith(config['redirectUrl'])) {
                _webViewController.loadUrl(config['targetUrl']);
              } else if (url.startsWith(config['targetUrl'])) {
                import(_webViewController, context);
                print('Login success!');
              }
            },
          );
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context) async {
    // final String cookies =
    //     await controller.evaluateJavascript('document.cookie');
    Toast.showToast(S.of(context).class_parse_toast_importing, context);
    await controller.evaluateJavascript(config['preExtractJS'] ?? '');
    await Future.delayed(Duration(seconds: config['delayTime'] ?? 0));
    String response = await controller.evaluateJavascript(config['extractJS']);
    print(response);
    Map courseTableMap = json.decode(response);
    CourseTableProvider courseTableProvider = new CourseTableProvider();
    int index;

    try {
      CourseTable courseTable = await courseTableProvider
          .insert(new CourseTable(courseTableMap['name']));
      index = (courseTable.id!);
    } catch (e) {
      Toast.showToast(S.of(context).qrcode_name_error_toast, context);
      return;
    }
    CourseProvider courseProvider = new CourseProvider();
    await ScopedModel.of<MainStateModel>(context).changeclassTable(index);

    Iterable courses = json.decode(courseTableMap['courses']);
    List<Map<String, dynamic>> coursesMap =
        new List<Map<String, dynamic>>.from(courses);
    try {
      coursesMap.forEach((courseMap) {
        courseMap.remove('id');
        courseMap['tableid'] = index;
        Course course = new Course.fromMap(courseMap);
        courseProvider.insert(course);
      });
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.showToast(S.of(context).qrcode_read_error_toast, context);
      return;
    }

//     response = response.replaceAll('\\u003C', '<');
//     response = response.replaceAll('\\\"', '\"');
// //    HttpUtil httpUtil = new HttpUtil();
// //    httpUtil.setCookies(cookies);
// //    String url = Url.URL_NJU_HOST + '/login.do';
// //    String response = await httpUtil.get(url);
// //    String url = Url.URL_NJU_HOST + Url.ClassInfo;
// //    String response = await httpUtil.get(url);
//     CourseParser cp = new CourseParser(response);
//     String courseTableName = cp.parseCourseName();
//     int rst = await cp.addCourseTable(courseTableName, context);
//     try {
//       await cp.parseCourse(rst);
//       Toast.showToast(S.of(context).class_parse_toast_success, context);
//       Navigator.of(context).pop(true);
//     } catch (e) {
//       Toast.showToast(S.of(context).class_parse_error_toast, context);
//     }
  }
}

class ManualMenu extends StatelessWidget {
  ManualMenu(this.controller);

  final Future<WebViewController> controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            // listCookies(controller.data!, context);
          },
        );
      },
    );
  }

// listCookies(WebViewController controller, BuildContext context) async {
//   final String cookies =
//       await controller.evaluateJavascript('document.cookie');
//   String response =
//       await controller.evaluateJavascript('document.body.innerHTML');
//
//   response = response.replaceAll('\\u003C', '<');
//   response = response.replaceAll('\\\"', '\"');
//   CourseParser cp = new CourseParser(response);
//   String courseTableName = cp.parseCourseName();
//   int rst = await cp.addCourseTable(courseTableName, context);
//   try {
//     await cp.parseCourse(rst);
//     Toast.showToast(S.of(context).class_parse_toast_success, context);
//     Navigator.of(context).pop(true);
//   } catch (e) {
//     Toast.showToast(S.of(context).class_parse_error_toast, context);
//   }
// }
}
