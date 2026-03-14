import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
import '../../Utils/ImportRemoteDataSource.dart';

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
  final ImportRemoteDataSource _remoteDataSource =
      ImportRemoteDataSource.instance;
  bool _isImporting = false;
  String? _lastImportedUrl;

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
            _handlePageFinished(url);
          },
        ),
      );

    _webViewController.loadRequest(Uri.parse(widget.config['initialUrl']));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: color.surface,
        title: Text(widget.config['page_title']),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _restartImportSession();
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
      backgroundColor: color.surface,
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxWidth = width > 1200 ? 1100.0 : 980.0;
        final horizontalPadding = width < 560 ? 12.0 : 20.0;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 10, horizontalPadding, 12),
              child: Column(
                children: [
                  _buildInfoBanner(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: color.outlineVariant.withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: WebViewWidget(controller: _webViewController),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    if (widget.config['banner_content'] == null) {
      return const SizedBox.shrink();
    }
    final color = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: color.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.config['banner_content'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
          if ((widget.config['banner_url'] ?? '').toString().isNotEmpty)
            TextButton(
              onPressed: () =>
                  launchUrl(Uri.parse(widget.config['banner_url'])),
              child: Text(widget.config['banner_action']),
            ),
        ],
      ),
    );
  }

  Future<void> _restartImportSession() async {
    _isImporting = false;
    _lastImportedUrl = null;
    await cookieManager.clearCookies();
    await _webViewController
        .loadRequest(Uri.parse(widget.config['initialUrl']));
  }

  Future<void> _handlePageFinished(String url) async {
    if (widget.config['redirectUrl'] != '' &&
        url.startsWith(widget.config['redirectUrl'])) {
      await _webViewController
          .loadRequest(Uri.parse(widget.config['targetUrl']));
      return;
    }
    if (!url.startsWith(widget.config['targetUrl'])) {
      return;
    }
    if (_isImporting || _lastImportedUrl == url) {
      return;
    }
    _lastImportedUrl = url;
    await import(_webViewController, context);
  }

  Future<void> import(
    WebViewController controller,
    BuildContext context, {
    String? rsp,
  }) async {
    if (_isImporting) {
      return;
    }
    _isImporting = true;
    int? createdTableId;

    try {
      String response = '';
      Map<String, dynamic> adapterTiming = <String, dynamic>{};
      final CourseTableProvider courseTableProvider = CourseTableProvider();
      final CourseProvider courseProvider = CourseProvider();
      Toast.showToast(S.of(context).class_parse_toast_importing, context);

      if (rsp != null) {
        response = rsp;
      } else {
        await controller.runJavaScript(widget.config['preExtractJS'] ?? '');
        await Future.delayed(
            Duration(seconds: widget.config['delayTime'] ?? 0));

        if (_adapterEngine.shouldUseAdapter(widget.config)) {
          final adapterResult =
              await _adapterEngine.run(controller, widget.config);
          adapterTiming = Map<String, dynamic>.from(
            adapterResult['timing'] ?? <String, dynamic>{},
          );
          response = jsonEncode(<String, dynamic>{
            'name': adapterResult['name'],
            'courses': adapterResult['courses'],
          });
        } else {
          response = await _runLegacyExtract(controller);
        }
      }

      final Map<String, dynamic> courseTableMap =
          _decodeCourseTablePayload(response);
      final List<Map<String, dynamic>> coursesMap =
          CourseImportCodec.normalizeOnlineCourses(courseTableMap['courses']);
      if (coursesMap.isEmpty) {
        throw const FormatException(
            'No valid courses were parsed from import payload.');
      }

      final String tableName = CourseImportCodec.normalizeCourseTableName(
        courseTableMap['name'],
        fallback: _fallbackCourseTableName(),
      );
      final Map<String, dynamic> tableData =
          _buildCourseTableData(widget.config, adapterTiming);
      final CourseTable courseTable = await courseTableProvider.insert(
        CourseTable(
          tableName,
          data: tableData.isEmpty ? '' : jsonEncode(tableData),
        ),
      );
      createdTableId = courseTable.id!;

      final List<Course> courses = coursesMap
          .map(
            (Map<String, dynamic> courseMap) => Course.fromMap(
              CourseImportCodec.onlineCourseToDbMap(
                courseMap,
                tableId: createdTableId!,
              ),
            ),
          )
          .toList(growable: false);
      await courseProvider.insertAll(courses);
      await ScopedModel.of<MainStateModel>(context)
          .changeclassTable(createdTableId);

      UmengCommonSdk.onEvent('class_import', <String, String>{
        'type': 'be',
        'action': 'success',
      });
      if (!mounted) {
        return;
      }
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (createdTableId != null) {
        try {
          await CourseTableProvider().delete(createdTableId);
        } catch (_) {}
      }
      await _handleImportFailure(controller, e);
    } finally {
      _isImporting = false;
    }
  }

  String _fallbackCourseTableName() {
    return (widget.config['title'] ??
            widget.config['page_title'] ??
            widget.config['description'] ??
            '自动导入')
        .toString();
  }

  Map<String, dynamic> _decodeCourseTablePayload(String rawResponse) {
    dynamic current = rawResponse;
    for (int i = 0; i < 4; i++) {
      if (current is Map) {
        return Map<String, dynamic>.from(current);
      }
      if (current is! String) {
        break;
      }
      final cleaned = _cleanImportResponse(current);
      final uriDecoded = _tryDecodeUriComponent(cleaned);
      if (uriDecoded != cleaned) {
        current = uriDecoded;
        continue;
      }
      try {
        current = jsonDecode(cleaned);
      } catch (_) {
        current = cleaned;
        break;
      }
    }
    if (current is Map) {
      return Map<String, dynamic>.from(current);
    }
    throw const FormatException('Import payload is not a valid JSON object.');
  }

  String _cleanImportResponse(String raw) {
    String text = raw.trim();
    if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
      text = text.substring(1, text.length - 1);
    }
    return text
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\n', '\n')
        .replaceAll('\\u003C', '<')
        .replaceAll('\\/', '/');
  }

  String _tryDecodeUriComponent(String text) {
    if (!text.contains('%')) {
      return text;
    }
    try {
      return Uri.decodeComponent(text);
    } catch (_) {
      return text;
    }
  }

  Future<void> _handleImportFailure(
    WebViewController controller,
    Object error,
  ) async {
    String response = '';
    try {
      final result = await controller.runJavaScriptReturningResult(
        "window.document.getElementsByTagName('html')[0].outerHTML;",
      );
      response = result.toString();
    } catch (_) {}

    final String url = await controller.currentUrl() ?? '';
    final String now = DateTime.now().toString();
    final String errorCode = now
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');
    final Map<String, String> info = <String, String>{
      'errorCode': errorCode,
      'response': response,
      'errorMsg': error.toString(),
      'url': url,
      'way': 'be',
    };

    try {
      await _remoteDataSource.postImportErrorLog(info);
    } catch (_) {}

    UmengCommonSdk.onEvent('class_import', <String, String>{
      'type': 'be',
      'action': 'fail',
    });

    if (!mounted) {
      return;
    }

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
                  await Clipboard.setData(ClipboardData(text: errorCode));
                  await _launchQqGroup();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: TransBgTextButton(
                color: Colors.grey,
                child: Text(
                  S.of(context).parse_error_dialog_other_ways,
                  style: const TextStyle(color: Colors.grey),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchQqGroup() async {
    String url = Url.QQ_GROUP_ANDROID_URL;
    if (Platform.isIOS) {
      url = Url.QQ_GROUP_APPLE_URL;
    } else if (Platform.operatingSystem == 'ohos') {
      url = Url.QQ_GROUP_OHOS_URL;
    }
    await launchUrl(Uri.parse(url));
  }

  Future<String> _runLegacyExtract(WebViewController controller) async {
    String url = '';
    if (Platform.isIOS) {
      url = widget.config['extractJSfileiOS'] ?? '';
    } else if (Platform.isAndroid) {
      url = widget.config['extractJSfileAndroid'] ?? '';
    } else if (Platform.operatingSystem == 'ohos') {
      url = widget.config['extractJSfileOHOS'] ?? '';
    }
    String js = '';
    if (url.isNotEmpty) {
      js = await _remoteDataSource.fetchText(url);
    } else {
      js = (widget.config['extractJS'] ?? '').toString();
    }
    if (js.trim().isEmpty) {
      throw const FormatException('Legacy extract script is empty.');
    }
    var result = await controller.runJavaScriptReturningResult(js);
    return _cleanImportResponse(result.toString());
  }

  Map<String, dynamic> _buildCourseTableData(
      Map config, Map<String, dynamic> timing) {
    final data = <String, dynamic>{};
    dynamic classTimeList =
        timing['class_time_list'] ?? config['class_time_list'];
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
