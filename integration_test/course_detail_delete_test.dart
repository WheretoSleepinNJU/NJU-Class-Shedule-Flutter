import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart'
    show CourseTable, CourseTableProvider;
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'course_edit_test.dart' show report;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'blank dismissal, uniform card actions and whole-course deletion',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final provider = CourseProvider(), tables = CourseTableProvider();
      final table = await tables.insert(CourseTable('详情关闭与删除 · 匿名验证'));
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder f) async {
        for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(f, findsWidgets);
      }

      Future<void> tap(Finder f) async {
        await until(f);
        await tester.ensureVisible(f.first);
        await settle(2);
        await tester.tap(f.first);
        await settle();
      }

      Finder key(String s) => find.byKey(ValueKey(s));
      Future<void> snap(String name, String note) async {
        await settle(4);
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      Finder tile(int day, int start) => find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is CourseWidget &&
              w.course.weekTime == day &&
              w.course.startTime == start,
        ),
        matching: find.byType(InkWell),
      );
      try {
        await prefs.setInt('privacyVersion', 1000000);
        await prefs.setBool('hasShowReview', true);
        await prefs.setInt('tableId', table.id!);
        await prefs.setBool('showWeekend', true);
        await prefs.setBool('forceZoom', true);
        await prefs.setBool('showNonCurrentWeekCourses', true);
        await prefs.setInt('themeModeIndex', 1);
        await prefs.setInt('themeIndex', 0);
        await WeekUtil.setNowWeek(1);
        UmengCommonSdk.initCommon(
          '5f8ef217fac90f1c19a7b0f3',
          '5f9e1efa1c520d30739d2737',
          'Umeng',
        );
        final conf = await InitUtil.initialize();
        final rows = <Course>[];
        for (final c in [
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,3,7]',
            2,
            3,
            1,
            1,
            courseId: 1601,
            classNumber: 'QA-CS001',
            teacher: '理论课教师',
            classroom: '仙林 101',
          ),
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,2,5,7]',
            5,
            5,
            1,
            1,
            courseId: 1601,
            classNumber: 'QA-CS001',
            teacher: '研讨课教师',
            classroom: '鼓楼 202',
          ),
          Course(
            table.id,
            '一个特别特别长的课程名称与课堂讨论实践',
            '[2,4,6]',
            2,
            3,
            1,
            0,
            courseId: 1602,
            classroom: '仙林 305',
          ),
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,3]',
            4,
            5,
            1,
            1,
            courseId: 1601,
            classNumber: 'QA-OTHER',
            teacher: '另一教学班教师',
          ),
        ]) {
          rows.add(await provider.insert(c));
        }
        final originals = rows.take(2).toList();
        final untouched = rows.skip(2).map((c) => c.toMap()).toList();
        await provider.db!.execute(
          'CREATE TRIGGER qa_delete_abort BEFORE DELETE ON $tableName WHEN OLD.$columnId = ${rows[1].id} BEGIN SELECT RAISE(ABORT, \'QA delete rollback\'); END',
        );
        try {
          await expectLater(
            provider.deleteMeetingGroup(originals),
            throwsA(isA<Exception>()),
          );
          expect(
            (await provider.getMeetings(
              rows.first,
            )).map((c) => c.toMap()).toList(),
            originals.map((c) => c.toMap()).toList(),
          );
        } finally {
          await provider.db!.execute('DROP TRIGGER IF EXISTS qa_delete_abort');
        }
        await provider.update(
          Course.fromMap(rows[1].toMap())..classroom = '并发更新的教室',
        );
        expect(await provider.deleteMeetingGroup(originals), isFalse);
        await provider.update(rows[1]);
        expect(await provider.deleteMeetingGroup([]), isFalse);
        await report({
          'event': 'result',
          'id': 'delete-atomic',
          'status': 'pass',
          'checks': [
            'later delete failure rolls back earlier delete',
            'stale editor cannot delete changed group',
            'empty delete rejected',
          ],
        });
        Future<void> home({bool dark = false}) async {
          await prefs.setInt('themeModeIndex', dark ? 2 : 1);
          await tester.pumpWidget(
            app.MyApp(
              conf[0],
              dark ? ThemeMode.dark : ThemeMode.light,
              conf[2],
              key: UniqueKey(),
            ),
          );
          await until(find.byType(CourseWidget));
          await settle();
        }

        Future<void> openDetails() async {
          await tap(tile(2, 3));
          await until(find.byType(CourseDetailsDialog));
          expect(find.byType(CourseDetailCard), findsNWidgets(2));
          expect(find.text('确认'), findsNothing);
          expect(
            key('course-detail-dismiss-hint').hitTestable(),
            findsOneWidget,
          );
          double offset(Course c) =>
              tester.getTopLeft(key('edit-course-${c.id}')).dy -
              tester.getTopLeft(key('course-detail-card-${c.id}')).dy;
          expect((offset(rows[0]) - offset(rows[2])).abs(), lessThan(.1));
        }

        Future<void> closeBlank() async {
          await tester.tapAt(const Offset(4, 100));
          await settle();
          expect(find.byType(CourseDetailsDialog), findsNothing);
        }

        await home();
        await openDetails();
        await snap(
          'details-blank-close',
          '无确认按钮，底部灰字提示点击空白处关闭；长标题、短标题及非本周课程的编辑入口统一。',
        );
        await closeBlank();
        await openDetails();
        await tap(find.text(rows.first.name!).first);
        expect(
          find.byType(CourseDetailsDialog),
          findsOneWidget,
          reason: 'Course contents must not dismiss the dialog.',
        );
        await tap(key('course-detail-dismiss-hint'));
        expect(find.byType(CourseDetailsDialog), findsNothing);
        await home(dark: true);
        await openDetails();
        await snap('details-dark', '深色主题下的小灰字关闭提示与统一编辑按钮。');
        await closeBlank();
        if (Platform.isIOS || Platform.isAndroid) {
          await home();
          await report({'event': 'font', 'scale': 2});
          await settle(16);
          await openDetails();
          await snap('details-large', '系统大字号下关闭提示固定可见，长标题换行，卡片的编辑入口保持统一。');
          await closeBlank();
          await report({'event': 'font', 'scale': 1});
          await settle(16);
        }
        await report({
          'event': 'result',
          'id': 'blank-close',
          'status': 'pass',
          'checks': [
            'outside blank closes',
            'hint closes',
            'card content stays open',
            'no confirmation button',
            'long and inactive card action offsets equal',
            'dark theme',
          ],
        });
        await home();
        await openDetails();
        await tap(key('edit-course-${rows.first.id}'));
        await until(find.byType(EditCourseView));
        expect(key('delete-course').hitTestable(), findsOneWidget);
        await snap('delete-editor', '编辑页底部提供删除课程入口，整门课程的所有时段一起删除。');
        await tap(key('delete-course'));
        expect(find.textContaining('将同时删除该课程的全部 2 个上课时段。'), findsOneWidget);
        await snap('delete-confirmation', '确认弹窗明确显示课程名称与全部两个时段，允许取消。');
        await tap(key('cancel-course-deletion'));
        expect(await provider.getMeetings(rows.first), hasLength(2));
        expect(find.byType(EditCourseView), findsOneWidget);
        await tap(key('delete-course'));
        await tap(key('confirm-course-deletion'));
        await until(find.byType(CourseWidget));
        expect(find.byType(EditCourseView), findsNothing);
        expect(await provider.getCourse(rows[0].id!), isNull);
        expect(await provider.getCourse(rows[1].id!), isNull);
        expect(
          (await provider.getAllCourses(table.id!))
              .map((r) => Course.fromMap(Map<String, dynamic>.from(r)).toMap())
              .toList(),
          untouched,
        );
        await snap('deleted-timetable', '确认后课表立即刷新；该课程两个时段均消失，另一教学班与重叠课程仍保留。');
        await report({
          'event': 'result',
          'id': 'delete-course',
          'status': 'pass',
          'checks': [
            'delete action visible',
            'cancel preserves all meetings',
            'confirm deletes both meetings',
            'other section and unrelated course remain',
            'editor closes and timetable refreshes',
          ],
          'remaining': untouched,
        });
      } catch (e) {
        await snap('failure', e.toString());
        await report({
          'event': 'result',
          'id': 'detail-delete',
          'status': 'fail',
          'error': e.toString(),
        });
        rethrow;
      } finally {
        await report({'event': 'font', 'scale': 1});
        await tester.pumpWidget(const SizedBox());
        await settle(2);
        await provider.deleteByTable(table.id!);
        await tables.delete(table.id!);
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
        await report({'event': 'complete'});
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
