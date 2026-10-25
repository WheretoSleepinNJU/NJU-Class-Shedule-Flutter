import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'edit_course_test.dart' show fixture, localized, RecordingProvider;
import 'multi_meeting_test.dart' show secondMeeting;
import '../../Components/dialog_accessibility_test.dart' show openDialog;

class DeletionProvider extends RecordingProvider {
  int deletions = 0;
  bool succeeds = true;
  List<Course>? deleted;
  @override
  Future<bool> deleteMeetingGroup(List<Course> originals) async {
    deletions++;
    deleted = originals;
    return succeeds;
  }
}

void main() {
  test(
    'deletion passes the complete original group and refreshes only on success',
    () async {
      final provider = DeletionProvider();
      var refreshes = 0;
      final presenter = EditCoursePresenter(
        provider: provider,
        refreshWidgets: () async {
          refreshes++;
        },
      );
      final originals = [fixture(), secondMeeting()];
      expect(await presenter.delete(originals), isTrue);
      expect(provider.deleted, originals);
      expect(refreshes, 1);
      provider.succeeds = false;
      expect(await presenter.delete(originals), isFalse);
      expect(refreshes, 1);
    },
  );

  testWidgets('cancel deletion preserves the unsaved form and all meetings', (
    tester,
  ) async {
    final provider = DeletionProvider();
    await localized(
      tester,
      (_) => EditCourseView(
        course: fixture(),
        meetings: [fixture(), secondMeeting()],
        presenter: EditCoursePresenter(
          provider: provider,
          refreshWidgets: () async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-course-name')),
      '尚未保存的课程名',
    );
    await tester.tap(find.byKey(const ValueKey('delete-course')));
    await tester.pumpAndSettle();
    expect(find.textContaining('将同时删除该课程的全部 2 个上课时段。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel-course-deletion')));
    await tester.pumpAndSettle();
    expect(provider.deletions, 0);
    expect(find.text('尚未保存的课程名'), findsOneWidget);
    expect(find.byType(EditCourseView), findsOneWidget);
  });

  for (final succeeds in [true, false]) {
    testWidgets(
      'confirm deletion closes only after persistence succeeds ($succeeds)',
      (tester) async {
        final provider = DeletionProvider()..succeeds = succeeds;
        await localized(
          tester,
          (_) => EditCourseView(
            course: fixture(),
            meetings: [fixture(), secondMeeting()],
            presenter: EditCoursePresenter(
              provider: provider,
              refreshWidgets: () async {},
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('delete-course')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-course-deletion')));
        await tester.pumpAndSettle();
        expect(provider.deletions, 1);
        expect(provider.deleted!.map((c) => c.id), [17, 18]);
        expect(
          find.byType(EditCourseView),
          succeeds ? findsNothing : findsOneWidget,
        );
        if (!succeeds) expect(find.text('删除失败，请重新打开课程后重试'), findsOneWidget);
      },
    );
  }

  testWidgets('new courses have no delete option', (tester) async {
    await localized(
      tester,
      (_) => const EditCourseView(tableId: 3, classTimeList: []),
    );
    expect(find.byKey(const ValueKey('delete-course')), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'card actions keep the same top offset for long titles and inactive courses ($scale)',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final a = fixture()..name = '一个特别特别特别长的课程名称与课堂讨论实践';
        final b = secondMeeting()..name = '短标题';
        await openDialog(
          tester,
          (_) => CourseDetailsDialog(
            courses: [a, b],
            isActive: (c) => c.id == b.id,
            onEdit: (_) {},
          ),
          scale: scale,
        );
        double actionOffset(Course c) =>
            tester.getTopLeft(find.byKey(ValueKey('edit-course-${c.id}'))).dy -
            tester
                .getTopLeft(find.byKey(ValueKey('course-detail-card-${c.id}')))
                .dy;
        expect((actionOffset(a) - actionOffset(b)).abs(), lessThan(.1));
        expect(find.text('确认'), findsNothing);
        await tester.tap(find.text(a.name!));
        await tester.pumpAndSettle();
        expect(
          find.byType(CourseDetailsDialog),
          findsOneWidget,
          reason: 'Card contents are not blank space.',
        );
        await tester.tapAt(const Offset(4, 100));
        await tester.pumpAndSettle();
        expect(find.byType(CourseDetailsDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('tapping the blank gap inside the dialog closes it', (
    tester,
  ) async {
    final a = fixture(), b = secondMeeting()..name = '另一门课程';
    await openDialog(
      tester,
      (_) => CourseDetailsDialog(courses: [a, b], isActive: (_) => true),
      scale: 1,
    );
    final first = find.byKey(ValueKey('course-detail-card-${a.id}'));
    final point = tester.getBottomLeft(first) + const Offset(12, 6);
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(find.byType(CourseDetailsDialog), findsNothing);
  });
}
