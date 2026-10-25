import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/CourseTableView.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

const _channel = MethodChannel('com.wheretosleepinnju/widget_data');
const _port = int.fromEnvironment('QA_WIDGET_RECORDER', defaultValue: 8776);
Future<Map> record(Map data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:$_port/event'),
    );
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(jsonEncode(data));
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    return jsonDecode(await utf8.decoder.bind(response).join()) as Map;
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'Sunday course added through editor reaches the real App Group',
    (tester) async {
      expect(Platform.isIOS, isTrue);
      expect(
        DateTime.now().weekday,
        7,
        reason: 'Run on a real Sunday; do not change the host clock',
      );
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final tables = CourseTableProvider();
      final courses = CourseProvider();
      final now = DateTime.now();
      String timeAfter(int minutes) {
        final d = now.add(Duration(minutes: minutes));
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }

      final table = await tables.insert(
        CourseTable(
          '周日小组件 · 匿名验证',
          data: jsonEncode({
            'class_time_list': [
              {'start': timeAfter(60), 'end': timeAfter(110)},
            ],
          }),
        ),
      );
      Future<void> settle([int count = 6]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
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

      Future<Map<String, dynamic>> read() async => Map<String, dynamic>.from(
        (await _channel.invokeMapMethod<String, dynamic>(
          'debugReadWidgetData',
        ))!,
      );
      Future<void> pause(String phase, Map<String, dynamic> payload) async {
        await record({'event': 'stage', 'phase': phase, 'payload': payload});
        if (!const bool.fromEnvironment('QA_WIDGET_NATIVE_PAUSE')) return;
        for (var i = 0; i < 480; i++) {
          final status = await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(seconds: 2));
            return record({'event': 'poll', 'phase': phase});
          });
          if (status?['done'] == true) break;
        }
      }

      try {
        await prefs.setInt('tableId', table.id!);
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setBool('showWeekend', true);
        await prefs.setBool('addButton', true);
        await prefs.setBool('showNonCurrentWeekCourses', false);
        await prefs.setInt('widgetTomorrowPreviewHour', 23);
        await WeekUtil.setNowWeek(6);
        await courses.insert(Course(table.id, '仅下周日对照', '[7]', 7, 1, 0, 0));
        await courses.insert(Course(table.id, '下周一对照', '[7]', 1, 1, 0, 0));
        app.main();
        await until(find.byType(CourseTableView));
        await until(find.byIcon(Icons.add));
        await settle(12);
        expect(
          await WidgetRefreshHelper.manualRefresh(),
          isTrue,
          reason: 'The simulator app must have real App Group entitlements',
        );
        final before = await read();
        expect(before['currentWeekDay'], 7);
        expect(before['currentWeek'], 6);
        expect(before['todayCourses'], isEmpty);
        await pause('before-add', before);
        await tap(find.byIcon(Icons.add));
        await until(find.byType(EditCourseView));
        await tester.enterText(
          find.byKey(const ValueKey('edit-course-name')),
          '周日新增课程',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
        await tap(find.text(S.current.clear_selection));
        await tap(find.byKey(const ValueKey('edit-week-6')));
        await tap(find.byKey(const ValueKey('edit-day-1')));
        await tap(find.text('周日').last);
        await tap(find.byKey(const ValueKey('save-course')));
        await until(find.byType(CourseTableView));
        await settle(8);
        final after = await read();
        final today = after['todayCourses'] as List;
        expect(today.map((c) => c['name']), ['周日新增课程']);
        expect(today.single['weekDay'], 7);
        expect(today.single['weeks'], [6]);
        expect(after['currentWeek'], 6);
        expect(after['currentWeekDay'], 7);
        expect((after['tomorrowCourses'] as List).map((c) => c['name']), [
          '下周一对照',
        ]);
        expect(after['hasCoursesToday'], isTrue);
        expect((await courses.getAllCourses(table.id!)).length, 3);
        await pause('after-add', after);
        expect(tester.takeException(), isNull);
        await record({
          'event': 'result',
          'status': 'pass',
          'realEditor': true,
          'realAppGroupRoundTrip': true,
          'todayCount': today.length,
          'weekday': 7,
          'currentWeek': 6,
          'sameWeekSundayOnly': true,
          'nextWeekMondayPreview': true,
        });
      } finally {
        await tester.pumpWidget(const SizedBox());
        await settle(2);
        await tables.delete(table.id!);
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
        WidgetRefreshHelper.clearCache();
        await WidgetRefreshHelper.manualRefresh();
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
