import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Components/Dialog.dart';
import '../../Components/TransBgTextButton.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/Url.dart';
import '../../Utils/CourseImportCodec.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;
  final Map config;

  const ImportFromBEView({Key? key, this.title, required this.config})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImportFromBEViewState();
  }

  /// 只负责"跑 WebView 抓取 -> 拉取远程 extractJS -> 执行 -> JSON decode"，
  /// 不做任何数据库写入，供导入流程和"检查更新"流程共用。
  static Future<Map> fetchCourseTableMap(
      WebViewController controller, Map config,
      {String? rsp}) async {
    String response = "";
    if (rsp == null) {
      await controller.runJavaScript(config['preExtractJS'] ?? '');
      await Future.delayed(Duration(seconds: config['delayTime'] ?? 0));
      Dio dio = Dio();

      String url = '';
      if (Platform.isIOS) {
        url = config['extractJSfileiOS'] ?? "";
      } else if (Platform.isAndroid) {
        url = config['extractJSfileAndroid'] ?? "";
      } else if (Platform.operatingSystem == 'ohos') {
        url = config['extractJSfileOHOS'] ?? "";
      }

      Response serverRsp = await dio.get(url);
      String js = serverRsp.data;
      var result = await controller.runJavaScriptReturningResult(js);
      response = result.toString();

      if (response.startsWith('"') && response.endsWith('"')) {
        response = response.substring(1, response.length - 1);
      }
    } else {
      response = rsp;
    }

    final rawResponse = response;
    response = Uri.decodeComponent(response.replaceAll('"', ''));
    final decoded = json.decode(response);
    if (decoded is! Map) {
      final currentUrl = await controller.currentUrl();
      // njubksjw2.js 内部大概率抛了异常（Android WebView 的已知坑：JS 抛错时
      // runJavaScriptReturningResult 不会把异常带给 Dart，只会静默返回 "null"），
      // 单独查一下页面上关键元素在不在，帮助判断脚本具体是在哪一步失败的。
      String domDiagnostic = '（诊断脚本执行失败）';
      try {
        final diagJs = '''
          (function(){
            var nameEl = document.querySelector("#dqxnxqkclb");
            var tableBody = document.querySelector("table tbody");
            var anyTable = document.querySelector("table");
            return JSON.stringify({
              hasNameEl: !!nameEl,
              nameElText: nameEl ? nameEl.textContent : null,
              hasTableTbody: !!tableBody,
              hasAnyTable: !!anyTable,
              rowCount: tableBody ? tableBody.querySelectorAll("tr").length : 0,
              bodyTextSnippet: document.body ? document.body.innerText.substring(0, 300) : null
            });
          })();
        ''';
        final diagResult = await controller.runJavaScriptReturningResult(diagJs);
        domDiagnostic = diagResult.toString();
      } catch (e) {
        domDiagnostic = '诊断脚本本身出错：$e';
      }
      throw Exception(
        '课表抓取脚本没有返回预期的数据（很可能是脚本内部报错，被 WebView 吞掉了）。\n\n'
        '[调试] 抓取脚本执行时所在的网址：$currentUrl\n'
        '[调试] 页面关键元素诊断：\n$domDiagnostic\n\n'
        '[调试] 抓取脚本原始返回内容（JSON 解析前，前 1000 字）：\n'
        '${rawResponse.substring(0, rawResponse.length > 1000 ? 1000 : rawResponse.length)}',
      );
    }
    return decoded;
  }
}

