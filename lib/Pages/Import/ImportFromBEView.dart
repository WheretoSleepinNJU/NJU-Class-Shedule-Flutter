import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import 'dart:async';
import '../../generated/l10n.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;
  final Map config;

  ImportFromBEView({Key? key, this.title, required this.config})
      : super(key: key);

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
        title: new Text(widget.config['page_title']),
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
                    content: Text(widget.config['banner_content'],
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Theme.of(context).primaryColor,
                    actions: [
                      TextButton(
                          child: Text(widget.config['banner_action'],
                              style: TextStyle(color: Colors.white)),
                          onPressed: () => launch(widget.config['banner_url'])),
                    ],
                  ),
            Expanded(
                child: WebView(
              initialUrl: widget.config['initialUrl'],
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) async {
                _webViewController = webViewController;
              },
              javascriptChannels: <JavascriptChannel>[
                snackbarJavascriptChannel(context),
              ].toSet(),
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
    await controller.evaluateJavascript(widget.config['preExtractJS'] ?? '');
    await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
    String response =
        await controller.evaluateJavascript(widget.config['extractJS']);

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
  }
}
