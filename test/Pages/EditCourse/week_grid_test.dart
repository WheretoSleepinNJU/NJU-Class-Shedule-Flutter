import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'edit_course_test.dart' show fixture, localized;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('week cells retain equal widths when toggled at scale $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await localized(
        tester,
        (_) => EditCourseView(course: fixture()),
        scale: scale,
      );
      Finder week(int n) => find.byKey(ValueKey('edit-week-$n'));
      final width = tester.getSize(week(1)).width;
      for (final n in [2, 7, 9, 10, 11, 20, 25]) {
        expect(tester.getSize(week(n)).width, width);
      }
      await Scrollable.ensureVisible(tester.element(week(10)), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(week(10));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(week(10)).selected, isTrue);
      expect(tester.getSize(week(10)).width, width);
      await tester.tap(week(10));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(week(10)).selected, isFalse);
      expect(tester.getSize(week(10)).width, width);
      expect(find.text('自由时间/时间待定'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
