import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/NjuConfig.dart';
import '../../Utils/CourseImportCodec.dart';
import '../../Utils/NjuAutoLoginScript.dart';
import '../../Utils/NjuCredentialStore.dart';
import '../../Utils/NjuEhallJsonImporter.dart';
import '../../Utils/States/MainState.dart';

/// 南大专属导入/登录流程。
///
/// 只有一条登录链路：拿到账号密码 -> 后台 WebView 里跑自动登录脚本
/// （填表 + 过滑块拼图，遇到图形验证码就把真实网页显示出来兜底）->
/// 复用 [NjuEhallJsonImporter] 从已认证的 WebView 读取 eHall JSON，
/// 写入现有课程表模型。
///
/// 账号密码从哪来分两种：第一次用要用户手输（[_Stage.loginForm]），
/// 之后存在 [NjuCredentialStore] 里，"自动更新"直接拿它重跑同一条链路
/// （[_Stage.autoUpdateChoice]）。
///
/// 早期版本还有一条"快捷导入"：不输账密，直接拿 WebView 里残留的
/// Cookie 去访问目标页。实测会话保不住（系统清后台、Cookie 过期都会让
/// 它失效），失败率高到没有使用价值，已经删掉——现在"之前登录过"省掉的
/// 只是重新输账号密码，登录该走的流程一步都不少。
class ImportView extends StatefulWidget {
  const ImportView({Key? key}) : super(key: key);

  @override
  State<ImportView> createState() => _ImportViewState();
}

enum _Stage {
  checkingPriorLogin,
  autoUpdateChoice,
  loginForm,
  loggingIn,
  needManualLogin,
  debugPreFetch,
  fetching,
  error,
}

// TODO(临时测试代码，成品发布前必须删除): 登录成功、抵达目标页之后，
// 先把真实网页显示出来，让你手动切换学期（比如切到有课的下学期）再点
// 按钮触发抓取，用来验证抓取/解析逻辑本身有没有问题，而不是自动直接抓
// 当前学期（可能没课）。现阶段保留，用完之后把这个改回 false（或者
// 直接删掉这段 + `_Stage.debugPreFetch` 相关代码 + `_buildBody` 里对应
// 的 case 分支），恢复"登录成功自动抓取"的正式体验。
const bool _kDebugManualSemesterPick = true; // TODO: 临时测试用，成品前删除

