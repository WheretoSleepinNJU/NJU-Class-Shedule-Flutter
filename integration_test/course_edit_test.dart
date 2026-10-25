import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';

Future<void> report(Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('http://127.0.0.1:8769'));
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(
      jsonEncode({'platform': Platform.operatingSystem, ...data}),
    );
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode != 200) {
      throw StateError('Screenshot recorder failed');
    }
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'course cards and editing persist through the real UI',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final original = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final tables = CourseTableProvider();
      final provider = CourseProvider();
      final table = await tables.insert(CourseTable('课程编辑 · 匿名验证'));
      final rows = <Course>[];
      Future<void> settle([int count = 8]) async {
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
        await tester.tap(finder.first);
        await settle();
      }

      Future<void> snapshot(String name, String note) async {
        await settle(4);
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      Finder courseTile(int id) => find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is CourseWidget && widget.course.id == id,
        ),
        matching: find.byType(InkWell),
      );
      final overlappingTile = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is CourseWidget &&
              widget.course.weekTime == 2 &&
              widget.course.startTime == 3,
        ),
        matching: find.byType(InkWell),
      );
      Future<void> scrollTo(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          220,
          scrollable:
              find
                  .descendant(
                    of: find.byType(EditCourseView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
        );
        await settle();
      }

      Future<void> enter(Finder finder, String value) async {
        if (Platform.operatingSystem != 'ohos') {
          await tester.enterText(finder, value);
          return;
        }
        // The Harmony IME can replay its previous value after TestTextInput
        // injection. Use the SDK's native input path instead.
        await tap(finder);
        final editable = find.descendant(
          of: finder,
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(editable);
        await settle();
        final point = tester.getCenter(editable);
        final ratio = tester.view.devicePixelRatio;
        await report({
          'event': 'native-input',
          'x': (point.dx * ratio).round(),
          'y': (point.dy * ratio).round(),
          'text': value,
        });
        await settle();
        expect(tester.widget<EditableText>(editable).controller.text, value);
      }

      try {
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setInt('tableId', table.id!);
        await prefs.setBool('showWeekend', true);
        await prefs.setBool('forceZoom', true);
        await prefs.setBool('showNonCurrentWeekCourses', true);
        await prefs.setInt('themeModeIndex', 1);
        await WeekUtil.setNowWeek(1);
        UmengCommonSdk.initCommon(
          '5f8ef217fac90f1c19a7b0f3',
          '5f9e1efa1c520d30739d2737',
          'Umeng',
        );
        final conf = await InitUtil.initialize();
        for (final course in [
          Course(
            table.id,
            '离散数学',
            '[1,3,7]',
            2,
            3,
            1,
            1,
            teacher: '测试教师',
            classroom: '仙林教学楼 101',
            info: '课堂讨论与习题实践',
            color: '#8EB5C9',
            courseId: 100,
            classNumber: 'QA-CS001',
            link: 'https://example.edu/course/fixture',
            testTime: '原考试信息',
            testLocation: '原考试地点',
          ),
          Course(
            table.id,
            '一个特别特别长的课程名称与课堂讨论实践',
            '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]',
            2,
            3,
            1,
            1,
            courseId: 101,
          ),
          Course(
            table.id,
            '跨学科专题研讨',
            '[1,2,3]',
            2,
            3,
            1,
            0,
            classroom: '鼓楼校区 202',
            courseId: 102,
          ),
          Course(
            table.id,
            '高等数学',
            '[1,2,3]',
            4,
            5,
            1,
            1,
            classroom: '仙林教学楼 301',
            courseId: 103,
          ),
        ]) {
          rows.add(await provider.insert(course));
        }
        final untouched = (await provider.getCourse(rows.last.id!))!.toMap();
        Future<void> home(ThemeMode mode) async {
          await prefs.setInt('themeModeIndex', mode == ThemeMode.dark ? 2 : 1);
          await tester.pumpWidget(
            app.MyApp(conf[0], mode, conf[2], key: UniqueKey()),
          );
          await until(find.byType(CourseWidget));
          await settle();
        }

        await home(ThemeMode.light);
        await tap(overlappingTile);
        await until(find.byType(CourseDetailCard));
        expect(find.byType(CourseDetailCard), findsNWidgets(3));
        await snapshot('cards-light', '三门同时间课程纵向排列；长标题换行，每张卡片独立编辑。');
        await tap(find.byKey(ValueKey('edit-course-${rows.first.id}')));
        await until(find.byType(EditCourseView));
        await snapshot('editor-filled', '课程名称、老师、地点、备注和不连续周次回填。');
        for (final entry
            in {
              'name': '离散数学（已编辑）',
              'teacher': '张老师',
              'classroom': '仙林教学楼 305',
              'info': '已通过编辑页面保存',
            }.entries) {
          await enter(
            find.byKey(ValueKey('edit-course-${entry.key}')),
            entry.value,
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
        await scrollTo(find.byKey(const ValueKey('edit-week-3')));
        await tap(find.byKey(const ValueKey('edit-week-3')));
        await tap(find.byKey(const ValueKey('edit-week-5')));
        await scrollTo(find.byKey(const ValueKey('edit-day-2')));
        await tap(find.byKey(const ValueKey('edit-day-2')));
        await tap(find.text('周三').last);
        await scrollTo(find.byKey(const ValueKey('edit-start-3')));
        await tap(find.byKey(const ValueKey('edit-start-3')));
        await tap(find.textContaining('14:00-14:50').last);
        await scrollTo(find.byKey(const ValueKey('edit-end-5')));
        await tap(find.byKey(const ValueKey('edit-end-5')));
        await tap(find.textContaining('15:00-15:50').last);
        await snapshot('editor-schedule', '任意选周从 1/3/7 改为 1/5/7，并修改为周三第5–6节。');
        await tap(find.byKey(const ValueKey('save-course')));
        await until(courseTile(rows.first.id!));
        final saved = (await provider.getCourse(rows.first.id!))!;
        expect(saved.name, '离散数学（已编辑）');
        expect(saved.teacher, '张老师');
        expect(saved.classroom, '仙林教学楼 305');
        expect(saved.weekNumbers, [1, 5, 7]);
        expect(saved.weekTime, 3);
        expect(saved.startTime, 5);
        expect(saved.timeCount, 1);
        expect(saved.tableId, table.id);
        expect(saved.courseId, 100);
        expect(saved.importType, 1);
        expect(saved.color, '#8EB5C9');
        expect(saved.classNumber, 'QA-CS001');
        expect(saved.link, rows.first.link);
        expect(saved.testTime, rows.first.testTime);
        expect((await provider.getAllCourses(table.id!)).length, 4);
        expect((await provider.getCourse(rows.last.id!))!.toMap(), untouched);
        await snapshot(
          'saved-timetable',
          '保存后课表立即更新；编辑记录移动到周三第5–6节，原冲突由3门变2门。',
        );
        await tap(courseTile(rows.first.id!));
        await snapshot('saved-details', '重新打开详情显示修改后的字段、任意周次和实际时钟区间。');
        await tap(find.byKey(ValueKey('edit-course-${rows.first.id}')));
        await enter(find.byKey(const ValueKey('edit-course-name')), '这次修改应取消');
        await tap(find.byType(BackButton));
        expect((await provider.getCourse(rows.first.id!))!.name, saved.name);
        await report({
          'event': 'result',
          'id': 'edit-persistence',
          'status': 'pass',
          'readback': saved.toMap(),
        });
        await home(ThemeMode.dark);
        await tap(overlappingTile);
        await snapshot('cards-dark', '深色主题下的重叠课程卡片与独立编辑入口。');
        await tap(find.byKey(const ValueKey('course-detail-dismiss-hint')));
        await home(ThemeMode.light);
        if (Platform.isAndroid || Platform.isIOS) {
          await report({'event': 'font', 'scale': 2});
          await settle(16);
          await tap(courseTile(rows.first.id!));
          final scale =
              MediaQuery.textScalerOf(
                tester.element(find.byType(CourseDetailCard)),
              ).scale(16) /
              16;
          expect(scale, greaterThan(1));
          await snapshot('cards-large', '通过系统设置放大字体，详情卡片同步放大且操作可用。');
          await tap(find.byKey(ValueKey('edit-course-${rows.first.id}')));
          await snapshot('editor-large', '系统大字号下编辑表单与保存按钮可用。');
          expect(tester.takeException(), isNull);
          await report({
            'event': 'result',
            'id': 'system-large-font',
            'status': 'pass',
            'scale': scale,
          });
        }
        await report({
          'event': 'result',
          'id': 'course-cards',
          'status': 'pass',
        });
      } catch (error) {
        await snapshot('failure', error.toString());
        await report({
          'event': 'result',
          'id': 'course-edit',
          'status': 'fail',
          'error': error.toString(),
        });
        rethrow;
      } finally {
        await report({'event': 'font', 'scale': 1});
        await tester.pumpWidget(const SizedBox());
        await settle(2);
        await provider.deleteByTable(table.id!);
        await tables.delete(table.id!);
        for (final key in prefs.getKeys().toList()) {
          if (!original.containsKey(key)) await prefs.remove(key);
        }
        for (final entry in original.entries) {
          final value = entry.value;
          if (value is bool) await prefs.setBool(entry.key, value);
          if (value is int) await prefs.setInt(entry.key, value);
          if (value is double) await prefs.setDouble(entry.key, value);
          if (value is String) await prefs.setString(entry.key, value);
          if (value is List<String>) {
            await prefs.setStringList(entry.key, value);
          }
        }
        await report({'event': 'complete'});
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
