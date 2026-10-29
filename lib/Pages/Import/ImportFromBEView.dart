import '../../AdaptiveUI/adaptive_ui.dart';
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
import '../../Resources/Url.dart';
import '../../Utils/OnlineImportService.dart';
import '../../Utils/ImportTestScript.dart';

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
  bool _pageLoading = true;
  String? _testStatus;
  String? _testUrl;
  String? _testJsError;

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
              onPageStarted: (url) {
                _pageLoading = true;
                _recordTestNavigation(url);
              },
              onPageFinished: (String url) {
                _pageLoading = false;
                _recordTestNavigation(url);
                _handleImportUrl(url);
              },
              onUrlChange: (change) {
                if (change.url != null) _recordTestNavigation(change.url!);
                // History API navigation does not finish a new page load.
                // Full navigation still waits for onPageFinished so scripts
                // run in the destination document, rather than the old page.
                if (!_pageLoading && change.url != null) {
                  _handleImportUrl(change.url!);
                }
              },
            ),
          );

    // 启用第三方 Cookie 支持
    _enableThirdPartyCookies();
  }

  void _recordTestNavigation(String url) {
    if (!mounted || !widget.testMode) return;
    setState(() {
      _testUrl = url;
      if (!_extracting) {
        _testStatus =
            _pageLoading
                ? S.of(context).import_test_loading
                : S.of(context).import_test_waiting_url;
      }
    });
  }

  void _testStep(String status) {
    if (mounted && widget.testMode) {
      setState(() => _testStatus = status);
    }
  }

  String get _testAddress {
    // Login tickets and fragments are unnecessary for matching diagnosis.
    return (_testUrl ?? widget.config['initialUrl'])
        .toString()
        .split('?')
        .first
        .split('#')
        .first;
  }

  Future<void> _runTestPreScript(
    WebViewController controller,
    String script,
  ) async {
    // Android does not propagate JS exceptions. A final marker verifies that
    // the script completed, while preserving its global declaration scope.
    // Avoid eval()/Function(), which the portal's CSP may forbid.
    const marker = 'NJU_IMPORT_PRE_COMPLETED';
    dynamic result = await controller
        .runJavaScriptReturningResult('$script\n;"$marker";')
        .timeout(const Duration(seconds: 30));
    for (var i = 0; i < 4 && result is String; i++) {
      try {
        result = jsonDecode(result);
      } on FormatException {
        break;
      }
    }
    if (result != marker) {
      throw FormatException(
        _testJsError != null
            ? 'preExtractJS: $_testJsError'
            : S.of(context).import_test_script_invalid,
      );
    }
  }

  void _handleImportUrl(String url) {
    if (!mounted || _completed || _extracting) return;
    final target = (widget.config['targetUrl'] ?? '').toString();
    final redirect = (widget.config['redirectUrl'] ?? '').toString();
    // A target may share the redirect prefix; extract before redirecting.
    if (target.isNotEmpty && url.startsWith(target)) {
      import(_webViewController, context);
    } else if (target.isNotEmpty &&
        redirect.isNotEmpty &&
        url.startsWith(redirect)) {
      _pageLoading = true;
      _webViewController.loadRequest(Uri.parse(target));
    }
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
      if (widget.testMode) {
        await androidController.setOnConsoleMessage((message) {
          if (_extracting && message.level == JavaScriptLogLevel.error) {
            _testJsError = message.message;
          }
        });
      }
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
    return AdaptiveScaffold(
      scrollUnderAppBar: false,
      appBar: AdaptiveTopAppBar(
        title: Text(widget.config['page_title']),
        actions: <Widget>[
          if (widget.testMode)
            AdaptiveIconButton(
              key: const ValueKey('import-test-retry'),
              tooltip: S.of(context).import_test_retry,
              icon: const Icon(Icons.play_arrow),
              onPressed:
                  _extracting
                      ? null
                      : () => import(_webViewController, context),
            ),
          AdaptiveIconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                widget.testMode && _extracting
                    ? null
                    : () async {
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
              if (widget.testMode)
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _testStatus ?? S.of(context).import_test_loading,
                          key: const ValueKey('import-test-status'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _testAddress.replaceFirstMapped(
                                  RegExp(r'/(https?)/[a-f0-9]{30,}/'),
                                  (match) => '/${match[1]}/…/',
                                ),
                                key: const ValueKey('import-test-current-url'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            AdaptiveIconButton(
                              tooltip:
                                  MaterialLocalizations.of(
                                    context,
                                  ).copyButtonLabel,
                              onPressed:
                                  () => Clipboard.setData(
                                    ClipboardData(text: _testAddress),
                                  ),
                              icon: const Icon(Icons.copy, size: 18),
                            ),
                          ],
                        ),
                        if (_extracting &&
                            _testStatus != S.of(context).import_test_error)
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
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
                      AdaptiveButton.text(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(widget.config['banner_action']),
                        onPressed:
                            () => launchUrl(
                              Uri.parse(widget.config['banner_url'])
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
    _testJsError = null;
    _testStep(S.of(context).import_test_preparing);
    try {
      if (!widget.testMode) {
        Toast.showToast(S.of(context).class_parse_toast_importing, context);
      }
      Object response;
      if (rsp != null) {
        response = rsp;
      } else {
        final pre = (widget.config['preExtractJS'] ?? '').toString();
        if (pre.isNotEmpty) {
          if (widget.testMode) {
            await _runTestPreScript(controller, pre);
          } else {
            await controller.runJavaScript(pre);
          }
        }
        if (!mounted) return;
        _testStep(
          '${S.of(context).import_test_delay} (${widget.config['delayTime'] ?? 0}s)',
        );
        await Future.delayed(
          Duration(seconds: widget.config['delayTime'] ?? 0),
        );
        if (!mounted) return;
        _testStep(S.of(context).import_test_extracting);
        _testJsError = null;
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
        final execution = controller.runJavaScriptReturningResult(
          widget.testMode ? guardImportTestExtraction(js) : js,
        );
        response =
            widget.testMode
                ? await execution.timeout(const Duration(seconds: 60))
                : await execution;
        if (widget.testMode && mounted) {
          validateImportTestExtraction(
            response,
            emptyResultMessage: S.of(context).import_test_extract_empty,
          );
        }
      }
      final data = decodeOnlineImportResult(response);
      if (!mounted) return;
      _testStep(S.of(context).import_test_saving);
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
        final failedStep = _testStatus;
        _testStep(S.of(context).import_test_error);
        await showDialog<void>(
          context: context,
          builder:
              (dialogContext) => AdaptiveDialog(
                title: Text(S.of(context).import_test_error),
                content: SingleChildScrollView(
                  child: SelectableText(
                    [
                      if (failedStep != null) failedStep,
                      e.toString(),
                      if (_testJsError != null &&
                          !e.toString().contains(_testJsError!))
                        _testJsError!,
                    ].join('\n'),
                  ),
                ),
                actions: [
                  AdaptiveButton.text(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel
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
      if (mounted && widget.testMode) setState(() {});
    }
  }
}