class _ImportViewState extends State<ImportView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _courseTableProvider = CourseTableProvider();
  final _courseProvider = CourseProvider();

  _Stage _stage = _Stage.checkingPriorLogin;
  // 重试时要回到的"起始页"：之前登录过、账号密码也还在，就是自动更新
  // 选择页，否则是登录表单。
  _Stage _initialStage = _Stage.loginForm;
  String _statusText = '';
  String _errorText = '';

  WebViewController? _webViewController;
  NjuEntryConfig? _activeConfig;
  bool _autofillAttempted = false;
  Timer? _loginTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// "登录成功过"跟"课表导入成功过"是两件独立的事——比如暑期没课，
  /// 抓取那一步会失败、根本不会生成课表，但登录本身是成功的。所以这里
  /// 单独存一个标记，只要登录本身通过了就记上，不依赖有没有课表。
  static const _prefsHasLoggedInKey = 'nju_has_logged_in_before';

  /// 决定进来先看到哪一页，顺便把记住的账号密码填进输入框。
  ///
  /// 两件事必须一起做：自动更新就是拿存下来的账号密码重跑一遍登录，
  /// 所以"之前登录过"这个标记单独成立没用——用户手动清过密码的话，
  /// 自动更新点了也没账号可用，那就跟没登录过一样直接进登录表单。
  Future<void> _bootstrap() async {
    bool hasPrior = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      hasPrior = prefs.getBool(_prefsHasLoggedInKey) ?? false;
    } catch (_) {
      hasPrior = false;
    }
    var username = '';
    var password = '';
    try {
      (username, password) = await NjuCredentialStore.read();
    } catch (_) {
      // 读不到就当没存过，退回登录表单让用户手输。
    }
    if (!mounted) return;
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _initialStage = hasPrior && username.isNotEmpty && password.isNotEmpty
          ? _Stage.autoUpdateChoice
          : _Stage.loginForm;
      _stage = _initialStage;
    });
  }

  Future<void> _markLoginSucceeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsHasLoggedInKey, true);
    } catch (_) {
      // 存不上就算了，最多下次还是从登录表单开始，不影响这次的登录本身。
    }
  }

  /// 只在 Android 上、只问一次：小米/OPPO/vivo 等厂商定制系统喜欢清后台/
  /// 清缓存，登录会话（WebView 里的 Cookie）存在系统层面，App 自己保护
  /// 不了，只能申请忽略电池优化来降低被系统当成"后台可清理进程"的概率。
  /// 这只是降低概率，不是保证；用户拒绝也不影响正常使用，所以失败/拒绝
  /// 都直接吞掉，不打断导入成功的流程。
  static const _prefsBatteryOptRequestedKey = 'nju_battery_opt_requested';

  Future<void> _maybeRequestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsBatteryOptRequestedKey) ?? false) return;
      await prefs.setBool(_prefsBatteryOptRequestedKey, true);

      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {
      // 申请失败/被拒绝都无所谓，不影响导入本身。
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _loginTimeoutTimer?.cancel();
    super.dispose();
  }

  void _submitLoginForm() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      Toast.showToast('请输入账号和密码', context);
      return;
    }
    setState(() {
      _stage = _Stage.loggingIn;
      _statusText = '正在登录...';
    });
    _beginLogin(NjuConfig.loginProbe);
  }

  /// 打开后台 WebView 加载登录页，等 [_onPageFinished] 接手注入自动登录
  /// 脚本。自动更新和手输账密走的是同一个方法——两者的区别只在账号密码
  /// 从哪来（存的 / 刚输的），登录本身没有任何差别。
  void _beginLogin(NjuEntryConfig config, {int timeoutSeconds = 25}) {
    _activeConfig = config;
    _autofillAttempted = false;
    _loginTimeoutTimer?.cancel();
    _loginTimeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
      if (!mounted || _stage != _Stage.loggingIn) return;
      // 走 _fallBackToManualLogin 而不是直接改 stage：超时的时候自动登录
      // 脚本多半还在跑，必须先把它停掉再把表单交给用户。
      _fallBackToManualLogin('自动登录超时，请在下方手动完成登录');
    });

    final url = Uri.parse(config.initialUrl);
    if (_webViewController == null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..addJavaScriptChannel(
          NjuAutoLoginScript.channelName,
          onMessageReceived: _onAutoLoginMessage,
        )
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: _onPageFinished,
          onWebResourceError: (error) {
            if (!mounted) return;
            _loginTimeoutTimer?.cancel();
            setState(() {
              _stage = _Stage.error;
              _errorText = '网络错误，请检查网络连接（如需要请先连接南京大学 VPN）';
            });
          },
        ))
        ..loadRequest(url);
    } else {
      _webViewController!.loadRequest(url);
    }
  }

  Future<void> _onPageFinished(String url) async {
    if (!mounted || _activeConfig == null) return;
    final config = _activeConfig!;

    if (url.startsWith(config.targetUrl)) {
      _loginTimeoutTimer?.cancel();
      if (_stage == _Stage.fetching || _stage == _Stage.debugPreFetch) {
        // 已经在抓取/调试预览阶段，避免重复触发。
        return;
      }
      unawaited(_markLoginSucceeded());
      // 登录真的成功了，把这次用的账号密码记住：下次进来就能直接
      // "自动更新"，不用再输一遍。自动更新路径下存的就是同一份，
      // 重存一次没有副作用。
      unawaited(NjuCredentialStore.save(
        _usernameController.text.trim(),
        _passwordController.text,
      ));
      if (_kDebugManualSemesterPick) {
        setState(() => _stage = _Stage.debugPreFetch);
        return;
      }
      await _fetchAndImport(config);
      return;
    }

    final isLoginPage = url.contains('authserver.nju.edu.cn/authserver/login');
    if (!isLoginPage) return;
    if (_stage != _Stage.loggingIn && _stage != _Stage.needManualLogin) return;

    // 还停在登录页：第一次注入自动登录脚本，之后如果又回到登录页，
    // 说明提交失败（账号密码错误，或者过了验证码兜底页又失败一次）。
    if (!_autofillAttempted) {
      _autofillAttempted = true;
      await _startAutoLoginScript();
      // 脚本是异步跑的（填表、过滑块、提交都要时间），结果通过
      // JavaScriptChannel 回到 [_onAutoLoginMessage]，成功则由下一次
      // onPageFinished 命中 targetUrl 接手，这里不再等它的返回值。
      return;
    }

    // 已经尝试过自动填表，又回到了登录页 -> 大概率是账号密码错误。
    if (_stage == _Stage.loggingIn) {
      _loginTimeoutTimer?.cancel();
      final errorMessage = await _scrapeLoginError();
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        if (errorMessage.startsWith('[DEBUG_DUMP]')) {
          _errorText = '没能识别到明确的错误提示。\n\n'
              '下面是登录表单的 HTML 结构（长按可复制发给开发者用来调整识别逻辑）：\n\n'
              '${errorMessage.substring('[DEBUG_DUMP]'.length)}';
        } else {
          _errorText = errorMessage.isNotEmpty
              ? '登录失败：$errorMessage'
              : '账号或密码错误，请检查后重试';
        }
      });
    }
  }

  Future<String> _runJs(String js) async {
    final result = await _webViewController!.runJavaScriptReturningResult(js);
    String status = result.toString();
    if (status.startsWith('"') && status.endsWith('"')) {
      status = status.substring(1, status.length - 1);
    }
    return status;
  }

  /// 把 `assets/scripts/auto_auth_login.js` 注入登录页跑起来。填表、按需
  /// 刷新验证码、过滑块、提交、判断结果全在那个脚本里，这边只负责启动它
  /// 和接收它回传的消息（[_onAutoLoginMessage]）。
  Future<void> _startAutoLoginScript() async {
    try {
      await NjuAutoLoginScript.inject(
        _webViewController!,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      _fallBackToManualLogin('自动登录脚本启动失败（$e），请在下方手动完成登录');
    }
  }

  /// 自动登录脚本通过 JavaScriptChannel 回传的消息。
  void _onAutoLoginMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final event = NjuAutoLoginScript.decode(message.message);
    switch (event.type) {
      case 'log':
        debugPrint('[NjuAutoLogin][${event.level}] ${event.message}');
        return;
      case 'solveCaptcha':
        // 图形验证码识别在扩展里是丢给 background 跑 ONNX 模型的，App 里
        // 没有推理运行时，识别不了。halt 掉脚本（不然它会一直刷验证码跟
        // 用户抢输入框），把真实页面交还给用户手动填。
        _fallBackToManualLogin('出现了图形验证码，请在下方手动完成登录');
        return;
      case 'loginComplete':
        if (event.success) {
          // 成功不在这里收口：还要等 WebView 真的跳到目标页，
          // 由 [_onPageFinished] 命中 targetUrl 之后接手抓取。
          return;
        }
        _handleAutoLoginFailure(event.message);
        return;
    }
  }

  /// 脚本抛上来的失败原因分两类：账号密码错这种再试也没用，直接报错；
  /// 滑块/表单没搞定这种是「机器没过、人能过」，退回手动登录。
  void _handleAutoLoginFailure(String reason) {
    if (_stage != _Stage.loggingIn) return;
    if (reason.contains('NJU_INVALID_CREDENTIALS')) {
      _loginTimeoutTimer?.cancel();
      unawaited(NjuAutoLoginScript.halt(_webViewController!));
      setState(() {
        _stage = _Stage.error;
        _errorText = '账号或密码错误，请检查后重试';
      });
      return;
    }
    if (reason.contains('NJU_SLIDER_FAILED_TWICE')) {
      _fallBackToManualLogin('滑块验证连续失败，请在下方手动完成登录');
      return;
    }
    if (reason.contains('NJU_SLIDER_NO_POINTER_SUPPORT')) {
      // 触摸和鼠标两种合成事件页面都没接住——多半是滑块组件换了实现
      // （比如改用 Pointer Events）。这种是代码要跟着改的，不是用户能
      // 解决的，日志里留一句好定位。
      debugPrint('[NjuAutoLogin] 滑块对合成的 touch/mouse 事件都无反应');
      _fallBackToManualLogin('无法自动完成滑块验证，请在下方手动滑动');
      return;
    }
    _fallBackToManualLogin(
        reason.isEmpty ? '自动登录失败，请在下方手动完成登录' : '自动登录失败：$reason\n请在下方手动完成登录');
  }

  /// 把页面交还给用户手动登录。必须先 halt 脚本：它还在跑的话会继续改
  /// 输入框、刷验证码、点登录按钮，跟用户抢同一个表单。
  void _fallBackToManualLogin(String statusText) {
    if (_stage != _Stage.loggingIn) return;
    _loginTimeoutTimer?.cancel();
    final controller = _webViewController;
    if (controller != null) unawaited(NjuAutoLoginScript.halt(controller));
    setState(() {
      _stage = _Stage.needManualLogin;
      _statusText = statusText;
    });
  }

  /// 调试用：把当前页面上"看起来像验证码/滑块组件"的那块 HTML 导出，
  /// 显示在错误页里方便长按复制。不知道确切的容器选择器，所以尝试了
  /// 几种常见命名，找不到就退而求其次导出整个可见弹窗/对话框区域。
  Future<void> _dumpCaptchaHtml() async {
    const js = '''
      (function(){
        var candidates = [
          '#sliderDiv', '.sliderDiv', '[id*="slider" i]', '[class*="slider" i]',
          '[id*="captcha" i]', '[class*="captcha" i]',
          '[id*="puzzle" i]', '[class*="puzzle" i]'
        ];
        for (var i=0;i<candidates.length;i++){
          var el = document.querySelector(candidates[i]);
          if (el) {
            var rect = el.getBoundingClientRect();
            if (rect.width > 0 && rect.height > 0) {
              // 往上找到看起来像"弹窗容器"的祖先，信息更完整。
              var container = el.closest('.card, .modal, .dialog, [class*="card" i], [class*="modal" i], [class*="dialog" i]') || el;
              return container.outerHTML.substring(0, 4000);
            }
          }
        }
        // 都没找到：退而求其次，导出所有可见的 canvas/dialog 元素的父级结构。
        var canvas = document.querySelector('canvas');
        if (canvas) {
          var parent = canvas.closest('div');
          for (var j=0;j<4 && parent && parent.parentElement; j++) parent = parent.parentElement;
          return (parent || canvas).outerHTML.substring(0, 4000);
        }
        return document.body.outerHTML.substring(0, 4000);
      })();
    ''';
    final dump = await _runJs(js);
    if (!mounted) return;
    setState(() {
      _stage = _Stage.error;
      _errorText = '验证组件结构（长按可复制发给开发者）：\n\n$dump';
    });
  }

  Future<String> _scrapeLoginError() async {
    const js = '''
      (function(){
        var candidates = document.querySelectorAll('[class*="error" i], [class*="tip" i], [id*="error" i], span, div');
        for (var i=0;i<candidates.length;i++){
          var el = candidates[i];
          var text = (el.textContent||'').trim();
          if(text && (text.indexOf('密码') !== -1 || text.indexOf('账号') !== -1 || text.indexOf('用户名') !== -1 || text.indexOf('错误') !== -1 || text.indexOf('失败') !== -1)){
            var rect = el.getBoundingClientRect();
            if(rect.width>0 && rect.height>0) return text.substring(0,80);
          }
        }
        // 没找到明确的错误文案：优先把"登录按钮"那个区域的 HTML 吐出来
        // （之前的 dump 都在表单开头被截断，从没看到过按钮长什么样）。
        var pwd = document.querySelector('input[type="password"]');
        var form = pwd ? (pwd.form || pwd.closest('form')) : null;
        var btnArea = form ? form.querySelector('.ge-btn') : null;
        var dump = btnArea ? btnArea.outerHTML : (form ? form.outerHTML : document.body.innerHTML);
        return '[DEBUG_DUMP]' + dump.substring(0, 3000);
      })();
    ''';
    try {
      final result = await _webViewController!.runJavaScriptReturningResult(js);
      String text = result.toString();
      if (text.startsWith('"') && text.endsWith('"')) {
        text = text.substring(1, text.length - 1);
      }
      return text;
    } catch (e) {
      return '';
    }
  }

  Future<void> _fetchAndImport(NjuEntryConfig config) async {
    setState(() {
      _activeConfig = config;
      _stage = _Stage.fetching;
      _statusText = '正在获取课表...';
    });

    try {
      final courseTableMap = await NjuEhallJsonImporter.fetchCourseTableMap(
        _webViewController!,
        pinyin: config.pinyin,
      );
      await _saveCourseTableMap(config, courseTableMap);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorText = '课表抓取失败：$e';
      });
    }
  }

  /// 把抓到的课表数据落库。
  Future<void> _saveCourseTableMap(
      NjuEntryConfig config, Map<String, dynamic> courseTableMap) async {
    Iterable courses;
    final rawCourses = courseTableMap['courses'];
    if (rawCourses.runtimeType != String) {
      courses = rawCourses;
    } else if (json.decode(rawCourses).runtimeType != String) {
      courses = json.decode(rawCourses);
    } else {
      courses = json.decode(json.decode(rawCourses));
    }
    final coursesMap = List<Map<String, dynamic>>.from(courses);

    final courseTable =
        await _courseTableProvider.insert(CourseTable(courseTableMap['name']));
    final tableId = courseTable.id!;

    if (mounted) {
      await ScopedModel.of<MainStateModel>(context).changeclassTable(tableId);
    }

    for (final courseMap in coursesMap) {
      final dbMap =
          CourseImportCodec.onlineCourseToDbMap(courseMap, tableId: tableId);
      final course = Course.fromMap(dbMap);
      await _courseProvider.insert(course);
    }

    await _courseTableProvider.updateCheckUpdateInfo(
      tableId,
      sourceSchoolPinyin: config.pinyin,
      lastSnapshot: json.encode(coursesMap),
      lastCheckedAt: DateTime.now().toIso8601String(),
    );

    await _maybeRequestBatteryOptimizationExemption();

    if (!mounted) return;
    Toast.showToast('导入成功', context);
    Navigator.of(context).pop(true);
  }

  /// 统一的"重置状态回到某个起始页"，默认回到 [_initialStage]（自动更新
  /// 选择页或登录表单），也可以指定具体页面（比如"新账号登录"按钮要强制
  /// 回登录表单，不是回自动更新选择页）。
  void _retry({_Stage? stage}) {
    setState(() {
      _stage = stage ?? _initialStage;
      _statusText = '';
      _errorText = '';
      _webViewController = null;
      _activeConfig = null;
      _autofillAttempted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入南大课表')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_stage) {
      case _Stage.checkingPriorLogin:
        return const Center(child: CircularProgressIndicator());
      case _Stage.autoUpdateChoice:
        return _buildAutoUpdateChoice(context);
      case _Stage.loginForm:
        return _buildLoginForm(context);
      case _Stage.loggingIn:
      case _Stage.fetching:
        return _buildProgressOverWebView(context);
      case _Stage.needManualLogin:
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text(_statusText, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _dumpCaptchaHtml,
                child: const Text('（调试用）导出当前验证组件结构'),
              ),
            ]),
          ),
          Expanded(child: WebViewWidget(controller: _webViewController!)),
        ]);
      case _Stage.debugPreFetch: // TODO: 临时测试用，成品前删除（连同上面的 _kDebugManualSemesterPick）
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              const Text(
                '（临时调试）登录成功，已到达课表页。\n'
                '可以在下面手动切换学期（比如切到有课的下学期），\n'
                '切好之后点按钮用当前页面内容抓取一次。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _fetchAndImport(_activeConfig!),
                child: const Text('用当前页面内容抓取课表'),
              ),
            ]),
          ),
          Expanded(child: WebViewWidget(controller: _webViewController!)),
        ]);
      case _Stage.error:
        return _buildError(context);
    }
  }

  /// 登录/抓取过程中的转圈界面。
  ///
  /// WebView 是铺在底下、被不透明遮罩盖住的，不是多余的：自动登录脚本回放
  /// 滑块轨迹用的是 `requestAnimationFrame`，而 rAF 只有在 WebView 真的挂进
  /// 视图树、参与合成的时候才会触发。要是这里只挂一个转圈指示器、把 WebView
  /// 留在树外，轨迹回放会一直卡住，直到 [_beginLogin] 的超时把流程推走。
  Widget _buildProgressOverWebView(BuildContext context) {
    final progress = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_statusText),
        ],
      ),
    );
    final controller = _webViewController;
    if (controller == null) return progress;
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: controller)),
        Positioned.fill(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: progress,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoUpdateChoice(BuildContext context) {
    final maskedUsername = _maskUsername(_usernameController.text.trim());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('已记住账号 $maskedUsername', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              '"自动更新"会用记住的账号密码重新登录一次，再抓取最新课表，\n'
              '整个过程不需要你操作；只有在出现图形验证码的时候才会\n'
              '把登录页显示出来让你手动完成。\n'
              '换账号请选"新账号登录"。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startAutoUpdate,
              icon: const Icon(Icons.sync),
              label: const Text('自动更新'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _retry(stage: _Stage.loginForm),
              icon: const Icon(Icons.person_outline),
              label: const Text('新账号登录'),
            ),
          ],
        ),
      ),
    );
  }

  /// 学号中间打码，只是让用户确认"是不是这个账号"，不用把完整学号亮在
  /// 屏幕上。太短的就整个遮掉，免得反而暴露。
  static String _maskUsername(String username) {
    if (username.length <= 4) return '*' * username.length;
    return '${username.substring(0, 2)}'
        '${'*' * (username.length - 4)}'
        '${username.substring(username.length - 2)}';
  }

  /// 拿存下来的账号密码重跑一遍完整登录，跟手输账密走的是同一条链路
  /// （[_beginLogin] -> 注入脚本填表过滑块 -> 命中目标页抓取），区别
  /// 只是用户不用再输一遍。
  void _startAutoUpdate() {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      // [_bootstrap] 已经挡过一次，正常进不来；真进来了就当没登录过。
      _retry(stage: _Stage.loginForm);
      return;
    }
    setState(() {
      _stage = _Stage.loggingIn;
      _statusText = '正在用记住的账号自动登录...';
    });
    _beginLogin(NjuConfig.loginProbe);
  }

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('南京大学统一身份认证', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: '学号/工号', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder()),
            onSubmitted: (_) => _submitLoginForm(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submitLoginForm, child: const Text('登录')),
          if (_usernameController.text.isNotEmpty ||
              _passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await NjuCredentialStore.clear();
                if (!mounted) return;
                setState(() {
                  _usernameController.clear();
                  _passwordController.clear();
                  // 账号密码没了，自动更新就没得可用，重试的落点也要跟着
                  // 改回登录表单，不然会弹回一个点了就跳走的选择页。
                  _initialStage = _Stage.loginForm;
                });
                Toast.showToast('已清除记住的账号密码', context);
              },
              child: const Text('清除已记住的账号密码'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _retry, child: const Text('重试')),
              // 自动更新失败最常见的原因就是密码在学校那边改过了，重试
              // 多少次都是同样的结果，得给一条换账号密码的出路。
              if (_initialStage == _Stage.autoUpdateChoice) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _retry(stage: _Stage.loginForm),
                  child: const Text('重新输入账号密码'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SelectableText(
              _errorText,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
