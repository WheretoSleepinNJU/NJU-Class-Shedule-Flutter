import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../Resources/Url.dart';
import 'dart:async';
import '../../generated/l10n.dart';
import '../../Resources/Url.dart';
import '../../Utils/HttpUtil.dart';
import '../../Resources/Constant.dart';
import '../../Utils/CourseParserXK.dart';
import '../../Components/Toast.dart';

class ImportFromXKView extends StatefulWidget {
  final String? title;

  ImportFromXKView({Key? key, this.title}) : super(key: key);

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

class _WebViewState extends State<ImportFromXKView> {
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
          return Column(children: <Widget>[
            MaterialBanner(
              forceActionsBelow: true,
              content: Text(S.of(context).import_banner,
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Theme.of(context).primaryColor,
              actions: [
                TextButton(
                    child: Text(S.of(context).import_banner_action,
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => launch(Url.URL_NJU_VPN)),
              ],
            ),
            Expanded(
                child: WebView(
              initialUrl:
                  'https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/index.do',
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
                if (url.startsWith(
                    "https://xk.nju.edu.cn/xsxkapp/sys/xsxkapp/*default/grablessons.do")) {
                  import(_webViewController, context);
                  print('Login success!');
                }
              },
            ))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context) async {
    // final String cookies =
    //     await controller.evaluateJavascript('document.cookie');
    Toast.showToast(S.of(context).class_parse_toast_importing, context);
    await controller.evaluateJavascript(
        'document.getElementsByClassName("yxkc-window-btn")[0].click()');
    await Future.delayed(Duration(seconds: 3));
    String response =
        await controller.evaluateJavascript('document.body.innerHTML');

    // response = response.replaceAll('\\u003C', '<');
    // response = response.replaceAll('\\\"', '\"');
    // HttpUtil httpUtil = new HttpUtil();
    // httpUtil.setCookies(cookies);
    // String url = Url.URL_NJU_HOST + '/login.do';
    // String response = await httpUtil.get(url);
    // String url = Url.URL_NJU_HOST + Url.ClassInfo;
    // String response = await httpUtil.get(url);
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
