import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart'
    show CourseTableProvider, CourseTable;
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
    'themed multi-meeting details, editing and adding persist atomically',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final tables = CourseTableProvider(), provider = CourseProvider();
      final table = await tables.insert(CourseTable('多时段课程 · 匿名验证'));
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
        await tester.tap(f.first);
        await settle();
      }

      Future<void> snap(String name, String note) async {
        await settle(4);
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      Finder key(String value) => find.byKey(ValueKey(value));
      Future<void> scrollTo(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          230,
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

      Future<void> editorTop() async {
        if (Platform.operatingSystem != 'ohos') return;
        // Native IME dismissal changes the inset after its close request.
        // Return to the form header after that transition before tapping it.
        await settle(12);
        final scroller =
            find
                .descendant(
                  of: find.byType(EditCourseView),
                  matching: find.byType(Scrollable),
                )
                .first;
        tester.state<ScrollableState>(scroller).position.jumpTo(0);
        await settle(6);
      }

      Future<void> enter(Finder f, String value) async {
        if (Platform.operatingSystem != 'ohos') {
          await tester.enterText(f, value);
          return;
        }
        await tap(f);
        final editable = find.descendant(
          of: f,
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(editable);
        await settle();
        final point = tester.getCenter(editable),
            ratio = tester.view.devicePixelRatio;
        await report({
          'event': 'native-input',
          'x': (point.dx * ratio).round(),
          'y': (point.dy * ratio).round(),
          'text': value,
        });
        await settle();
        expect(tester.widget<EditableText>(editable).controller.text, value);
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
        await prefs.setBool('addButton', true);
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
        final originals = <Course>[];
        for (final c in [
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,3,7]',
            2,
            3,
            1,
            1,
            courseId: 901,
            classNumber: 'QA-CS001',
            teacher: '理论课教师',
            classroom: '仙林教学楼 101',
            info: '理论课备注',
            color: '#8EB5C9',
            link: 'https://example.edu/qa',
            testTime: '原考试时间',
            testLocation: '原考试地点',
          ),
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,2,5,7]',
            5,
            5,
            1,
            1,
            courseId: 901,
            classNumber: 'QA-CS001',
            teacher: '研讨课教师',
            classroom: '鼓楼教学楼 202',
            info: '研讨课备注',
            color: '#8EB5C9',
            link: 'https://example.edu/qa',
            testTime: '原考试时间',
            testLocation: '原考试地点',
          ),
          Course(
            table.id,
            '一个特别特别长的课程名称与课堂讨论实践',
            '[1,2,3]',
            2,
            3,
            1,
            0,
            courseId: 902,
            classroom: '仙林 305',
          ),
          Course(
            table.id,
            '离散数学与课堂讨论',
            '[1,2,3]',
            4,
            5,
            1,
            1,
            courseId: 901,
            classNumber: 'QA-OTHER',
            teacher: '另一教学班教师',
          ),
        ]) {
          originals.add(await provider.insert(c));
        }
        final before = [for (final c in originals) c.toMap()];
        // A later insert fails after an earlier update: the entire transaction must roll back.
        await provider.db!.execute(
          'CREATE TRIGGER qa_meeting_abort BEFORE INSERT ON $tableName WHEN NEW.$columnTableId = ${table.id} AND NEW.$columnName = \'ATOMIC_QA\' BEGIN SELECT RAISE(ABORT, \'QA transaction rollback\'); END',
        );
        try {
          await expectLater(
            provider.saveMeetingGroup(originals.take(2).toList(), [
              Course.fromMap(originals.first.toMap())..name = 'ATOMIC_QA',
              Course.fromMap(originals.first.toMap())
                ..id = null
                ..name = 'ATOMIC_QA',
            ]),
            throwsA(isA<Exception>()),
          );
          expect(
            (await provider.getAllCourses(table.id!))
                .map(
                  (r) => Course.fromMap(Map<String, dynamic>.from(r)).toMap(),
                )
                .toList(),
            before,
          );
        } finally {
          await provider.db!.execute('DROP TRIGGER IF EXISTS qa_meeting_abort');
        }
        final changed = Course.fromMap(originals[1].toMap())
          ..classroom = '并发修改';
        await provider.update(changed);
        expect(
          await provider.saveMeetingGroup(
            originals.take(2).toList(),
            originals.take(2).toList(),
          ),
          isFalse,
        );
        await provider.update(originals[1]);
        await report({
          'event': 'result',
          'id': 'atomic-save',
          'status': 'pass',
          'checks': [
            'late insert failure rolls back earlier update',
            'stale editor rejected',
            'separate section excluded',
          ],
        });
        Future<void> home({bool dark = false, int theme = 0}) async {
          await prefs.setInt('themeModeIndex', dark ? 2 : 1);
          await prefs.setInt('themeIndex', theme);
          await tester.pumpWidget(
            app.MyApp(
              theme,
              dark ? ThemeMode.dark : ThemeMode.light,
              conf[2],
              key: UniqueKey(),
            ),
          );
          await until(find.byType(CourseWidget));
          await settle();
        }

        await home();
        await tap(tile(2, 3));
        expect(find.byType(CourseDetailCard), findsNWidgets(2));
        expect(find.text('2 个上课时段'), findsOneWidget);
        await snap('multi-default', '默认主题、标准字号；一张卡片识别两个时段，标题与编辑首行对齐。');
        await tap(key('edit-course-${originals.first.id}'));
        await snap('multi-editor', '已有课程回填两个独立时段，每个时段保留自己的教师、教室、周次。');
        await enter(key('edit-course-name'), '离散数学（多时段）');
        await enter(key('edit-course-classroom'), '仙林教学楼 305');
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
        await editorTop();
        await tap(find.text('时段 1'));
        await scrollTo(key('add-course-slot'));
        await tap(key('add-course-slot'));
        await scrollTo(key('course-slot-2'));
        await tap(find.text('时段 3'));
        await snap('multi-three-drafts', '同一门课程可继续添加第三时段；各时段能独立展开或移除。');
        await tap(key('save-course'));
        await until(tile(2, 3));
        var meetings = await provider.getMeetings(
          (await provider.getCourse(originals.first.id!))!,
        );
        expect(meetings, hasLength(3));
        expect(meetings.map((c) => c.name), everyElement('离散数学（多时段）'));
        expect(meetings.first.classroom, '仙林教学楼 305');
        expect(
          meetings[1].toMap(),
          Map<String, dynamic>.from(before[1])..[columnName] = '离散数学（多时段）',
        );
        expect(meetings.last.id, isNotNull);
        expect(meetings.last.weekTime, 6);
        expect(meetings.map((c) => c.courseId), everyElement(901));
        expect(
          (await provider.getCourse(originals.last.id!))!.toMap(),
          before.last,
        );
        expect(await provider.getAllCourses(table.id!), hasLength(5));
        await home(theme: 3);
        await tap(tile(2, 3));
        await snap(
          'multi-purple',
          '切换紫色主题后，卡片底色、描边、时段标签与编辑按钮跟随主题。保存后重新打开显示三个时段。',
        );
        await tap(key('edit-course-${originals.first.id}'));
        await editorTop();
        await tap(find.text('时段 1'));
        await scrollTo(key('remove-slot-2'));
        await tap(key('remove-slot-2'));
        await tap(key('save-course'));
        await until(tile(2, 3));
        meetings = await provider.getMeetings(
          (await provider.getCourse(originals.first.id!))!,
        );
        expect(meetings, hasLength(2));
        expect(await provider.getAllCourses(table.id!), hasLength(4));
        await home(dark: true, theme: 3);
        await tap(tile(2, 3));
        await snap('multi-dark', '深色紫色主题：多时段卡片、标准字号与主题色编辑入口。');
        await tap(key('edit-course-${originals.first.id}'));
        await enter(key('edit-course-name'), '不应保存');
        await tap(find.byType(BackButton));
        expect(
          (await provider.getCourse(originals.first.id!))!.name,
          '离散数学（多时段）',
        );
        await report({
          'event': 'result',
          'id': 'edit-multiple',
          'status': 'pass',
          'readback': meetings.map((c) => c.toMap()).toList(),
          'checks': [
            '2 imported meetings recognized',
            'third meeting inserted then removed',
            'independent notes/weeks/teachers retained',
            'other section untouched',
            'cancel did not write',
          ],
        });
        await home();
        await tap(find.byType(FloatingActionButton));
        await until(key('edit-course-name'));
        await settle();
        await enter(key('edit-course-name'), '手动添加的多时段课程');
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
        await editorTop();
        await tap(find.text('时段 1'));
        await tap(key('add-course-slot'));
        await scrollTo(key('course-slot-1'));
        await tap(find.text('时段 2'));
        await snap('add-two-meetings', '实际添加入口支持一门课程设置多个时段；两个时段统一提交。');
        await tap(key('save-course'));
        await until(tile(1, 1));
        final added =
            (await provider.getAllCourses(table.id!))
                .map((r) => Course.fromMap(Map<String, dynamic>.from(r)))
                .where((c) => c.name == '手动添加的多时段课程')
                .toList();
        expect(added, hasLength(2));
        expect(added.map((c) => c.courseId).toSet(), hasLength(1));
        expect(added.map((c) => c.importType), everyElement(0));
        await tap(tile(1, 1));
        expect(find.text('添加方式：手动导入'), findsOneWidget);
        expect(find.text('2 个上课时段'), findsOneWidget);
        await snap('added-details', '添加后重新打开详情识别两个时段，来源明确显示“添加方式：手动导入”。');
        await report({
          'event': 'result',
          'id': 'add-multiple',
          'status': 'pass',
          'readback': added.map((c) => c.toMap()).toList(),
        });
        if (Platform.isIOS || Platform.isAndroid) {
          await tap(find.byKey(const ValueKey('course-detail-dismiss-hint')));
          await report({'event': 'font', 'scale': 2});
          await settle(16);
          await tap(tile(1, 1));
          await snap('multi-large', '系统大字体下，标准样式随辅助功能字号放大，多时段详情保持可滚动。');
          await tap(key('edit-course-${added.first.id}'));
          await snap('editor-large', '系统大字体下多时段编辑与顶部保存按钮仍可用。');
          expect(tester.takeException(), isNull);
        }
        await report({
          'event': 'result',
          'id': 'theme-details',
          'status': 'pass',
          'checks': [
            'default theme',
            'purple theme',
            'dark theme',
            'standard font sizes',
            'edit and title baseline alignment',
            'explicit manual source label',
          ],
        });
      } catch (error) {
        await snap('failure', error.toString());
        await report({
          'event': 'result',
          'id': 'multi-meetings',
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
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
