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

class ImportFromCerViewState extends State<ImportFromCerView> {
  late final WebViewController _webViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (widget.config['redirectUrl'] != '' &&
                url.startsWith(widget.config['redirectUrl'])) {
              _webViewController.loadRequest(Uri.parse(widget.config['targetUrl']));
            } else if (url.startsWith(widget.config['targetUrl'])) {
              import(_webViewController, context);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'SnackbarJSChannel',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message.message),
          ));
        },
      );

    _webViewController.loadRequest(Uri.parse(widget.config['initialUrl']));
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
              _webViewController.loadRequest(Uri.parse(widget.config['initialUrl']));
            },
          ),
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
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor),
                          child: Text(widget.config['banner_action']),
                          onPressed: () => launch(widget.config['banner_url'])),
                    ],
                  ),
            Expanded(
                child: WebViewWidget(controller: _webViewController))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context,
      {String? res}) async {
    String response = "";
    if (res != null) {
      response = res;
    } else {
      Toast.showToast(S.of(context).class_parse_toast_importing, context);
      await controller.runJavaScript(widget.config['preExtractJS'] ?? '');
      await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
      
      var result = await controller
          .runJavaScriptReturningResult(widget.config['extractJS']);
      response = result.toString();
      
      if (response.startsWith('"') && response.endsWith('"')) {
         response = response.substring(1, response.length - 1);
      }
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
      try {
        await Dio()
            .post(Url.URL_BACKEND + "/log/log", data: FormData.fromMap(info));
      } catch (e) {
        print(e);
      }

      UmengCommonSdk.onEvent("class_import", {"type": "cer", "action": "fail"});
      
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