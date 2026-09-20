import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/NjuConfig.dart';
import '../../Utils/CourseDiff.dart';
import '../../Utils/CourseImportCodec.dart';
import '../../Utils/NjuEhallJsonImporter.dart';

/// "检查更新"页面：复用已登录 WebView，通过 [NjuEhallJsonImporter] 读取
/// eHall JSON，
/// 但只解析、不直接写库——抓到新数据后先和当前数据库里的课程做 diff，
/// 展示变更预览，由用户确认后再落库。
class CheckUpdateView extends StatefulWidget {
  final int tableId;

  const CheckUpdateView({Key? key, required this.tableId}) : super(key: key);

  @override
  State<CheckUpdateView> createState() => _CheckUpdateViewState();
}

enum _Stage { loadingConfig, unsupported, webview, reviewing, applied }

class _CheckUpdateViewState extends State<CheckUpdateView> {
  final CourseTableProvider _courseTableProvider = CourseTableProvider();
  final CourseProvider _courseProvider = CourseProvider();

  _Stage _stage = _Stage.loadingConfig;
  String _message = '正在准备检查…';
  Map? _config;
  WebViewController? _webViewController;
  Timer? _sessionTimeoutTimer;

  CourseDiffResult? _diff;
  List<Map<String, dynamic>>? _newCoursesMap;
  List<Course>? _oldCourses;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _sessionTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final pinyin =
        await _courseTableProvider.getSourceSchoolPinyin(widget.tableId);
    if (pinyin == null || pinyin.isEmpty) {
      setState(() {
        _stage = _Stage.unsupported;
        _message = '该课表不是通过学校自动导入创建的，无法检查更新。';
      });
      return;
    }

    final entry = NjuConfig.findByPinyin(pinyin);
    if (entry == null) {
      setState(() {
        _stage = _Stage.unsupported;
        _message = '未能找到该课表对应的学校配置，无法检查更新。';
      });
      return;
    }

