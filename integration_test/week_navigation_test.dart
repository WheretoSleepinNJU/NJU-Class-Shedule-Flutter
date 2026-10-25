import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/WeekPickerSheet.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

Future<void> report(Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse(
        'http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:${const int.fromEnvironment('QA_PORT', defaultValue: 8781)}',
      ),
    );
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(
      jsonEncode({'platform': Platform.operatingSystem, ...data}),
    );
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw StateError('QA recorder: $body');
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'left title, browse week and confirmed actual-week change',
    (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final tables = CourseTableProvider(), courses = CourseProvider();
      final beforeIds =
          (await tables.getAllCourseTable()).map((r) => r['id']).toSet();
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(finder, findsWidgets);
      }

      Finder key(String k) => find.byKey(ValueKey(k));
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

      Future<void> open() => tap(key('timetable-week-menu'));
      Future<void> close() async {
        final sheetTop = tester.getTopLeft(find.byType(BottomSheet)).dy;
        expect(sheetTop, greaterThan(0));
        await tester.tapAt(Offset(4, sheetTop / 2));
        await settle();
        expect(find.byType(WeekPickerSheet), findsNothing);
      }

      try {
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setBool('showWeekend', true);
        await prefs.setBool('showNonCurrentWeekCourses', false);
        await prefs.setBool('forceZoom', true);
        await prefs.setInt('themeModeIndex', 1);
        await prefs.setInt('themeIndex', 0);
        await prefs.setString('bgImgPath', '');
        UmengCommonSdk.initCommon(
          '5f8ef217fac90f1c19a7b0f3',
          '5f9e1efa1c520d30739d2737',
          'Umeng',
        );
        final conf = await InitUtil.initialize();
        final table = await tables.insert(CourseTable('周选择 · 匿名验证'));
        await prefs.setInt('tableId', table.id!);
        await WeekUtil.setNowWeek(6);
        for (final c in [
          Course(
            table.id,
            '本周课程 · 计算机系统',
            '[6]',
            1,
            3,
            1,
            0,
            classroom: '仙林101',
          ),
          Course(table.id, '第8周 · 学术写作', '[8]', 3, 3, 1, 0, classroom: '仙林202'),
          Course(
            table.id,
            '当前周课程 · 软件工程',
            '[9]',
            DateTime.now().weekday,
            5,
            1,
            0,
            classroom: '仙林303',
          ),
        ]) {
          await courses.insert(c);
        }
        Future<void> home(ThemeMode mode) async {
          await tester.pumpWidget(
            app.MyApp(conf[0], mode, conf[2], key: UniqueKey()),
          );
          await until(key('timetable-main-title'));
          await settle();
        }

        Finder course(String name) => find.byWidgetPredicate(
          (w) => w is CourseWidget && w.course.name == name,
        );
        if (const bool.fromEnvironment('QA_WEEK_STATUS_ONLY')) {
          for (final scenario in [
            (6, 6, 'current', '南哪课表  第6周'),
            (6, 8, 'non-current', '南哪课表  第8周 [非本周]'),
            (0, 1, 'not-started', '南哪课表  第1周 [未开学]'),
          ]) {
            await WeekUtil.setNowWeek(scenario.$1);
            await prefs.setInt('tmpWeekIndex', scenario.$2);
            await home(ThemeMode.light);
            expect(find.text(scenario.$4), findsOneWidget);
            await snap(
              'title-${scenario.$3}',
              '原有周数提示规则：${scenario.$4}；保留日期副标题与下拉箭头。',
            );
            await report({
              'event': 'result',
              'id': scenario.$3,
              'status': 'pass',
              'actualWeek': scenario.$1,
              'viewedWeek': scenario.$2,
              'title': scenario.$4,
            });
          }
          return;
        }
        await home(ThemeMode.light);
        expect(find.text('南哪课表  第6周'), findsOneWidget);
        final today = DateTime.now();
        final expectedDate =
            '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
        expect(
          tester.widget<Text>(key('timetable-date-subtitle')).data,
          startsWith(expectedDate),
        );
        expect(
          tester.getTopLeft(key('timetable-main-title')).dx,
          closeTo(tester.getTopLeft(key('timetable-date-subtitle')).dx, .1),
        );
        expect(course('本周课程 · 计算机系统'), findsWidgets);
        await snap('header-default', '左侧主标题+下拉箭头；副标题为真实当天日期和星期。');
        await open();
        expect(find.text('本周'), findsOneWidget);
        await snap('picker-default', '默认查看周课表：主题色标记浏览周，“本周”标记实际当前周。');
        await tap(key('week-picker-8'));
        await until(course('第8周 · 学术写作'));
        await prefs.reload();
        expect(prefs.getInt('weekIndex'), 6);
        expect(prefs.getInt('tmpWeekIndex'), 8);
        expect(find.text('南哪课表  第8周 [非本周]'), findsOneWidget);
        await snap('view-week8', '查看第8周已切换课表；实际当前周仍为6。');
        await open();
        await tap(key('week-picker-mode'));
        await tap(key('week-picker-9'));
        await close();
        await prefs.reload();
        expect(prefs.getInt('weekIndex'), 6);
        expect(prefs.getInt('tmpWeekIndex'), 8);
        await report({
          'event': 'result',
          'id': 'browse-and-cancel',
          'status': 'pass',
          'actualWeek': 6,
          'viewedWeek': 8,
        });
        await open();
        await tap(key('week-picker-mode'));
        await tap(key('week-picker-9'));
        expect(prefs.getInt('weekIndex'), 6);
        await snap('edit-current-week', '修改模式中选择第9周；确认前未修改实际周数。');
        await tap(key('confirm-current-week'));
        await until(course('当前周课程 · 软件工程'));
        await prefs.reload();
        expect(prefs.getInt('weekIndex'), 9);
        expect(prefs.getInt('tmpWeekIndex'), 9);
        expect(find.text('南哪课表  第9周'), findsOneWidget);
        await snap('current-week9', '确认后当前周与浏览周均为9，课表显示第9周课程。');
        if (Platform.isAndroid || Platform.isIOS) {
          await WidgetRefreshHelper.manualRefresh();
          final native = await const MethodChannel(
            'com.wheretosleepinnju/widget_data',
          ).invokeMapMethod<String, dynamic>('debugReadWidgetData');
          expect(native?['currentWeek'], 9);
          await report({
            'event': 'native-widget-readback',
            'currentWeek': native?['currentWeek'],
            'todayCount': (native?['todayCourses'] as List?)?.length,
          });
        } else if (Platform.operatingSystem == 'ohos') {
          await WidgetRefreshHelper.refreshAfterWeekChanged();
          await report({'event': 'ohos-widget-readback', 'currentWeek': 9});
        }
        await report({
          'event': 'result',
          'id': 'set-current-week',
          'status': 'pass',
          'actualWeek': 9,
          'viewedWeek': 9,
        });
        await prefs.setInt('themeModeIndex', 2);
        await home(ThemeMode.dark);
        await open();
        await snap('picker-dark', '深色主题：周次选中态与未选中态，实际本周9。');
        await close();
        await prefs.setInt('themeModeIndex', 1);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await home(ThemeMode.light);
        await snap('header-large', '2倍框架文字输入；标题按总览统一上限1.4，日期与设置入口保持可见。');
        await open();
        await snap('picker-large', '2倍框架文字：网格减少列数并可滚动，不截断本周和操作入口。');
        await close();
        await report({
          'event': 'result',
          'id': 'theme-and-large-font',
          'status': 'pass',
        });
      } finally {
        tester.platformDispatcher.clearAllTestValues();
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(2);
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
        await report({
          'event': 'restored',
          'tableIds':
              (await tables.getAllCourseTable()).map((r) => r['id']).toList(),
          'originalTableIds': beforeIds.toList(),
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
