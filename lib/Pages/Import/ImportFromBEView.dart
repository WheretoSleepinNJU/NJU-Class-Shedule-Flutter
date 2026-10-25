import 'dart:io';
import 'dart:async';
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
import '../../Resources/Url.dart';
import '../../Utils/OnlineImportService.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;
  final Map config;
  final bool testMode;

  const ImportFromBEView({
    Key? key,
    this.title,
    required this.config,
    this.testMode = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImportFromBEViewState();
  }
}

class ImportFromBEViewState extends State<ImportFromBEView> {
  late final WebViewController _webViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  bool _extracting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          )
          ..addJavaScriptChannel(
            'SnackbarJSChannel',
            onMessageReceived: (JavaScriptMessage message) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message.message)));
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                if (!mounted || _completed) return;
                final target = (widget.config['targetUrl'] ?? '').toString();
                final redirect =
                    (widget.config['redirectUrl'] ?? '').toString();
                // A target may share the redirect prefix; extract before redirecting.
                if (target.isNotEmpty && url.startsWith(target)) {
                  import(_webViewController, context);
                } else if (redirect.isNotEmpty && url.startsWith(redirect)) {
                  _webViewController.loadRequest(Uri.parse(target));
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
        androidController,
        true,
      );
    }
    // 等待第三方 cookie 设置完成后再加载页面
    if (mounted) {
      await _webViewController.loadRequest(
        Uri.parse(widget.config['initialUrl']),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config['page_title']),
        actions: <Widget>[
          if (widget.testMode)
            IconButton(
              tooltip: S.of(context).import_test_retry,
              icon: const Icon(Icons.play_arrow),
              onPressed: () => import(_webViewController, context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await cookieManager.clearCookies();
              _webViewController.loadRequest(
                Uri.parse(widget.config['initialUrl']),
              );
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
          return Column(
            children: <Widget>[
              widget.config['banner_content'] == null
                  ? Container()
                  : MaterialBanner(
                    forceActionsBelow: true,
                    content: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.config['banner_content'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(widget.config['banner_action']),
                        onPressed:
                            () => launchUrl(
                              Uri.parse(widget.config['banner_url']),
                            ),
                      ),
                    ],
                  ),
              Expanded(child: WebViewWidget(controller: _webViewController)),
            ],
          );
        },
      ),
    );
  }

  import(
    WebViewController controller,
    BuildContext context, {
    String? rsp,
  }) async {
    if (_extracting || _completed || !mounted) return;
    _extracting = true;
    try {
      Toast.showToast(S.of(context).class_parse_toast_importing, context);
      Object response;
      if (rsp != null) {
        response = rsp;
      } else {
        final pre = (widget.config['preExtractJS'] ?? '').toString();
        if (pre.isNotEmpty) await controller.runJavaScript(pre);
        await Future.delayed(
          Duration(seconds: widget.config['delayTime'] ?? 0),
        );
        if (!mounted) return;
        String js;
        if (widget.testMode) {
          js = widget.config['extractJS'] as String;
        } else {
          final key =
              Platform.isIOS
                  ? 'extractJSfileiOS'
                  : Platform.isAndroid
                  ? 'extractJSfileAndroid'
                  : 'extractJSfileOHOS';
          final url =
              widget.config[key] ?? widget.config['extractJSfile'] ?? '';
          final serverRsp = await Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.plain,
            ),
          ).get<String>(url);
          js = serverRsp.data ?? '';
        }
        if (!mounted) return;
        response = await controller.runJavaScriptReturningResult(js);
      }
      final data = decodeOnlineImportResult(response);
      if (!mounted) return;
      final state = ScopedModel.of<MainStateModel>(context);
      final index = await saveOnlineImport(data, widget.config);
      _completed = true;
      await state.changeclassTable(index);
      if (!widget.testMode) {
        UmengCommonSdk.onEvent('class_import', {
          'type': 'be',
          'action': 'success',
        });
      }
      if (!mounted) return;
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (widget.testMode) {
        await showDialog<void>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(S.of(context).import_test_error),
                content: SingleChildScrollView(
                  child: SelectableText(e.toString()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              ),
        );
        return;
      }
      var result = await controller.runJavaScriptReturningResult(
        "window.document.getElementsByTagName('html')[0].outerHTML;",
      );
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
        "way": "be",
      };

      try {
        await Dio().post(
          Url.URL_BACKEND + "/log/log",
          data: FormData.fromMap(info),
        );
      } catch (_) {}

      UmengCommonSdk.onEvent("class_import", {"type": "be", "action": "fail"});

      if (!mounted) return;
      await showDialog<String>(
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
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                  child: Text(S.of(context).parse_error_dialog_add_group),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: errorCode));
                    if (Platform.isIOS) {
                      launchUrl(Uri.parse(Url.QQ_GROUP_APPLE_URL));
                    } else if (Platform.isAndroid) {
                      launchUrl(Uri.parse(Url.QQ_GROUP_ANDROID_URL));
                    } else if (Platform.operatingSystem == 'ohos') {
                      launchUrl(Uri.parse(Url.QQ_GROUP_OHOS_URL));
                    }
                    Navigator.of(context).pop();
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
      return;
    } finally {
      _extracting = false;
    }
  }
}
