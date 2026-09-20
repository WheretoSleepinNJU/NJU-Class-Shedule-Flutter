import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// 把 `assets/scripts/auto_auth_login.js` 搬进 App 的 WebView 里跑。
///
/// 那个脚本原本是 Chrome 扩展的 content script，它自己不认识 WebView，
/// 依赖三样只有扩展环境才有的东西：
///   * `chrome.storage.local` —— 读账号密码和几个开关；
///   * `chrome.runtime.getURL()` + `fetch()` —— 读打包在扩展里的滑块轨迹；
///   * `chrome.runtime.sendMessage()` —— 回传日志/登录结果、请求验证码识别。
///
/// 所以这里先注入一段 shim，把这三样分别接到「Dart 传进来的配置」「内嵌的
/// 轨迹 JSON」「JavaScriptChannel」上，再原样注入脚本本身——脚本的 DOM 逻辑
/// 一个字都不用改。
///
/// 脚本来自 https://github.com/121mc/Auto_Auth_Login 的 `content/content.js`，
/// 但已经是改过的分支（滑块重试 5 次改 2 次、失败原因换成
/// `NJU_INVALID_CREDENTIALS` / `NJU_SLIDER_FAILED_TWICE` 这两个码给 Dart 侧
/// 分类用）。上游更新不能直接覆盖，得手动合。
class NjuAutoLoginScript {
  /// 脚本回传消息用的 JavaScriptChannel 名字，注册在 WebViewController 上。
  static const String channelName = 'NjuAutoLogin';

  static const String _scriptAsset = 'assets/scripts/auto_auth_login.js';

  /// 脚本用 `chrome.runtime.getURL('recordings/xxx.json')` 读滑块轨迹。
  /// 扩展里这些是打包资源，这边改成从 assets 读出来内嵌进 shim，键名保持
  /// 和脚本里写的相对路径一致。
  static const Map<String, String> _bundledAssets = {
    'recordings/3.json': 'assets/recordings/3.json',
  };

  static String? _cachedShim;
  static String? _cachedContentScript;

  /// 注入并启动自动登录。调用前 WebView 必须已经注册了 [channelName] 通道
  /// （见 [ImportView]），否则脚本回传消息时会直接报错。
  ///
  /// 这个方法只负责「把脚本跑起来」，登录成功/失败不通过返回值给出，而是
  /// 由脚本通过通道回传 [NjuAutoLoginEvent]。
  static Future<void> inject(
    WebViewController controller, {
    required String username,
    required String password,
  }) async {
    await _loadAssets();
    final storage = jsonEncode({
      'nju_auto_login_pending': true,
      'nju_username': username,
      'nju_password': password,
      // App 里没有扩展那套调试面板，滑块调试记录一律关掉，省得脚本每一步
      // 都往通道里塞画布截图。
      'nju_debug_mode': false,
    });
    // 顺序不能换：先装 shim，再把账号密码写进它的假 storage，最后才跑脚本
    // ——脚本一进来就读 `chrome.storage.local`，读不到就直接 return 了。
    // 脚本本身是个 IIFE，包在 if 里语法没问题；这层守卫是防同一个页面被
    // 注入两次（登录页内部还有异步跳转会再触发一次 onPageFinished），不然
    // 会跑起来两份流程、把登录按钮点两遍。整页刷新会清掉标记，正是想要的。
    await controller.runJavaScript('''
${_cachedShim!}
window.__njuBridge.configure($storage);
if (!window.__njuAutoLoginStarted) {
  window.__njuAutoLoginStarted = true;
${_cachedContentScript!}
}
''');
  }

  /// 让脚本停下来：之后所有 `chrome.runtime.sendMessage` 都返回永不 settle
  /// 的 Promise，脚本里那些 `await` 就会一直挂着，不会继续刷验证码、改
  /// 输入框、点登录按钮。
  ///
  /// 交还给用户手动登录之前必须调用，否则脚本会和用户抢同一个表单。
  static Future<void> halt(WebViewController controller) async {
    try {
      await controller
          .runJavaScript('window.__njuBridge && window.__njuBridge.halt();');
    } catch (_) {
      // 页面可能已经跳走了，停不停都无所谓。
    }
  }

