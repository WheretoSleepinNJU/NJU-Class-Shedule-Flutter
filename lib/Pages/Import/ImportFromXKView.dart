import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../generated/l10n.dart';
import '../../Utils/CourseParser.dart';
import '../../Components/Toast.dart';

class ImportFromXKView extends StatefulWidget {
  final Map config;

  const ImportFromXKView({Key? key, required this.config}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WebViewState();
  }
}

class _WebViewState extends State<ImportFromXKView> {
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
              await cookieManager.clearCookies();
              _webViewController.loadRequest(Uri.parse(widget.config['initialUrl']));
            },
          )
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
              padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 12),
              child: Column(
                children: [
                  _buildInfoBanner(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: color.outlineVariant.withOpacity(0.35)),
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
              onPressed: () => launch(widget.config['banner_url']),
              child: Text(widget.config['banner_action']),
            ),
        ],
      ),
    );
  }

  import(WebViewController controller, BuildContext context) async {
    Toast.showToast(S.of(context).class_parse_toast_importing, context);
    await controller.runJavaScript(widget.config['preExtractJS'] ?? '');
    await Future.delayed(Duration(seconds: widget.config['delayTime'] ?? 0));
    
    var result = await controller
        .runJavaScriptReturningResult(widget.config['extractJS']);
    String response = result.toString();
    
    if (response.startsWith('"') && response.endsWith('"')) {
       response = response.substring(1, response.length - 1);
    }
    
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