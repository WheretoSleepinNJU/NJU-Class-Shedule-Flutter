import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;
  final Map config;

  const ImportFromBEView({Key? key, this.title, required this.config})
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                          style: TextButton.styleFrom(primary: Colors.white),
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
    try {
      CourseTableProvider courseTableProvider = CourseTableProvider();
      Toast.showToast(S.of(context).class_parse_toast_importing, context);
      await controller.runJavascript(widget.config['preExtractJS'] ?? '');
      await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
      Dio dio = Dio();
      // 他妈的，屁事真多
      String url = '';
      if(Platform.isIOS) {
        url = widget.config['extractJSfileiOS'];
      } else if(Platform.isAndroid) {
        url = widget.config['extractJSfileAndroid'];
      }
      Response rsp = await dio.get(url);
      String js = rsp.data;
      String response = await controller.runJavascriptReturningResult(js);
      response = Uri.decodeComponent(response.replaceAll('"', ''));
      Map courseTableMap = json.decode(response);
      CourseTable courseTable =
          await courseTableProvider.insert(CourseTable(courseTableMap['name']));
      int index = (courseTable.id!);
      CourseProvider courseProvider = CourseProvider();
      await ScopedModel.of<MainStateModel>(context).changeclassTable(index);
      Iterable courses;
      // 因为这里有的可能会被encode有的不会 所以做下特殊处理...
      if(courseTableMap['courses'].runtimeType != String) {
        courses = courseTableMap['courses'];
      } else if(json.decode(courseTableMap['courses']).runtimeType != String) {
        courses = json.decode(courseTableMap['courses']);
      } else {
        courses = json.decode(json.decode(courseTableMap['courses']));
      }
      List<Map<String, dynamic>> coursesMap =
          List<Map<String, dynamic>>.from(courses);
      for (var courseMap in coursesMap) {
        courseMap.remove('id');
        courseMap['tableid'] = index;
        Course course = Course.fromMap(courseMap);
        await courseProvider.insert(course);
      }
      UmengCommonSdk.onEvent(
          "class_import", {"type": "be", "action": "success"});
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      UmengCommonSdk.onEvent("class_import", {"type": "be", "action": "fail"});
      Toast.showToast(S.of(context).online_parse_error_toast, context);
      return;
    }
  }
}
