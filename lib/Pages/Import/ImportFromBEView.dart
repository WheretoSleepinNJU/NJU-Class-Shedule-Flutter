import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
import '../../Utils/ImportAdapterEngine.dart';

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

class ImportFromBEViewState extends State<ImportFromBEView> {
  late final WebViewController _webViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();
  final ImportAdapterEngine _adapterEngine = ImportAdapterEngine();

  @override
  void initState() {
    super.initState();
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
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
              _webViewController.loadRequest(Uri.parse(widget.config['targetUrl']));
            } else if (url.startsWith(widget.config['targetUrl'])) {
              import(_webViewController, context);
            }
          },
        ),
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
            Expanded(
                child: WebViewWidget(controller: _webViewController))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context, {String? rsp}) async {
    try {
      String response = "";
      Map<String, dynamic> adapterTiming = <String, dynamic>{};
      CourseTableProvider courseTableProvider = CourseTableProvider();
      Toast.showToast(S.of(context).class_parse_toast_importing, context);

      if (rsp != null) {
        response = rsp;
      } else {
        await controller.runJavaScript(widget.config['preExtractJS'] ?? '');
        await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));

        if (_adapterEngine.shouldUseAdapter(widget.config)) {
          final adapterResult = await _adapterEngine.run(controller, widget.config);
          adapterTiming =
              Map<String, dynamic>.from(adapterResult['timing'] ?? <String, dynamic>{});
          response = Uri.encodeComponent(jsonEncode(<String, dynamic>{
            'name': adapterResult['name'],
            'courses': adapterResult['courses'],
          }));
        } else {
          response = await _runLegacyExtract(controller);
        }
      }

      response = Uri.decodeComponent(response.replaceAll('"', ''));
      Map courseTableMap = json.decode(response);

      final tableData = _buildCourseTableData(widget.config, adapterTiming);

      CourseTable courseTable;
      if (tableData.isEmpty) {
        courseTable = await courseTableProvider
            .insert(CourseTable(courseTableMap['name']));
      } else {
        try {
          String dataString = json.encode(tableData);
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
        final dbMap = CourseImportCodec.onlineCourseToDbMap(courseMap, tableId: index);
        Course course = Course.fromMap(dbMap);
        await courseProvider.insert(course);
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

  Future<String> _runLegacyExtract(WebViewController controller) async {
    Dio dio = Dio();
    String url = '';
    if (Platform.isIOS) {
      url = widget.config['extractJSfileiOS'] ?? '';
    } else if (Platform.isAndroid) {
      url = widget.config['extractJSfileAndroid'] ?? '';
    } else if (Platform.operatingSystem == 'ohos') {
      url = widget.config['extractJSfileOHOS'] ?? '';
    }
    Response serverRsp = await dio.get(url);
    String js = serverRsp.data;
    var result = await controller.runJavaScriptReturningResult(js);
    String response = result.toString();
    if (response.startsWith('"') && response.endsWith('"')) {
      response = response.substring(1, response.length - 1);
    }
    return response;
  }

  Map<String, dynamic> _buildCourseTableData(Map config, Map<String, dynamic> timing) {
    final data = <String, dynamic>{};
    dynamic classTimeList = timing['class_time_list'] ?? config['class_time_list'];
    if (classTimeList == null && timing['sectionTimes'] is List) {
      classTimeList = _convertSectionTimes(timing['sectionTimes'] as List);
    }
    final semesterStart = timing['semester_start_monday'] ??
        timing['semesterStart'] ??
        config['semester_start_monday'];
    if (classTimeList != null) {
      data['class_time_list'] = classTimeList;
    }
    if (semesterStart != null) {
      data['semester_start_monday'] = semesterStart;
    }
    return data;
  }

  List<Map<String, dynamic>> _convertSectionTimes(List sectionTimes) {
    final List<Map<String, dynamic>> rst = [];
    for (final row in sectionTimes) {
      if (row is! Map) continue;
      final start = row['startTime']?.toString() ?? row['start']?.toString();
      final end = row['endTime']?.toString() ?? row['end']?.toString();
      if (start == null || end == null || start.isEmpty || end.isEmpty) {
        continue;
      }
      rst.add(<String, dynamic>{'start': start, 'end': end});
    }
    return rst;
  }
}
