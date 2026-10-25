import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/ScheduleModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

class RecordingProvider extends CourseProvider {
  Course? saved;
  int rows = 1;
  int updates = 0;
  List<Course> meetings = [];
  @override
  Future<bool> saveMeetingGroup(
    List<Course> originals,
    List<Course> courses,
  ) async {
    saved = courses.first;
    meetings = courses;
    updates++;
    return rows == 1;
  }
}

Course fixture() => Course(
  3,
  '离散数学与课堂讨论',
  '[1,3,7]',
  2,
  3,
  1,
  1,
  id: 17,
  courseId: 9,
  color: '#aabbcc',
  classroom: '仙林 101',
  teacher: '测试老师',
  info: '原备注',
  classNumber: 'CS-101',
  link: 'https://example.edu/course/1',
  testTime: '期末考试时间',
  testLocation: '考试地点',
);

Future<void> localized(
  WidgetTester tester,
  WidgetBuilder page, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
      home: Builder(
        builder:
            (context) => Scaffold(
              body: TextButton(
                child: const Text('打开'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: page)),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'updating a meeting preserves its ID and all imported metadata',
    () async {
      final provider = RecordingProvider();
      var refreshes = 0;
      final presenter = EditCoursePresenter(
        provider: provider,
        refreshWidgets: () async {
          refreshes++;
        },
      );
      final original = fixture();
      final before = original.toMap();
      expect(
        await presenter.save(
          original,
          name: ' 新名称 ',
          teacher: ' 新老师 ',
          classroom: ' 新地点 ',
          info: ' 新备注 ',
          weeks: [7, 1, 7, 3],
          weekTime: 5,
          startTime: 4,
          endTime: 6,
          timePending: false,
        ),
        isTrue,
      );
      final saved = provider.saved!;
      expect(saved.id, 17);
      expect(saved.tableId, 3);
      expect(saved.courseId, 9);
      expect(saved.importType, 1);
      expect(saved.color, '#aabbcc');
      expect(saved.classNumber, original.classNumber);
      expect(saved.link, original.link);
      expect(saved.testTime, original.testTime);
      expect(saved.testLocation, original.testLocation);
      expect(saved.weekNumbers, [1, 3, 7]);
      expect(saved.startTime, 4);
      expect(saved.timeCount, 2);
      expect(saved.weekTime, 5);
      expect(saved.name, '新名称');
      expect(
        original.toMap(),
        before,
        reason:
            'Do not mutate the displayed record before persistence succeeds.',
      );
      expect(refreshes, 1);
      expect(provider.updates, 1);
    },
  );

  test(
    'a deleted meeting and invalid weeks cannot become duplicate courses',
    () async {
      final provider = RecordingProvider()..rows = 0;
      var refreshes = 0;
      final presenter = EditCoursePresenter(
        provider: provider,
        refreshWidgets: () async {
          refreshes++;
        },
      );
      Future<bool> save(List<int> weeks) => presenter.save(
        fixture(),
        name: '测试',
        teacher: '',
        classroom: '',
        info: '',
        weeks: weeks,
        weekTime: 2,
        startTime: 1,
        endTime: 1,
        timePending: false,
      );
      expect(await save([]), isFalse);
      expect(provider.updates, 0);
      expect(await save([1]), isFalse);
      expect(provider.updates, 1);
      expect(refreshes, 0);
    },
  );

  test('free courses retain their unscheduled representation', () async {
    final provider = RecordingProvider();
    final presenter = EditCoursePresenter(
      provider: provider,
      refreshWidgets: () async {},
    );
    expect(
      await presenter.save(
        fixture(),
        name: '自由课程',
        teacher: '',
        classroom: '',
        info: '',
        weeks: [3, 5],
        weekTime: 2,
        startTime: 1,
        endTime: 4,
        timePending: true,
      ),
      isTrue,
    );
    expect(provider.saved!.startTime, 0);
    expect(provider.saved!.timeCount, 0);
    expect(provider.saved!.weekTime, 0);
    final schedule = ScheduleModel([provider.saved!], 3)..init();
    expect(schedule.freeCourses, [provider.saved]);
    expect(schedule.activeCourses, isEmpty);
  });

  testWidgets('editing a name leaves irregular imported weeks unchanged', (
    tester,
  ) async {
    final provider = RecordingProvider();
    await localized(
      tester,
      (_) => EditCourseView(
        course: fixture(),
        presenter: EditCoursePresenter(
          provider: provider,
          refreshWidgets: () async {},
        ),
      ),
    );
    expect(find.text('离散数学与课堂讨论'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('edit-course-name')),
      '修改后的课程',
    );
    await tester.tap(find.byKey(const ValueKey('save-course')));
    await tester.pumpAndSettle();
    expect(provider.saved!.name, '修改后的课程');
    expect(provider.saved!.weekNumbers, [1, 3, 7]);
    expect(find.byType(EditCourseView), findsNothing);
  });

  testWidgets('back cancels edits without any database write', (tester) async {
    final provider = RecordingProvider();
    final course = fixture();
    await localized(
      tester,
      (_) => EditCourseView(
        course: course,
        presenter: EditCoursePresenter(
          provider: provider,
          refreshWidgets: () async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-course-name')),
      '不保存的修改',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(provider.updates, 0);
    expect(course.name, '离散数学与课堂讨论');
  });

  testWidgets('large-font editor remains usable on a small screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    await localized(
      tester,
      (_) => EditCourseView(course: fixture()),
      scale: 3.2,
    );
    expect(find.text('保存').hitTestable(), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('edit-course-name')), '');
    await tester.tap(find.byKey(const ValueKey('save-course')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.class_name_empty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlapping courses form a vertical list with independent edit actions',
    (tester) async {
      final courses = List.generate(
        3,
        (index) =>
            fixture()
              ..id = index
              ..name = '课程 $index',
      );
      int? edited;
      await localized(
        tester,
        (context) => CourseDetailsDialog(
          courses: courses,
          isActive: (_) => true,
          onEdit: (course) {
            edited = course.id;
          },
        ),
        scale: 2,
      );
      final scroll = find.byKey(const ValueKey('course-detail-scroll'));
      await tester.drag(scroll, const Offset(0, -1200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('edit-course-2')));
      await tester.tap(find.byKey(const ValueKey('edit-course-2')));
      expect(edited, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
