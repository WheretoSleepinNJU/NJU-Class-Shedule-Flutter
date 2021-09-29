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

class ImportFromWebView extends StatefulWidget {
  final String? title;

  ImportFromWebView({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WebViewState();
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

class _WebViewState extends State<ImportFromWebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _webViewController;
  final CookieManager cookieManager = CookieManager();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('统一认证登录'),
        actions: <Widget>[ManualMenu(_controller.future)],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl:
                'https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _webViewController = webViewController;
              _controller.complete(webViewController);
              await cookieManager.clearCookies();
            },
            javascriptChannels: <JavascriptChannel>[
              snackbarJavascriptChannel(context),
            ].toSet(),
            onPageFinished: (url) {
              if (url.startsWith("http://elite.nju.edu.cn/jiaowu/login.do")) {
                _webViewController.loadUrl(
                    'http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse');
              } else if (url.startsWith(
                  "http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse")) {
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
    String response =
        await controller.evaluateJavascript('document.body.innerHTML');

    response = response.replaceAll('\\u003C', '<');
    response = response.replaceAll('\\\"', '\"');
//    HttpUtil httpUtil = new HttpUtil();
//    httpUtil.setCookies(cookies);
//    String url = Url.URL_NJU_HOST + '/login.do';
//    String response = await httpUtil.get(url);
//    String url = Url.URL_NJU_HOST + Url.ClassInfo;
//    String response = await httpUtil.get(url);
    CourseParser cp = new CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    try {
      await cp.parseCourse(rst);
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.showToast(S.of(context).class_parse_error_toast, context);
    }
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
            listCookies(controller.data!, context);
          },
        );
      },
    );
  }

  listCookies(WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.evaluateJavascript('document.cookie');
    String response =
        await controller.evaluateJavascript('document.body.innerHTML');

    response = response.replaceAll('\\u003C', '<');
    response = response.replaceAll('\\\"', '\"');
    CourseParser cp = new CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    try {
      await cp.parseCourse(rst);
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.showToast(S.of(context).class_parse_error_toast, context);
    }
  }
}