class ImportFromBEViewState extends State<ImportFromBEView> {
  late final WebViewController _webViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..addJavaScriptChannel(
        'SnackbarJSChannel',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message.message),
          ));
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (widget.config['redirectUrl'] != '' &&
                url.startsWith(widget.config['redirectUrl'])) {
              _webViewController
                  .loadRequest(Uri.parse(widget.config['targetUrl']));
            } else if (url.startsWith(widget.config['targetUrl'])) {
              import(_webViewController, context);
            }
          },
        ),
      );

    // 启用第三方 Cookie 支持
    _enableThirdPartyCookies();
  }

  Future<void> _enableThirdPartyCookies() async {
    if (Platform.isAndroid) {
      final AndroidWebViewController androidController =
          _webViewController.platform as AndroidWebViewController;
      final AndroidWebViewCookieManager androidCookieManager =
          cookieManager.platform as AndroidWebViewCookieManager;
      await androidCookieManager.setAcceptThirdPartyCookies(
          androidController, true);
    }
    // 等待第三方 cookie 设置完成后再加载页面
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
              _webViewController
                  .loadRequest(Uri.parse(widget.config['initialUrl']));
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.gamepad),
          //   onPressed: () async {
          //     String rsp = "";
          //     import(_webViewController, context, rsp: rsp);
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
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor),
                          child: Text(widget.config['banner_action']),
                          onPressed: () => launch(widget.config['banner_url'])),
                    ],
                  ),
            Expanded(child: WebViewWidget(controller: _webViewController))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context,
      {String? rsp}) async {
    try {
      CourseTableProvider courseTableProvider = CourseTableProvider();
      Toast.showToast(S.of(context).class_parse_toast_importing, context);

      Map courseTableMap = await ImportFromBEView.fetchCourseTableMap(
          controller, widget.config,
          rsp: rsp);

      CourseTable courseTable;
      if (widget.config['class_time_list'] == null &&
          widget.config['semester_start_monday'] == null) {
        courseTable = await courseTableProvider
            .insert(CourseTable(courseTableMap['name']));
      } else {
        try {
          Map data = {};
          if (widget.config['class_time_list'] != null) {
            data["class_time_list"] = widget.config['class_time_list'];
          }
          if (widget.config['semester_start_monday'] != null) {
            data["semester_start_monday"] =
                widget.config['semester_start_monday'];
          }
          String dataString = json.encode(data);
          courseTable = await courseTableProvider
              .insert(CourseTable(courseTableMap['name'], data: dataString));
        } catch (e) {
          courseTable = await courseTableProvider
              .insert(CourseTable(courseTableMap['name']));
        }
      }
      int index = (courseTable.id!);
      CourseProvider courseProvider = CourseProvider();
      await ScopedModel.of<MainStateModel>(context).changeclassTable(index);
      Iterable courses;
      if (courseTableMap['courses'].runtimeType != String) {
        courses = courseTableMap['courses'];
      } else if (json.decode(courseTableMap['courses']).runtimeType != String) {
        courses = json.decode(courseTableMap['courses']);
      } else {
        courses = json.decode(json.decode(courseTableMap['courses']));
      }
      List<Map<String, dynamic>> coursesMap =
          List<Map<String, dynamic>>.from(courses);
      for (var courseMap in coursesMap) {
        final dbMap =
            CourseImportCodec.onlineCourseToDbMap(courseMap, tableId: index);
        Course course = Course.fromMap(dbMap);
        await courseProvider.insert(course);
      }
      // 记录这张表来自哪个学校配置、以及本次抓取的原始课程数据，
      // 供后续"检查更新"功能做 diff 用。
      final pinyin = widget.config['pinyin'];
      if (pinyin != null) {
        await courseTableProvider.updateCheckUpdateInfo(
          index,
          sourceSchoolPinyin: pinyin.toString(),
          lastSnapshot: json.encode(coursesMap),
          lastCheckedAt: DateTime.now().toIso8601String(),
        );
      }
      UmengCommonSdk.onEvent(
          "class_import", {"type": "be", "action": "success"});
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      var result = await controller.runJavaScriptReturningResult(
          "window.document.getElementsByTagName('html')[0].outerHTML;");
      String response = result.toString();
      String url = await controller.currentUrl() ?? "";

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
        "url": url,
        "way": "be"
      };

      try {
        await Dio()
            .post(Url.URL_BACKEND + "/log/log", data: FormData.fromMap(info));
      } catch (_) {}

      UmengCommonSdk.onEvent("class_import", {"type": "be", "action": "fail"});

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
                          } else if (Platform.operatingSystem == 'ohos') {
                            launch(Url.QQ_GROUP_OHOS_URL);
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
      return;
    }
  }
}
