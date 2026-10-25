import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:azlistview/azlistview.dart';
import 'package:wheretosleepinnju/Resources/Constant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportView.dart';
import 'package:wheretosleepinnju/Utils/BackgroundService.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('capture current production screens with fictional store data', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
    final device =
        Platform.operatingSystem == 'ohos'
            ? 'harmony'
            : (tester.view.physicalSize.width > 1800 ? 'ipad' : 'iphone');
    final prefs = await SharedPreferences.getInstance();
    final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final tables = CourseTableProvider(), courses = CourseProvider();
    final beforeIds =
        (await tables.getAllCourseTable()).map((r) => r['id']).toSet();
    final backgrounds = BackgroundService.instance;
    final sources = <File>[];
    Future<void> report(Map<String, dynamic> data) async {
      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:8791'),
        );
        final bytes = utf8.encode(jsonEncode({'device': device, ...data}));
        request.headers.contentType = ContentType.json;
        request.contentLength = bytes.length;
        request.add(bytes);
        final response = await request.close();
        await response.drain<void>();
        expect(response.statusCode, 200);
      } finally {
        client.close();
      }
    }

    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Finder key(String k) => find.byKey(ValueKey(k));
    Future<void> until(Finder finder) async {
      for (var i = 0; i < 240 && finder.evaluate().isEmpty; i++) {
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

    Future<void> snap(String name) async {
      await settle(8);
      expect(tester.takeException(), isNull);
      await report({
        'event': 'snapshot',
        'name': name,
        'physicalSize': [
          tester.view.physicalSize.width,
          tester.view.physicalSize.height,
        ],
        'fictionalData': true,
      });
    }

    try {
      await prefs.setInt('privacyVersion', 1000000);
      await prefs.setBool('hasShowReview', true);
      await prefs.setBool('forceZoom', true);
      await prefs.setInt('themeModeIndex', 1);
      await prefs.setInt('themeIndex', 0);
      await prefs.setBool('showWeekend', true);
      await prefs.setBool('showNonCurrentWeekCourses', false);
      await prefs.setStringList('backgroundImages', []);
      await prefs.setString('bgImgPath', '');
      await prefs.remove('backgroundWhiteModes');
      final conf = await InitUtil.initialize();
      final table = await tables.insert(
        CourseTable(
          '2026 秋季学期',
          data: jsonEncode({
            'class_time_list': Constant.CLASS_TIME_LIST.take(10).toList(),
          }),
        ),
      );
      await prefs.setInt('tableId', table.id!);
      await WeekUtil.setNowWeek(8);
      final weeks = jsonEncode(List.generate(16, (i) => i + 1));
      final specs = <List<dynamic>>[
        ['高等数学', 1, 1, 1, '仙林201', '#5E86CB', 101, '林老师', '每周两次，循序渐进。'],
        ['高等数学', 3, 3, 1, '仙林201', '#5E86CB', 101, '林老师', '每周两次，循序渐进。'],
        ['大学英语', 1, 5, 1, '仙林105', '#6BA49A', 102, '陈老师', ''],
        ['数据结构', 1, 9, 1, '仙林301', '#B587BE', 103, '周老师', ''],
        ['程序设计', 2, 1, 2, '仙林302', '#E0A06B', 104, '吴老师', '带上电脑，一起动手实践。'],
        ['线性代数', 2, 6, 1, '仙林203', '#8F9F64', 105, '杨老师', ''],
        ['艺术鉴赏', 2, 9, 1, '逸夫楼', '#C17E93', 106, '赵老师', ''],
        ['大学物理', 3, 1, 1, '仙林205', '#6CA4BA', 107, '李老师', ''],
        ['体育', 3, 7, 1, '运动场', '#B9A365', 108, '王老师', ''],
        ['学术写作', 4, 1, 1, '图书馆', '#B587BE', 109, '周老师', ''],
        ['数据结构', 4, 5, 1, '仙林301', '#B587BE', 103, '周老师', ''],
        ['大学英语', 4, 9, 1, '仙林105', '#6BA49A', 102, '陈老师', ''],
        ['大学物理', 5, 3, 1, '仙林205', '#6CA4BA', 107, '李老师', ''],
        ['思政理论', 5, 7, 1, '仙林206', '#C17E93', 110, '何老师', ''],
        ['读书分享', 6, 3, 1, '图书馆', '#8F9F64', 111, '许老师', ''],
        ['社团活动', 7, 7, 1, '活动中心', '#E0A06B', 112, '', ''],
      ];
      for (final c in specs) {
        await courses.insert(
          Course(
            table.id,
            c[0],
            weeks,
            c[1],
            c[2],
            c[3],
            1,
            classroom: c[4],
            color: c[5],
            courseId: c[6],
            teacher: c[7],
            classNumber: 'DEMO-${c[6]}',
            info: c[8],
          ),
        );
      }
      await tester.pumpWidget(app.MyApp(conf[0], ThemeMode.light, conf[2]));
      await until(key('timetable-main-title'));
      await settle(16);
      await snap('01-overview');
      await tap(key('timetable-week-menu'));
      await snap('extra-week-picker');
      await tester.tapAt(const Offset(8, 80));
      await settle();
      final math = find.byWidgetPredicate(
        (w) => w is CourseWidget && w.course.name == '高等数学',
      );
      await tap(math.first);
      await until(find.text('编辑'));
      await snap('03-details');
      await tap(find.text('编辑'));
      await until(find.byType(EditCourseView));
      await snap('04-editor');
      await tap(find.byType(BackButton));
      await until(key('timetable-main-title'));
      await tap(find.byIcon(Icons.settings));
      await tap(find.text('导入课程表'));
      await until(find.byType(ImportView));
      await until(find.byType(AzListView));
      await snap('02-import');
      await tap(find.byType(BackButton));
      final temp = await getTemporaryDirectory();
      for (var i = 0; i < 2; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const rect = Rect.fromLTWH(0, 0, 600, 1400);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  i == 0
                      ? [
                        const Color(0xff123057),
                        const Color(0xff526F9E),
                        const Color(0xff91B5C7),
                      ]
                      : [const Color(0xfff6ecdd), const Color(0xffd7c2a9)],
            ).createShader(rect),
        );
        canvas.drawCircle(
          const Offset(540, 1140),
          340,
          Paint()
            ..color = (i == 0
                    ? const Color(0xffABCBDC)
                    : const Color(0xffe9cfb4))
                .withValues(alpha: .35),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(600, 1400);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${temp.path}/store-background-$i.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        sources.add(file);
        image.dispose();
        picture.dispose();
      }
      await backgrounds.addImages(sources.map((f) => XFile(f.path)).toList());
      await backgrounds.setFrequency(BackgroundFrequency.days, 1);
      await tap(key('background-settings'));
      await snap('extra-background-settings');
      await tap(find.byType(BackButton));
      await tap(find.byType(BackButton));
      await until(key('timetable-main-title'));
      await settle(12);
      await snap('05-background');
      await report({
        'event': 'complete',
        'screens': 7,
        'courseMeetings': specs.length,
      });
    } finally {
      tester.platformDispatcher.clearAllTestValues();
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(2);
      await backgrounds.clear();
      for (final file in sources) {
        if (await file.exists()) await file.delete();
      }
      for (final r in await tables.getAllCourseTable()) {
        if (!beforeIds.contains(r['id'])) await tables.delete(r['id']);
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
  });
}