  /// 解析通道里收到的一条消息。
  static NjuAutoLoginEvent decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NjuAutoLoginEvent(
          type: decoded['type']?.toString() ?? '',
          message: decoded['message']?.toString() ?? '',
          level: decoded['level']?.toString() ?? 'info',
          success: decoded['success'] == true,
        );
      }
    } catch (_) {
      // 落到下面按未知消息处理。
    }
    return NjuAutoLoginEvent(type: '', message: raw);
  }

  static Future<void> _loadAssets() async {
    if (_cachedShim != null) return;
    _cachedContentScript = await rootBundle.loadString(_scriptAsset);
    final assets = <String, String>{};
    for (final entry in _bundledAssets.entries) {
      assets[entry.key] = await rootBundle.loadString(entry.value);
    }
    _cachedShim = _shim(assets);
  }

  /// `chrome.*` 的替身。只实现脚本真正用到的那几个 API，其余一律返回空对象
  /// ——脚本里对未知响应都是「拿不到就当没有」，不会因此崩掉。
  static String _shim(Map<String, String> assets) {
    final assetsJson = jsonEncode(assets);
    return '''
(function () {
  if (window.__njuBridge) return;

  var ASSET_PREFIX = 'nju-bundled-asset://';
  var bridge = {
    storage: {},
    assets: $assetsJson,
    pending: {},
    seq: 0,
    halted: false
  };
  window.__njuBridge = bridge;

  bridge.configure = function (storage) {
    bridge.storage = storage || {};
    bridge.halted = false;
  };

  bridge.halt = function () {
    bridge.halted = true;
  };

  function post(payload) {
    try {
      $channelName.postMessage(JSON.stringify(payload));
    } catch (e) {
      // 通道没注册上也不该把脚本带崩，最多是 Dart 侧收不到进度。
    }
  }

  // 卡死用：halt 之后脚本里的 await 全部停在这里，页面就还给用户了。
  function never() {
    return new Promise(function () {});
  }

  // Dart 侧处理完 solveCaptcha 之后回调这里，把对应的请求 resolve 掉。
  bridge.resolve = function (id, response) {
    var entry = bridge.pending[id];
    if (!entry) return;
    delete bridge.pending[id];
    entry(response || {});
  };

  var nativeFetch = window.fetch ? window.fetch.bind(window) : null;
  window.fetch = function (input, init) {
    var url = typeof input === 'string' ? input : (input && input.url) || '';
    if (url.indexOf(ASSET_PREFIX) === 0) {
      var body = bridge.assets[url.slice(ASSET_PREFIX.length)];
      if (body === undefined) {
        return Promise.resolve(new Response('', { status: 404 }));
      }
      return Promise.resolve(new Response(body, {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }));
    }
    return nativeFetch(input, init);
  };

  function sendMessage(message, callback) {
    if (bridge.halted) return never();
    var action = (message && message.action) || '';

    if (action === 'solveCaptcha') {
      // 图形验证码识别在扩展里是丢给 background 跑 ONNX 模型的，App 这边
      // 没有推理运行时，只能把请求交给 Dart：Dart 要么给出识别结果，要么
      // 直接 halt 掉脚本、把页面交还给用户手填。
      var id = ++bridge.seq;
      var promise = new Promise(function (resolve) {
        bridge.pending[id] = resolve;
      }).then(function (response) {
        if (typeof callback === 'function') callback(response);
        return response;
      });
      post({ type: 'solveCaptcha', id: id });
      return promise;
    }

    if (action === 'contentLog') {
      post({ type: 'log', level: message.level || 'info', message: message.msg || '' });
    } else if (action === 'loginComplete') {
      post({
        type: 'loginComplete',
        success: message.success === true,
        message: message.message || ''
      });
    }
    // recordSliderCaptchaDebug 之类的调试上报直接吞掉，调试开关本来就是关的。

    var resolved = Promise.resolve({});
    if (typeof callback === 'function') resolved.then(callback);
    return resolved;
  }

  window.chrome = window.chrome || {};
  window.chrome.runtime = window.chrome.runtime || {};
  window.chrome.runtime.lastError = undefined;
  window.chrome.runtime.sendMessage = sendMessage;
  window.chrome.runtime.getURL = function (path) {
    return ASSET_PREFIX + path;
  };
  window.chrome.storage = window.chrome.storage || {};
  window.chrome.storage.local = {
    get: function (keys) {
      var list;
      if (typeof keys === 'string') list = [keys];
      else if (Array.isArray(keys)) list = keys;
      else list = Object.keys(keys || {});
      var out = {};
      for (var i = 0; i < list.length; i++) {
        var key = list[i];
        if (key in bridge.storage) out[key] = bridge.storage[key];
      }
      return Promise.resolve(out);
    },
    set: function () {
      return Promise.resolve();
    }
  };
})();
''';
  }
}

/// 自动登录脚本回传的一条消息。
class NjuAutoLoginEvent {
  /// `log` / `loginComplete` / `solveCaptcha`，空字符串表示没认出来。
  final String type;
  final String message;
  final String level;
  final bool success;

  const NjuAutoLoginEvent({
    required this.type,
    this.message = '',
    this.level = 'info',
    this.success = false,
  });
}
