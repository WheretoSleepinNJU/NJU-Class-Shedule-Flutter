import 'dart:io';
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

  // static const Map config = {
  //   "title": "统一认证登录",
  //   "initialUrl": "https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp",
  //   "redirectUrl": "http://elite.nju.edu.cn/jiaowu/login.do",
  //   "targetUrl": "http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse",
  //   "extractJS": "document.body.innerHTML"
  // };

  static const Map config = {
    "title": "统一认证登录",
    "initialUrl": "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/index.do",
    "redirectUrl": "",
    "targetUrl": "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/grablessons.do",
    "preExtractJS": "document.getElementsByClassName('yxkc-window-btn')[0].click()",
    "delayTime": 3,
    "extractJS": "document.body.innerHTML"
  };
  
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
              if (config['redirectUrl'] != '' && url.startsWith(config['redirectUrl'])) {
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
    await controller.evaluateJavascript(config['preExtractJS']);
    await Future.delayed(Duration(seconds: config['delayTime']));
    String response =
        await controller.evaluateJavascript(config['extractJS']);

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
