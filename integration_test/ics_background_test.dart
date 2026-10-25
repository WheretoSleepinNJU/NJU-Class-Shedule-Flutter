import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/Settings/BackgroundSettingsView.dart';
import 'package:wheretosleepinnju/Utils/BackgroundService.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

Future<void> report(Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
      Uri.parse('http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8782'),
    );
    req.headers.contentType = ContentType.json;
    final bytes = utf8.encode(
      jsonEncode({'platform': Platform.operatingSystem, ...data}),
    );
    req.contentLength = bytes.length;
    req.add(bytes);
    final response = await req.close();
    await response.drain<void>();
    expect(response.statusCode, 200);
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'ICS and multi-image backgrounds on the real app',
    (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final tables = CourseTableProvider(), courses = CourseProvider();
      final beforeIds =
          (await tables.getAllCourseTable()).map((t) => t['id']).toSet();
      final backgrounds = BackgroundService.instance;
      final temporary = await getTemporaryDirectory();
      final sources = <File>[];
      Future<void> settle([int count = 8]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder finder) async {
        for (var i = 0; i < 120 && finder.evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(finder, findsWidgets);
      }

      Finder key(String value) => find.byKey(ValueKey(value));
      Future<void> tap(Finder finder) async {
        await until(finder);
        await tester.ensureVisible(finder.first);
        await settle(2);
        await tester.tap(finder.first);
        await settle();
      }

      Future<void> snap(
        String name,
        String note, {
        bool nativePanel = false,
      }) async {
        await settle(4);
        expect(tester.takeException(), isNull);
        await report({
          'event': 'snapshot',
          'name': name,
          'note': note,
          'nativePanel': nativePanel,
        });
      }

      Future<void> result(String id, Map<String, dynamic> data) =>
          report({'event': 'result', 'id': id, 'status': 'pass', ...data});
      try {
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setBool('forceZoom', true);
        await prefs.setInt('themeModeIndex', 1);
        await prefs.setInt('themeIndex', 0);
        await prefs.setStringList('backgroundImages', []);
        await prefs.setString('bgImgPath', '');
        await prefs.setString('backgroundFrequency', 'everyVisit');
        final conf = await InitUtil.initialize();
        final table = await tables.insert(CourseTable('匿名验证课表'));
        await prefs.setInt('tableId', table.id!);
        await WeekUtil.setNowWeek(1);
        await courses.insert(
          Course(
            table.id,
            '算法与数据结构',
            '[1,3]',
            7,
            1,
            1,
            0,
            classroom: '仙林101',
            info: '周日课程，含中文/标点;与换行\n备注',
          ),
        );
        await courses.insert(
          Course(table.id, '算法与数据结构', '[2]', 2, 3, 0, 0, classroom: '鼓楼202'),
        );
        await courses.insert(Course(table.id, '自由时间课', '[1]', 0, 0, 0, 0));
        for (var i = 0; i < 2; i++) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const size = Size(600, 1200);
          canvas.drawRect(
            Offset.zero & size,
            Paint()
              ..color =
                  i == 0 ? const Color(0xff314c75) : const Color(0xff8a5538),
          );
          canvas.drawCircle(
            const Offset(450, 300),
            240,
            Paint()
              ..color =
                  i == 0 ? const Color(0xff8bd3dd) : const Color(0xffffd89e),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(600, 1200);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${temporary.path}/qa-background-$i.png');
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          sources.add(file);
          image.dispose();
          picture.dispose();
        }
        await backgrounds.addImages(sources.map((f) => XFile(f.path)).toList());
        Future<void> home() async {
          await tester.pumpWidget(
            app.MyApp(conf[0], ThemeMode.light, conf[2], key: UniqueKey()),
          );
          await until(key('timetable-main-title'));
          await settle(12);
        }

        await home();
        final first = (await backgrounds.load()).current;
        await snap('background-first', '真实首页使用第一张匿名测试图片；图片经生产保存逻辑复制到 App 内。');
        await home();
        final second = (await backgrounds.load()).current;
        expect(second, isNot(first));
        await snap('background-next', '重新打开真实课表后随机换为另一张图片，不连续重复。');
        await result('background-visits', {
          'changed': first != second,
          'images': 2,
        });
        await tap(find.byIcon(Icons.settings));
        await tap(key('background-settings'));
        await until(find.byType(BackgroundSettingsView));
        await snap(
          'background-manager',
          '两张背景缩略图、正在使用标记、添加/移除和切换频率。相册多选交互本项未模拟。',
        );
        await tap(key('background-frequency'));
        await tap(key('background-mode-days'));
        await tester.enterText(key('background-days'), '3');
        await settle();
        await snap('frequency-days', '选择每 X 天切换，并填写3天。');
        await tap(key('save-background-frequency'));
        final configured = await backgrounds.load();
        expect(configured.frequency, BackgroundFrequency.days);
        expect(configured.days, 3);
        await snap('frequency-saved', '原生持久化后显示每3天切换；两张图片保留。');
        await result('background-frequency', {
          'mode': configured.frequency.name,
          'days': configured.days,
        });
        await tap(key('shuffle-background'));
        expect((await backgrounds.load()).current, isNot(second));
        await tap(key('remove-background-1'));
        expect((await backgrounds.load()).images, hasLength(1));
        await snap('background-removed', '移除一张图片后，剩余一张；立即换一张按钮禁用。');
        await tap(key('clear-backgrounds'));
        expect((await backgrounds.load()).images, isEmpty);
        expect((await backgrounds.load()).current, isEmpty);
        await snap('background-empty', '移除全部背景后显示空态，课表恢复主题背景。');
        await result('background-remove-clear', {'images': 0, 'current': ''});
        await tap(key('add-backgrounds'));
        await snap(
          'photo-picker',
          '实际系统相册多选面板，仅选择预置的匿名测试图片。',
          nativePanel: true,
        );
        await report({'event': 'picker-wait'});
        for (
          var i = 0;
          i < 1200 && (await backgrounds.load()).images.length < 2;
          i++
        ) {
          await settle(1);
        }
        expect((await backgrounds.load()).images, hasLength(2));
        await snap('photo-selected', '从系统相册实际多选两张图片后返回，生产页面显示两张缩略图。');
        await result('background-native-picker', {'images': 2});
        // The normal settings route is kept, no preview screen substitutes for it.
        await tap(find.byType(BackButton));
        await settle();
        await tap(find.text('导入/导出课表'));
        await snap('ics-entry', '导入/导出课表新增导出为 ICS 文件，保留已有二维码和系统日历选项。');
        await tap(key('export-ics'));
        await settle(16);
        final file = File('${temporary.path}/匿名验证课表.ics');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();
        expect('BEGIN:VEVENT'.allMatches(content), hasLength(3));
        expect(content, contains('LOCATION:仙林101'));
        expect(content, contains('DTSTART:'));
        await report({'event': 'ics-file', 'content': content, 'events': 3});
        await snap(
          'ics-share',
          '实际原生分享面板接收到 .ics 文件；未向外部账号发送。',
          nativePanel: true,
        );
        await result('ics-export', {
          'events': 3,
          'calendarPermissionRequested': false,
        });
      } finally {
        tester.platformDispatcher.clearAllTestValues();
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(2);
        await backgrounds.clear();
        for (final file in sources) {
          if (await file.exists()) await file.delete();
        }
        for (final row in await tables.getAllCourseTable()) {
          if (!beforeIds.contains(row['id'])) await tables.delete(row['id']);
        }
        for (final key in prefs.getKeys().toList()) {
          if (!previous.containsKey(key)) await prefs.remove(key);
        }
        for (final e in previous.entries) {
          final v = e.value;
          if (v is bool) await prefs.setBool(e.key, v);
          if (v is int) await prefs.setInt(e.key, v);
          if (v is double) await prefs.setDouble(e.key, v);
          if (v is String) await prefs.setString(e.key, v);
          if (v is List<String>) await prefs.setStringList(e.key, v);
        }
        await WidgetRefreshHelper.refreshAfterTableChanged();
        await report({
          'event': 'restored',
          'tableIds':
              (await tables.getAllCourseTable()).map((t) => t['id']).toList(),
          'originalTableIds': beforeIds.toList(),
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
