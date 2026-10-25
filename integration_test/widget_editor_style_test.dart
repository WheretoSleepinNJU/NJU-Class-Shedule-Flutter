import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/ManageTable/ManageTableView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';
import 'package:wheretosleepinnju/core/widget_data/services/unified_data_service.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'course_edit_test.dart' show report;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'native widget, editor weeks and table selection',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final tables = CourseTableProvider(), courses = CourseProvider();
      // Actual SQLite courses feed the production Flutter -> native widget bridge.
      final periods = [
        for (var i = 0; i < 12; i++)
          {
            'start': '${(8 + i).toString().padLeft(2, '0')}:00',
            'end': '${(8 + i).toString().padLeft(2, '0')}:50',
          },
      ];
      final a = await tables.insert(
        CourseTable(
          '本学期 · 匿名验证',
          data: jsonEncode({'class_time_list': periods}),
        ),
      );
      final b = await tables.insert(CourseTable('下学期 · 匿名验证'));
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> page(Widget child, {bool dark = false}) async {
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: MainStateModel(),
            child: MaterialApp(
              key: UniqueKey(),
              theme: AppThemes.build(
                '#0095F9',
                dark ? Brightness.dark : Brightness.light,
                useSeedScheme: false,
              ),
              locale: const Locale('zh', 'CN'),
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: child,
            ),
          ),
        );
        await settle(16);
      }

      Future<void> snap(String name, String note) async {
        await settle(4);
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      try {
        await prefs.setInt('tableId', a.id!);
        await ColorPool.shuffleColorPool();
        await WeekUtil.setNowWeek(1);
        final rows = <Course>[];
        for (var i = 1; i <= 12; i++) {
          rows.add(
            await courses.insert(
              Course(
                a.id,
                '验证课程 ${i.toString().padLeft(2, '0')}',
                '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]',
                DateTime.now().weekday,
                i,
                0,
                1,
                courseId: 1800 + i,
                teacher: '测试老师',
                classroom: '仙林 ${100 + i}',
                color: '#0095F9',
              ),
            ),
          );
        }
        for (final scale in [1, 2]) {
          if (scale == 2 && !(Platform.isAndroid || Platform.isIOS)) continue;
          await report({'event': 'font', 'scale': scale});
          await page(EditCourseView(course: rows.first));
          Finder week(int n) => find.byKey(ValueKey('edit-week-$n'));
          final width = tester.getSize(week(1)).width;
          for (final n in [2, 7, 9, 10, 20, 25]) {
            expect(tester.getSize(week(n)).width, width);
          }
          await Scrollable.ensureVisible(
            tester.element(week(10)),
            alignment: .5,
          );
          await settle();
          await tester.tap(week(10));
          await settle();
          expect(tester.widget<FilterChip>(week(10)).selected, isFalse);
          expect(tester.getSize(week(10)).width, width);
          expect(find.text('自由时间/时间待定'), findsOneWidget);
          await snap(
            'editor-weeks-$scale',
            '周次单、双位数字等宽，取消第 10 周后宽度不变；自由时间/时间待定新文案。',
          );
          expect(tester.takeException(), isNull);
        }
        await report({'event': 'font', 'scale': 1});
        await page(const ManageTableView(), dark: true);
        final second = find.text(b.name!);
        await tester.ensureVisible(second);
        await settle();
        await snap(
          'table-dark-selected-a',
          '深色模式：当前课表有主题底色、加粗文字和勾选标记，其他课表保持普通背景。',
        );
        await tester.tap(second);
        await settle(20);
        expect(prefs.getInt('tableId'), b.id);
        final selected = find.ancestor(
          of: second,
          matching: find.byType(ListTile),
        );
        expect(tester.widget<ListTile>(selected).selected, isTrue);
        await snap('table-dark-selected-b', '切换至另一课表后，主题底色和勾选标记同步移动。');
        expect(tester.takeException(), isNull);
        await report({
          'event': 'result',
          'id': 'editor-style',
          'status': 'pass',
          'checks': [
            'week widths equal for 1 and 2 digits',
            'toggle retains width',
            'free / pending label',
            'dark selected row',
            'selection and preferences change together',
          ],
        });
        if (Platform.isAndroid) {
          await prefs.setInt('tableId', a.id!);
          final data =
              await UnifiedDataService(preferences: prefs).getWidgetData();
          expect(data.todayCourses.length, rows.length);
          expect(await WidgetRefreshHelper.manualRefresh(), isTrue);
          await report({'event': 'widget-ready', 'courseCount': rows.length});
        }
      } finally {
        await report({'event': 'font', 'scale': 1});
        await tester.pumpWidget(const SizedBox.shrink());
        await tables.delete(a.id!);
        await tables.delete(b.id!);
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
        await WidgetRefreshHelper.manualRefresh();
        await report({'event': 'complete'});
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
