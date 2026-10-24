import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/CourseTablePresenter.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

Widget localized(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('zh', 'CN'),
  supportedLocales: S.delegate.supportedLocales,
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

Course course(String name) =>
    Course(1, name, '[1]', 1, 1, 0, 0, classroom: 'QA-101');

Finder get badge => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
);

void main() {
  testWidgets('a single course has no count badge', (tester) async {
    await tester.pumpWidget(
      localized(
        CourseWidget(course('单门课程'), '#648BCC', 60, 52, true, 1, null, null),
      ),
    );
    expect(badge, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the badge shows the count and forwards taps to the course', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      localized(
        CourseWidget(
          course('冲突课程'),
          '#648BCC',
          60,
          52,
          true,
          3,
          () => taps++,
          null,
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.tapAt(tester.getCenter(badge));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a badge preserves the padded text position and width', (
    tester,
  ) async {
    Future<Rect> textRect(int count) async {
      await tester.pumpWidget(
        localized(
          CourseWidget(
            course('课程名称'),
            '#648BCC',
            60,
            52,
            true,
            count,
            null,
            null,
          ),
        ),
      );
      return tester.getRect(
        find.descendant(
          of: find.byType(CourseWidget),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().startsWith('课程名称'),
          ),
        ),
      );
    }

    final single = await textRect(1);
    final multiple = await textRect(12);
    expect(multiple, single);
    final card = tester.getRect(find.byType(CourseWidget));
    expect(multiple.left - card.left, 4.5);
    expect(multiple.top - card.top, 8.5);
    expect(card.right - multiple.right, 4.5);
    expect(tester.getRect(badge).top, card.top + 0.5);
    expect(tester.getRect(badge).right, card.right - 0.5);
    expect(tester.takeException(), isNull);
  });

  for (final count in [2, 12, 100]) {
    testWidgets('count $count fits a small card with large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        localized(
          CourseWidget(
            course('长课程名称与教学讨论'),
            '#648BCC',
            44,
            40,
            true,
            count,
            null,
            null,
          ),
          scale: 3.2,
        ),
      );
      final circle = tester.getRect(badge);
      final number = tester.getRect(find.text('$count'));
      expect(circle.width, circle.height);
      expect(circle.contains(number.topLeft), isTrue);
      expect(circle.contains(number.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the presenter passes the full selectable overlap count', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'colorPool': '[0,1,2]'});
    final presenter = CourseTablePresenter();
    presenter.multiCourses = [
      [course('A'), course('B'), course('C')],
    ];
    late BuildContext context;
    await tester.pumpWidget(
      localized(
        Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final cards = await presenter.getClassesWidgetList(
      context,
      60,
      52,
      1,
      true,
    );
    expect(cards, hasLength(1));
    expect((cards!.single as CourseWidget).courseCount, 3);
    await tester.pumpWidget(localized(Stack(children: cards)));
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
