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
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/BackgroundImage.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/TimetableHeader.dart';
import 'package:wheretosleepinnju/Utils/BackgroundService.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

Future<void> report(Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8789'),
    );
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(
      jsonEncode({'platform': Platform.operatingSystem, ...data}),
    );
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
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
    'background return, per-picture title colors and main settings entry',
    (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final tables = CourseTableProvider(), courses = CourseProvider();
      final beforeIds =
          (await tables.getAllCourseTable()).map((r) => r['id']).toSet();
      final service = BackgroundService.instance;
      final sources = <File>[];
      Future<void> settle([int count = 8]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Finder key(String value) => find.byKey(ValueKey(value));
      Future<void> until(Finder finder) async {
        for (var i = 0; i < 120 && finder.evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(finder, findsWidgets);
      }

      Future<void> tap(Finder finder) async {
        await until(finder);
        await tester.ensureVisible(finder.first);
        await settle(2);
        await tester.tap(finder.first);
        await settle();
      }

      Future<void> snap(String name, String note) async {
        await settle(4);
        expect(tester.takeException(), isNull);
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      Future<void> result(String id, Map<String, dynamic> facts) =>
          report({'event': 'result', 'id': id, 'status': 'pass', ...facts});
      Future<void> settings() async {
        await tap(find.byIcon(Icons.settings));
        await tap(key('background-settings'));
      }

      Future<void> home() async {
        await tap(find.byType(BackButton));
        await tap(find.byType(BackButton));
        await until(key('timetable-main-title'));
        await settle(12);
      }

      Future<void> verifyHome(String image, bool white) async {
        expect((await service.load()).current, image);
        final decorations =
            tester
                .widgetList<Container>(
                  find.descendant(
                    of: find.byType(BackgroundImage),
                    matching: find.byType(Container),
                  ),
                )
                .map((w) => w.decoration)
                .whereType<BoxDecoration>()
                .toList();
        expect(
          decorations.any(
            (d) =>
                d.image?.image is FileImage &&
                (d.image!.image as FileImage).file.path == image,
          ),
          isTrue,
        );
        expect(
          tester
              .widget<TimetableHeader>(find.byType(TimetableHeader))
              .foregroundColor,
          white ? Colors.white : Colors.black,
        );
      }

      try {
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setBool('forceZoom', true);
        await prefs.setInt('themeModeIndex', 1);
        await prefs.setInt('themeIndex', 0);
        await prefs.setStringList('backgroundImages', []);
        await prefs.setString('bgImgPath', '');
        await prefs.remove('backgroundWhiteModes');
        final conf = await InitUtil.initialize();
        final table = await tables.insert(CourseTable('背景回退验证'));
        await prefs.setInt('tableId', table.id!);
        await WeekUtil.setNowWeek(6);
        await courses.insert(
          Course(table.id, '软件工程', '[6]', 1, 2, 1, 0, classroom: '仙林101'),
        );
        final temporary = await getTemporaryDirectory();
        for (var i = 0; i < 2; i++) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 600, 1200),
            Paint()
              ..color =
                  i == 0 ? const Color(0xff183153) : const Color(0xfff5f0e8),
          );
          canvas.drawCircle(
            const Offset(480, 940),
            240,
            Paint()
              ..color =
                  i == 0 ? const Color(0xff31567a) : const Color(0xffeedac1),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(600, 1200);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${temporary.path}/qa-bg-refresh-$i.png');
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          sources.add(file);
          image.dispose();
          picture.dispose();
        }
        await service.addImages(sources.map((f) => XFile(f.path)).toList());
        await service.setFrequency(BackgroundFrequency.days, 365);
        final images = (await service.load()).images;
        await tester.pumpWidget(app.MyApp(conf[0], ThemeMode.light, conf[2]));
        await until(key('timetable-main-title'));
        await settle(12);
        await verifyHome(images[0], true);
        await snap('home-dark-auto', '深色背景自动识别白色标题；截图来自真实首页。');
        await tap(find.byIcon(Icons.settings));
        await tester.ensureVisible(key('background-settings'));
        await settle();
        expect(
          tester.getTopLeft(find.text('课表管理')).dy,
          lessThan(tester.getTopLeft(key('background-settings')).dy),
        );
        expect(
          tester.getTopLeft(key('background-settings')).dy,
          lessThan(tester.getTopLeft(find.text('自定义选项')).dy),
        );
        await snap('main-settings', '课表背景位于主设置页，顺序为课表管理、课表背景、自定义选项。');
        await tap(key('background-settings'));
        await snap('settings-days', '精简文案；白色标题模式在添加图片上方；切换频率左说明右显示每365天切换。');
        await tap(key('use-background-1'));
        expect((await service.load()).whiteMode, isFalse);
        await home();
        await verifyHome(images[1], false);
        await snap('home-light-auto', '点击浅色背景后直接回退至首页，图片保持所选，标题自动变黑。');
        await result('title-auto', {
          'darkWhite': true,
          'lightWhite': false,
          'renderedFileVerified': true,
        });
        await result('settings-entry', {
          'order': ['课表管理', '课表背景', '自定义选项'],
        });
        await settings();
        await tap(key('background-frequency'));
        await snap('frequency-options', '切换频率选项：每次打开课表或每X天切换，支持填写间隔天数。');
        await tap(key('background-mode-visit'));
        await tap(key('save-background-frequency'));
        await tap(key('shuffle-background'));
        final shuffled = (await service.load()).current;
        expect(shuffled, images[0]);
        // Returning from a picker while this settings route is visible must not
        // count as another visit to the timetable underneath it.
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await settle();
        expect((await service.load()).current, shuffled);
        await snap(
          'shuffled-settings',
          '每次随机模式下点击立即换一张，当前深色图已选中；白色标题开关与这张图一致。',
        );
        await home();
        await verifyHome(shuffled, true);
        await snap('home-after-shuffle', '从背景设置连续回退到首页，仍为刚刚换到的图片，没有再次随机换回旧图。');
        await result('shuffle-return', {
          'frequency': 'everyVisit',
          'selectedImageKept': true,
          'coveredRouteResumeKept': true,
        });
        await settings();
        await tap(key('background-white-title'));
        expect((await service.load()).whiteMode, isFalse);
        await tap(key('use-background-1'));
        expect((await service.load()).whiteMode, isFalse);
        await tap(key('background-white-title'));
        expect((await service.load()).whiteMode, isTrue);
        await tap(key('use-background-0'));
        expect((await service.load()).whiteMode, isFalse);
        await snap(
          'per-image-override',
          '深色图手动改为黑字，浅色图手动改为白字，切回深色图后独立设置仍为关闭；本图仅展示设置页。',
        );
        final reopened = BackgroundService();
        await reopened.selectImage(images[1]);
        expect((await reopened.load()).whiteMode, isTrue);
        await reopened.selectImage(images[0]);
        expect((await reopened.load()).whiteMode, isFalse);
        await result('title-per-image', {
          'darkOverride': false,
          'lightOverride': true,
          'serviceRestartRetained': true,
        });
        // Leave a readable dark/white selection before cleanup.
        await service.setWhiteMode(true);
        await tap(key('clear-backgrounds'));
        await snap('empty-settings', '空态仅显示还没有背景图片；不再显示补充介绍和自动切换长说明。');
      } finally {
        tester.platformDispatcher.clearAllTestValues();
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(2);
        await service.clear();
        for (final file in sources) {
          if (await file.exists()) await file.delete();
        }
        for (final row in await tables.getAllCourseTable()) {
          if (!beforeIds.contains(row['id'])) await tables.delete(row['id']);
        }
        for (final k in prefs.getKeys().toList()) {
          if (!previous.containsKey(k)) await prefs.remove(k);
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
        final afterIds =
            (await tables.getAllCourseTable()).map((r) => r['id']).toSet();
        expect(afterIds, beforeIds);
        await report({
          'event': 'restored',
          'tableIds': afterIds.toList(),
          'originalTableIds': beforeIds.toList(),
        });
      }
    },
  );
}
