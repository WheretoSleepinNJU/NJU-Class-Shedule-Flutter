import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../generated/l10n.dart';
import '../../Utils/CourseParserXK.dart';
import '../../Components/Toast.dart';

class ImportFromXKView extends StatefulWidget {
  final Map config;

  const ImportFromXKView({Key? key, required this.config}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WebViewState();
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

class _WebViewState extends State<ImportFromXKView> {
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
          )
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

  import(WebViewController controller, BuildContext context) async {
    Toast.showToast(S.of(context).class_parse_toast_importing, context);
    await controller.runJavascript(widget.config['preExtractJS'] ?? '');
    await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
    String response = await controller
        .runJavascriptReturningResult(widget.config['extractJS']);
    response = response.replaceAll('\\u003C', '<').replaceAll('\\"', '"');

    CourseParser cp = CourseParser(response);
    String courseTableName = cp.parseCourseName();
    int rst = await cp.addCourseTable(courseTableName, context);
    try {
      await cp.parseCourse(rst);
      UmengCommonSdk.onEvent(
          "class_import", {"type": "xk", "action": "success"});
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      UmengCommonSdk.onEvent("class_import", {"type": "xk", "action": "fail"});
      Toast.showToast(S.of(context).class_parse_error_toast, context);
    }
  }
}