    setState(() {
      _config = entry.toConfigMap();
      _stage = _Stage.webview;
    });
    _initWebView();
  }

  void _initWebView() {
    final config = _config!;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (config['redirectUrl'] != '' &&
                url.startsWith(config['redirectUrl'])) {
              _webViewController!.loadRequest(Uri.parse(config['targetUrl']));
            } else if (url.startsWith(config['targetUrl'])) {
              _sessionTimeoutTimer?.cancel();
              _fetchAndDiff();
            } else if (url.contains('authserver.nju.edu.cn/authserver/login')) {
              // 落回了登录页，说明之前保存的登录状态已经失效——"检查更新"
              // 本身不做登录（那一整套自动填表/验证码兜底逻辑只在
              // ImportView 里维护一份，这里不重复实现），直接提示用户
              // 去导入页重新登录一次。
              _sessionTimeoutTimer?.cancel();
              if (!mounted) return;
              setState(() {
                _stage = _Stage.unsupported;
                _message = '登录状态已失效，需要重新登录。请到"导入南大课表"页面用'
                    '"新账号登录"重新登录一次，之后再回来检查更新。';
              });
            }
          },
          onWebResourceError: (error) {
            _sessionTimeoutTimer?.cancel();
            if (!mounted) return;
            setState(() {
              _stage = _Stage.unsupported;
              _message = '网络错误，请检查网络连接（如需要请先连接南京大学 VPN）。';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(config['initialUrl']));

    _sessionTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted || _stage != _Stage.webview) return;
      setState(() {
        _stage = _Stage.unsupported;
        _message = '检查超时，请稍后重试。';
      });
    });
  }

  Future<void> _fetchAndDiff() async {
    try {
      Toast.showToast('正在抓取最新课表…', context);
      final courseTableMap = await NjuEhallJsonImporter.fetchCourseTableMap(
        _webViewController!,
        pinyin: _config!['pinyin'].toString(),
      );

      Iterable courses;
      final rawCourses = courseTableMap['courses'];
      if (rawCourses.runtimeType != String) {
        courses = rawCourses;
      } else if (json.decode(rawCourses).runtimeType != String) {
        courses = json.decode(rawCourses);
      } else {
        courses = json.decode(json.decode(rawCourses));
      }
      final newCoursesMap = List<Map<String, dynamic>>.from(courses);
      final newCourses = newCoursesMap
          .map((m) => Course.fromMap(
              CourseImportCodec.onlineCourseToDbMap(m, tableId: widget.tableId)))
          .toList();

      final oldCoursesRaw = await _courseProvider.getAllCourses(widget.tableId);
      final oldCourses =
          oldCoursesRaw.map((m) => Course.fromMap(Map<String, dynamic>.from(m))).toList();

      final diff = diffCourseLists(oldCourses, newCourses);

      // 无论用户是否应用变更，都记录一次检查时间和最新抓取结果，供以后参考。
      await _courseTableProvider.updateCheckUpdateInfo(
        widget.tableId,
        lastSnapshot: json.encode(newCoursesMap),
        lastCheckedAt: DateTime.now().toIso8601String(),
      );

      setState(() {
        _diff = diff;
        _newCoursesMap = newCoursesMap;
        _oldCourses = oldCourses;
        _stage = _Stage.reviewing;
      });
    } catch (e) {
      setState(() {
        _stage = _Stage.unsupported;
        _message = '检查更新失败：$e';
      });
    }
  }

  Future<void> _applyChanges() async {
    final diff = _diff!;

    for (final change in diff.changedSlots) {
      final updated = change.oldSlot;
      updated.classroom = change.newSlot.classroom;
      updated.info = change.newSlot.info;
      updated.weekTime = change.newSlot.weekTime;
      updated.startTime = change.newSlot.startTime;
      updated.timeCount = change.newSlot.timeCount;
      updated.weeks = change.newSlot.weeks;
      await _courseProvider.update(updated);
    }

    for (final slot in diff.addedSlots) {
      slot.tableId = widget.tableId;
      await _courseProvider.insert(slot);
    }
    for (final group in diff.addedCourses.values) {
      for (final slot in group) {
        slot.tableId = widget.tableId;
        await _courseProvider.insert(slot);
      }
    }

    if (mounted) {
      Toast.showToast('已应用课表变更', context);
      setState(() => _stage = _Stage.applied);
    }
  }

  Future<void> _removeSlot(Course slot) async {
    if (slot.id != null) {
      await _courseProvider.delete(slot.id!);
      Toast.showToast('已删除', context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('检查课表更新')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_stage) {
      case _Stage.loadingConfig:
        return const Center(child: CircularProgressIndicator());
      case _Stage.unsupported:
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_message, textAlign: TextAlign.center)));
      case _Stage.webview:
        return Column(children: [
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text('请登录以检查课表是否有更新，登录成功后将自动比对。')),
          Expanded(child: WebViewWidget(controller: _webViewController!)),
        ]);
      case _Stage.reviewing:
        return _buildReview(context);
      case _Stage.applied:
        return const Center(child: Text('变更已应用完成。'));
    }
  }

  Widget _buildReview(BuildContext context) {
    final diff = _diff!;
    if (diff.isEmpty) {
      return const Center(child: Text('没有检测到课表变化。'));
    }

    final items = <Widget>[];

    if (diff.addedCourses.isNotEmpty) {
      items.add(_sectionTitle('新增课程'));
      for (final entry in diff.addedCourses.entries) {
        for (final c in entry.value) {
          items.add(ListTile(
            title: Text(c.name ?? '', style: const TextStyle(color: Colors.green)),
            subtitle: Text('${c.teacher ?? ''} · ${c.classroom ?? ''}'),
          ));
        }
      }
    }

    if (diff.removedCourses.isNotEmpty) {
      items.add(_sectionTitle('课程消失（不会自动删除，需手动确认）'));
      for (final entry in diff.removedCourses.entries) {
        for (final c in entry.value) {
          items.add(ListTile(
            title: Text(c.name ?? '', style: const TextStyle(color: Colors.red)),
            subtitle: Text('${c.teacher ?? ''} · ${c.classroom ?? ''}'),
            trailing: TextButton(
                onPressed: () => _removeSlot(c), child: const Text('删除')),
          ));
        }
      }
    }

    if (diff.changedSlots.isNotEmpty) {
      items.add(_sectionTitle('信息变更'));
      for (final change in diff.changedSlots) {
        final fieldNames = {
          'classroom': '教室',
          'info': '备注',
          'weekTime': '星期',
          'startTime': '起始节次',
          'timeCount': '节次跨度',
          'weeks': '周次',
        };
        final desc = change.changedFields.entries
            .map((e) =>
                '${fieldNames[e.key] ?? e.key}：${e.value.key ?? ''} → ${e.value.value ?? ''}')
            .join('\n');
        items.add(ListTile(
          title: Text(change.oldSlot.name ?? ''),
          subtitle: Text(desc),
        ));
      }
    }

    if (diff.addedSlots.isNotEmpty) {
      items.add(_sectionTitle('新增时间段'));
      for (final c in diff.addedSlots) {
        items.add(ListTile(
          title: Text(c.name ?? '', style: const TextStyle(color: Colors.green)),
          subtitle: Text('星期${c.weekTime} 第${c.startTime}节 · ${c.classroom ?? ''}'),
        ));
      }
    }

    if (diff.removedSlots.isNotEmpty) {
      items.add(_sectionTitle('取消的时间段（不会自动删除，需手动确认）'));
      for (final c in diff.removedSlots) {
        items.add(ListTile(
          title: Text(c.name ?? '', style: const TextStyle(color: Colors.red)),
          subtitle: Text('星期${c.weekTime} 第${c.startTime}节 · ${c.classroom ?? ''}'),
          trailing: TextButton(
              onPressed: () => _removeSlot(c), child: const Text('删除')),
        ));
      }
    }

    return Column(children: [
      Expanded(child: ListView(children: items)),
      Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _applyChanges,
          child: const Text('应用新增/变更（不含上方需手动删除的项）'),
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
