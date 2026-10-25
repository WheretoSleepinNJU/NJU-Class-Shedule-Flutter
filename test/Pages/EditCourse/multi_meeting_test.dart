import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseGroup.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/CourseMeetingInput.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'edit_course_test.dart' show fixture, localized, RecordingProvider;

Course secondMeeting() =>
    Course.fromMap(fixture().toMap())
      ..id = 18
      ..weekTime = 5
      ..startTime = 5
      ..weeks = '[2,4,8]'
      ..teacher = '研讨老师'
      ..classroom = '鼓楼 202'
      ..info = '本时段独立备注';

CourseMeetingInput input(Course c) => CourseMeetingInput(
  original: c,
  weeks: c.weekNumbers,
  weekTime: c.weekTime!,
  startTime: c.startTime!,
  endTime: c.startTime! + c.timeCount!,
  teacher: c.teacher ?? '',
  classroom: c.classroom ?? '',
  timePending: c.weekTime == 0,
);

void main() {
  test('same course groups meetings while separating tables and sections', () {
    final a = fixture(), b = secondMeeting();
    expect(CourseGroup.collect([a, b]), hasLength(1));
    for (final different in [
      Course.fromMap(b.toMap())..tableId = 4,
      Course.fromMap(b.toMap())..classNumber = 'CS-102',
      Course.fromMap(b.toMap())..importType = 0,
    ]) {
      expect(CourseGroup.sameCourse(a, different), isFalse);
    }
    a.classNumber = null;
    b.classNumber = null;
    expect(CourseGroup.sameCourse(a, b), isTrue);
    b.courseId = 99;
    expect(CourseGroup.sameCourse(a, b), isFalse);
  });

  test(
    'batch edits retain independent metadata and notes for each meeting',
    () async {
      final provider = RecordingProvider();
      var refreshes = 0;
      final presenter = EditCoursePresenter(
        provider: provider,
        refreshWidgets: () async {
          refreshes++;
        },
      );
      final originals = [fixture(), secondMeeting()];
      expect(
        await presenter.saveMeetings(
          originals: originals,
          tableId: 3,
          name: '新的共同名称',
          info: '原备注',
          updateInfo: false,
          meetings: originals.map(input).toList(),
        ),
        isTrue,
      );
      expect(provider.meetings.map((c) => c.name), everyElement('新的共同名称'));
      for (var i = 0; i < 2; i++) {
        final expected = originals[i].toMap()..[columnName] = '新的共同名称';
        expect(provider.meetings[i].toMap(), expected);
      }
      expect(refreshes, 1);
    },
  );

  test(
    'adding and removing meetings keeps IDs and imported source metadata',
    () async {
      final provider = RecordingProvider();
      final presenter = EditCoursePresenter(
        provider: provider,
        refreshWidgets: () async {},
      );
      final originals = [fixture(), secondMeeting()];
      expect(
        await presenter.saveMeetings(
          originals: originals,
          tableId: 3,
          name: '离散数学',
          info: '共同备注',
          meetings: [
            input(originals[1]),
            const CourseMeetingInput(
              weeks: [1, 5],
              weekTime: 6,
              startTime: 2,
              endTime: 4,
              teacher: '新老师',
              classroom: '新教室',
              timePending: false,
            ),
          ],
        ),
        isTrue,
      );
      expect(provider.meetings.map((c) => c.id), [18, null]);
      expect(provider.meetings.last.classNumber, 'CS-101');
      expect(provider.meetings.last.courseId, 9);
      expect(provider.meetings.last.link, originals.first.link);
      expect(provider.meetings.last.weekNumbers, [1, 5]);
      expect(provider.meetings.last.timeCount, 2);
      expect(provider.meetings.map((c) => c.info), everyElement('共同备注'));
    },
  );

  test('all meetings must be valid before a batch can be written', () async {
    final provider = RecordingProvider();
    final presenter = EditCoursePresenter(
      provider: provider,
      refreshWidgets: () async {},
    );
    expect(
      await presenter.saveMeetings(
        originals: [fixture()],
        tableId: 3,
        name: '测试',
        info: '',
        meetings: [
          input(fixture()),
          const CourseMeetingInput(
            weeks: [],
            weekTime: 5,
            startTime: 1,
            endTime: 2,
            teacher: '',
            classroom: '',
            timePending: false,
          ),
        ],
      ),
      isFalse,
    );
    expect(provider.updates, 0);
  });

  testWidgets('existing meetings are recognized and editable together', (
    tester,
  ) async {
    final provider = RecordingProvider();
    final originals = [fixture(), secondMeeting()];
    await localized(
      tester,
      (_) => EditCourseView(
        course: originals.first,
        meetings: originals,
        presenter: EditCoursePresenter(
          provider: provider,
          refreshWidgets: () async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-course-name')),
      '两个时段的课程',
    );
    await tester.tap(find.text('时段 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNWidgets(2));
    await tester.tap(find.text('时段 2'));
    await tester.pumpAndSettle();
    final room = find.byKey(const ValueKey('slot-1-edit-course-classroom'));
    await tester.ensureVisible(room);
    await tester.enterText(room, '研讨课新教室');
    final week = find.byKey(const ValueKey('slot-1-edit-week-2'));
    await tester.ensureVisible(week);
    await tester.tap(week);
    await tester.tap(find.byKey(const ValueKey('save-course')));
    await tester.pumpAndSettle();
    expect(provider.meetings, hasLength(2));
    expect(provider.meetings.first.classroom, '仙林 101');
    expect(provider.meetings.first.weekNumbers, [1, 3, 7]);
    expect(provider.meetings[1].classroom, '研讨课新教室');
    expect(provider.meetings[1].weekNumbers, [4, 8]);
    expect(provider.meetings[1].info, '本时段独立备注');
  });

  testWidgets('a new course can add multiple meetings and remove a draft', (
    tester,
  ) async {
    final provider = RecordingProvider();
    await localized(
      tester,
      (_) => EditCourseView(
        tableId: 3,
        classTimeList: const [],
        presenter: EditCoursePresenter(
          provider: provider,
          refreshWidgets: () async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-course-name')),
      '手动多时段',
    );
    await tester.tap(find.text('时段 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-course-slot')));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNWidgets(2));
    final remove = find.byKey(const ValueKey('remove-slot-1'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(provider.updates, 0);
    final add = find.byKey(const ValueKey('add-course-slot'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-course')));
    await tester.pumpAndSettle();
    expect(provider.meetings, hasLength(2));
    expect(provider.meetings.map((c) => c.weekTime), [1, 2]);
    expect(provider.meetings.map((c) => c.id), everyElement(isNull));
    expect(provider.meetings.map((c) => c.importType), everyElement(0));
  });

  for (final dark in [false, true]) {
    testWidgets(
      'details use theme typography and align edit text with title ($dark)',
      (tester) async {
        final a = fixture(), b = secondMeeting();
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        await localized(
          tester,
          (_) => Theme(
            data: ThemeData(colorScheme: scheme),
            child: CourseDetailDialog(
              a,
              true,
              null,
              meetings: [a, b],
              onEdit: () {},
            ),
          ),
        );
        final title = tester.widget<Text>(find.text(a.name!));
        final editFinder = find.descendant(
          of: find.byKey(ValueKey('edit-course-${a.id}')),
          matching: find.text('编辑'),
        );
        final edit = tester.widget<Text>(editFinder);
        final editContext = tester.element(editFinder);
        final effectiveEditStyle = DefaultTextStyle.of(
          editContext,
        ).style.merge(edit.style);
        expect(title.style!.fontSize, 16);
        expect(effectiveEditStyle.fontSize, 14);
        expect(effectiveEditStyle.color, scheme.primary);
        double baseline(Finder finder) {
          final box = tester.renderObject<RenderBox>(finder);
          return box.localToGlobal(Offset.zero).dy +
              box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
        }

        expect(
          (baseline(find.text(a.name!)) - baseline(editFinder)).abs(),
          lessThan(.1),
        );
        expect(find.text('2 个上课时段'), findsOneWidget);
        expect(find.text('添加方式：自动导入'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
