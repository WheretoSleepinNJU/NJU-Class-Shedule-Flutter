import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Components/Dialog.dart';
import '../../Components/TransBgTextButton.dart';
import '../../generated/l10n.dart';
import '../../Utils/CourseParser.dart';
import '../../Components/Toast.dart';
import '../../Resources/Url.dart';

class ImportFromCerView extends StatefulWidget {
  final Map config;

  const ImportFromCerView({Key? key, required this.config}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImportFromCerViewState();
  }
}

JavascriptChannel snackbarJavascriptChannel(BuildContext context) {
  return JavascriptChannel(
    name: 'SnackbarJSChannel',
    onMessageReceived: (JavascriptMessage message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.message),
      ));
    },
  );
}

class ImportFromCerViewState extends State<ImportFromCerView> {
  late WebViewController _webViewController;
  final CookieManager cookieManager = CookieManager();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config['page_title']),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await cookieManager.clearCookies();
              _webViewController.loadUrl(widget.config['initialUrl']);
            },
          ),

          /// 作弊器
          // IconButton(
          //   icon: const Icon(Icons.gamepad),
          //   onPressed: () async {
          //     Response response = await Dio().get(
          //         "https://clover-1254951786.cos.ap-shanghai.myqcloud.com/Projects/wheretosleepinnju/debug/testfiles/jw.html");
          //     import(_webViewController, context, res: response.data);
          //   },
          // )
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Column(children: <Widget>[
            widget.config['banner_content'] == null
                ? Container()
                : MaterialBanner(
                    forceActionsBelow: true,
                    content: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(widget.config['banner_content'],
                            style: const TextStyle(color: Colors.white))),
                    backgroundColor: Theme.of(context).primaryColor,
                    actions: [
                      TextButton(
                          style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor),
                          child: Text(widget.config['banner_action']),
                          onPressed: () => launch(widget.config['banner_url'])),
                    ],
                  ),
            Expanded(
                child: WebView(
              initialUrl: widget.config['initialUrl'],
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) async {
                _webViewController = webViewController;
                await cookieManager.clearCookies();
              },
              javascriptChannels: <JavascriptChannel>{
                snackbarJavascriptChannel(context),
              },
              onPageFinished: (url) {
                if (widget.config['redirectUrl'] != '' &&
                    url.startsWith(widget.config['redirectUrl'])) {
                  _webViewController.loadUrl(widget.config['targetUrl']);
                } else if (url.startsWith(widget.config['targetUrl'])) {
                  import(_webViewController, context);
                }
              },
            ))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context,
      {String? res}) async {
    String response = "";
    if (res != null) {
      /// 测试数据
      response = res;
    } else {
      Toast.showToast(S.of(context).class_parse_toast_importing, context);
      await controller.runJavascript(widget.config['preExtractJS'] ?? '');
      await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
      response = await controller
          .runJavascriptReturningResult(widget.config['extractJS']);
    }
    response = response.replaceAll('\\u003C', '<').replaceAll('\\"', '"');

    try {
      CourseParser cp = CourseParser(response);
      String courseTableName = cp.parseCourseName();
      int rst = await cp.addCourseTable(courseTableName, context);
      await cp.parseCourse(rst);
      UmengCommonSdk.onEvent(
          "class_import", {"type": "cer", "action": "success"});
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      String now = DateTime.now().toString();
      String errorCode = now
          .replaceAll("-", "")
          .replaceAll(":", "")
          .replaceAll(" ", "")
          .replaceAll(".", "");
      Map<String, String> info = {
        "errorCode": errorCode,
        "response": response,
        "errorMsg": e.toString(),
        "way": "cer"
      };
      try{
        await Dio()
            .post(Url.URL_BACKEND + "/log/log", data: FormData.fromMap(info));
      } catch(e) {
        print(e);
      }

      UmengCommonSdk.onEvent("class_import", {"type": "cer", "action": "fail"});
      // Toast.showToast(S.of(context).class_parse_error_toast, context);
      showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return MDialog(
              S.of(context).parse_error_dialog_title,
              Text(S.of(context).parse_error_dialog_content(errorCode)),
              overrideActions: <Widget>[
                Container(
                    alignment: Alignment.centerRight,
                    child: TransBgTextButton(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        child: Text(S.of(context).parse_error_dialog_add_group),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: errorCode));
                          if (Platform.isIOS) {
                            launch(Url.QQ_GROUP_APPLE_URL);
                          } else if (Platform.isAndroid) {
                            launch(Url.QQ_GROUP_ANDROID_URL);
                          }
                          Navigator.of(context).pop();
                        })),
                Container(
                    alignment: Alignment.centerRight,
                    child: TransBgTextButton(
                        color: Colors.grey,
                        child: Text(S.of(context).parse_error_dialog_other_ways,
                            style: const TextStyle(color: Colors.grey)),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }))
              ],
            );
          });
    }
  }
}
