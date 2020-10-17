import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
//
//const String examplepage = '''
//      <!DOCTYPE html><html>
//      <head><title>Navigation Delegate Example</title></head>
//      <body>
//      <p>
//      The navigation delegate is set to block navigation to the youtube website.
//      </p>
//      <ul>
//      <ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
//      <ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
//      </ul>
//      </body>
//      </html>
//      ''';

class WebviewDemo extends StatefulWidget {
  final String title;

  WebviewDemo({Key key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WebviewDemoState();
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

class _WebviewDemoState extends State<WebviewDemo> {
  //
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('统一认证登录'),
        actions: <Widget>[
//          NavigationControls(_controller.future),
          SampleMenu(_controller.future)
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl: 'https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
            },
            javascriptChannels: <JavascriptChannel>[
              snackbarJavascriptChannel(context),
            ].toSet(),
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith("http://elite.nju.edu.cn/jiaowu/login.do")) {
                print('Login success!');
              }
              return NavigationDecision.navigate;
            },
          );
        },
      ),
    );
  }
}
//
//enum MenuOptions {
//  showUserAgent,
//  listCookies,
//  clearCookies,
//  addToCache,
//  listCache,
//  clearCache,
//  navigationDelegate
//}
//
class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);
  final Future<WebViewController> controller;
//  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {listCookies(controller.data, context);},
        );
//        return PopupMenuButton<MenuOptions>(
//          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
//            PopupMenuItem(
//              value: MenuOptions.showUserAgent,
//              child: const Text('Show User Agent'),
//              enabled: controller.hasData,
//            ),
//            PopupMenuItem(
//              value: MenuOptions.listCookies,
//              child: const Text('List Cookies'),
//            ),
//            PopupMenuItem(
//              value: MenuOptions.clearCookies,
//              child: const Text('Clear Cookies'),
//            ),
//            PopupMenuItem(
//              value: MenuOptions.addToCache,
//              child: const Text('Add to Cache'),
//            ),
//            PopupMenuItem(
//              value: MenuOptions.listCache,
//              child: const Text('List Cache'),
//            ),
//            PopupMenuItem(
//              value: MenuOptions.clearCache,
//              child: const Text('Clear Cache'),
//            ),
//            PopupMenuItem(
//              value: MenuOptions.navigationDelegate,
//              child: const Text('Navigation Delegate Demo'),
//            )
//          ],
//          onSelected: (MenuOptions value) {
//            switch (value) {
//              case MenuOptions.showUserAgent:
//                showUserAgent(controller.data, context);
//                break;
//              case MenuOptions.listCookies:
//                listCookies(controller.data, context);
//                break;
//              case MenuOptions.clearCookies:
//                clearCookies(controller.data, context);
//                break;
//              case MenuOptions.addToCache:
//                addToCache(controller.data, context);
//                break;
//              case MenuOptions.listCache:
//                listCache(controller.data, context);
//                break;
//              case MenuOptions.clearCache:
//                clearCache(controller.data, context);
//                break;
//              case MenuOptions.navigationDelegate:
//                navigationDelegateDemo(controller.data, context);
//                break;
//              default:
//            }
//          },
//        );
      },
    );
  }
//
//  navigationDelegateDemo(
//      WebViewController controller, BuildContext context) async {
//    final String contentbase64 =
//    base64Encode(const Utf8Encoder().convert(examplepage));
//    controller.loadUrl('data:text/html;base64,$contentbase64');
//  }
//
//  addToCache(WebViewController controller, BuildContext context) async {
//    await controller.evaluateJavascript(
//        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
//    Scaffold.of(context).showSnackBar(
//      const SnackBar(
//        content: Text('Added a test entry to cache'),
//      ),
//    );
//  }
//
//  void listCache(WebViewController controller, BuildContext context) async {
//    await controller.evaluateJavascript(
//        'caches.keys().then((cacheKeys) => JSON.stringify({"cacheKeys": cacheKeys, "localStorage": localStorage })).then((caches) => SnackbarJSChannel.postMessage(caches))');
//  }
//
//  void clearCache(WebViewController controller, BuildContext context) async {
//    await controller.clearCache();
//    Scaffold.of(context).showSnackBar(
//      const SnackBar(
//        content: Text('Cache Cleared'),
//      ),
//    );
//  }
//
  listCookies(WebViewController controller, BuildContext context) async {
    final String cookies =
    await controller.evaluateJavascript('document.cookie');
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[const Text('Cookies:'), getCookies(cookies)],
        ),
      ),
    );
  }

  Widget getCookies(String cookies) {
    if (null == cookies || cookies.isEmpty) {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets = cookieList.map(
          (String cookie) => Text(cookie),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }
//
//  void clearCookies(WebViewController controller, BuildContext context) async {
//    final bool hadCookies = await cookieManager.clearCookies();
//    String message = 'There are no cookies';
//    Scaffold.of(context).showSnackBar(
//      SnackBar(
//        content: Text(message),
//      ),
//    );
//  }
//
//  showUserAgent(WebViewController controller, BuildContext context) {
//    controller.evaluateJavascript(
//        'SnackbarJSChannel.postMessage("User Agent: " + navigator.userAgent);');
//  }
//}
//
//class NavigationControls extends StatelessWidget {
//  const NavigationControls(this._webViewControllerFuture);
//  final Future<WebViewController> _webViewControllerFuture;
//
//  @override
//  Widget build(BuildContext context) {
//    return FutureBuilder(
//      future: _webViewControllerFuture,
//      builder:
//          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
//        final bool webViewReady =
//            snapshot.connectionState == ConnectionState.done;
//        final WebViewController controller = snapshot.data;
//        return Row(
//          children: <Widget>[
////            IconButton(
////              icon: const Icon(Icons.arrow_back_ios),
////              onPressed: !webViewReady
////                  ? null
////                  : () async {
////                if (await controller.canGoBack()) {
////                  controller.goBack();
////                } else {
////                  Scaffold.of(context).showSnackBar(
////                    const SnackBar(
////                      content: Text("No Back history Item"),
////                    ),
////                  );
////                }
////              },
////            ),
////            IconButton(
////              icon: const Icon(Icons.arrow_forward_ios),
////              onPressed: !webViewReady
////                  ? null
////                  : () async {
////                if (await controller.canGoForward()) {
////                  controller.goForward();
////                } else {
////                  Scaffold.of(context).showSnackBar(
////                    const SnackBar(
////                      content: Text("No Forward history Item"),
////                    ),
////                  );
////                }
////              },
////            ),
//            IconButton(
//              icon: const Icon(Icons.refresh),
////              onPressed: !webViewReady
////                  ? null
////                  : () async {
////                controller.reload();
//              },
//            )
//          ],
//        );
//      },
//    );
//  }
}
