import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/TimetableHeader.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/WeekPickerSheet.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

Widget harness({
  required ValueChanged<WeekSelection?> result,
  int current = 6,
  int displayed = 6,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  locale: const Locale('zh', 'CN'),
  supportedLocales: S.delegate.supportedLocales,
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: AppThemes.build('#0095F9', brightness, useSeedScheme: false),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: TimetableHeader.toolbarHeight(TextScaler.linear(scale)),
        title: TimetableHeader(
          displayedWeek: displayed,
          currentWeek: current,
          date: DateTime(2026, 10, 25),
          onTap: () async => result(
            await showWeekPickerSheet(
              context,
              currentWeek: current,
              displayedWeek: displayed,
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
    ),
  ),
);

Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('timetable-week-menu')));
  await tester.pumpAndSettle();
  expect(find.byType(WeekPickerSheet), findsOneWidget);
}

void main() {
  testWidgets('title is left aligned with the real date subtitle and arrow', (
    tester,
  ) async {
    await tester.pumpWidget(harness(result: (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('南哪课表  第6周'), findsOneWidget);
    expect(find.text('2026/10/25 周日'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    final title = tester.getTopLeft(
      find.byKey(const ValueKey('timetable-main-title')),
    );
    final date = tester.getTopLeft(
      find.byKey(const ValueKey('timetable-date-subtitle')),
    );
    expect(title.dx, 16);
    expect(date.dx, title.dx);
    expect(date.dy, greaterThan(title.dy));
  });

  for (final displayed in [5, 8]) {
    testWidgets('non-current week $displayed keeps its status suffix', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(result: (_) {}, current: 6, displayed: displayed),
      );
      await tester.pumpAndSettle();
      expect(find.text('南哪课表  第$displayed周 [非本周]'), findsOneWidget);
      expect(find.textContaining('[未开学]'), findsNothing);
      expect(find.text('2026/10/25 周日'), findsOneWidget);
    });
  }
  for (final current in [0, -2]) {
    testWidgets('pre-semester $current takes priority over non-current week', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(result: (_) {}, current: current, displayed: 1),
      );
      await tester.pumpAndSettle();
      expect(find.text('南哪课表  第1周 [未开学]'), findsOneWidget);
      expect(find.textContaining('[非本周]'), findsNothing);
      await openPicker(tester);
      expect(find.textContaining('[未开学]'), findsWidgets);
    });
  }
  testWidgets('returning to the actual week removes the non-current suffix', (
    tester,
  ) async {
    await tester.pumpWidget(harness(result: (_) {}, current: 6, displayed: 8));
    await tester.pumpAndSettle();
    expect(find.text('南哪课表  第8周 [非本周]'), findsOneWidget);
    await tester.pumpWidget(harness(result: (_) {}, current: 6, displayed: 6));
    await tester.pumpAndSettle();
    expect(find.text('南哪课表  第6周'), findsOneWidget);
    expect(find.textContaining('[非本周]'), findsNothing);
  });
  testWidgets('status, week and arrow all fit at narrow width and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    for (final current in [0, 6]) {
      await tester.pumpWidget(
        harness(result: (_) {}, current: current, displayed: 25, scale: 3.2),
      );
      await tester.pumpAndSettle();
      final text = find.byKey(const ValueKey('timetable-main-title'));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(text).right,
        lessThanOrEqualTo(
          tester.getRect(find.byIcon(Icons.arrow_drop_down)).left,
        ),
      );
      expect(
        find.byKey(const ValueKey('timetable-week-menu')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('viewing a week returns a view action without confirmation', (
    tester,
  ) async {
    WeekSelection? chosen;
    await tester.pumpWidget(harness(result: (value) => chosen = value));
    await tester.pumpAndSettle();
    await openPicker(tester);
    expect(find.text('本周'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-current-week')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('week-picker-8')));
    await tester.pumpAndSettle();
    expect(chosen?.week, 8);
    expect(chosen?.changesCurrentWeek, isFalse);
    expect(find.byType(WeekPickerSheet), findsNothing);
  });

  testWidgets('changing current week requires selecting and confirming', (
    tester,
  ) async {
    WeekSelection? chosen;
    await tester.pumpWidget(harness(result: (value) => chosen = value));
    await tester.pumpAndSettle();
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('week-picker-mode')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('confirm-current-week'));
    expect(tester.widget<AdaptiveButton>(confirm).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('week-picker-9')));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(tester.widget<AdaptiveButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(chosen?.week, 9);
    expect(chosen?.changesCurrentWeek, isTrue);
  });

  testWidgets('dismissing a pending current-week edit makes no selection', (
    tester,
  ) async {
    WeekSelection? chosen;
    await tester.pumpWidget(harness(result: (value) => chosen = value));
    await tester.pumpAndSettle();
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('week-picker-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-picker-9')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(find.byType(WeekPickerSheet), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(852, 393)]) {
    for (final brightness in Brightness.values) {
      testWidgets('large text picker remains usable at $size / $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        WeekSelection? chosen;
        await tester.pumpWidget(
          harness(
            result: (v) => chosen = v,
            scale: 3.2,
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await openPicker(tester);
        await tester.tap(find.byKey(const ValueKey('week-picker-mode')));
        await tester.pumpAndSettle();
        final grid = find.descendant(
          of: find.byKey(const ValueKey('week-picker-grid')),
          matching: find.byType(Scrollable),
        );
        // Exercise the grid's scroll extent directly; synthetic drags on this
        // binding also leave the original Material picker at offset zero.
        final position = tester.state<ScrollableState>(grid).position;
        expect(position.maxScrollExtent, greaterThan(0));
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('week-picker-25')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('week-picker-25')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('confirm-current-week')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('confirm-current-week')));
        await tester.pumpAndSettle();
        expect(chosen?.week, 25);
      });
    }
  }

  testWidgets('a pre-semester week can be corrected without a negative index', (
    tester,
  ) async {
    await tester.pumpWidget(harness(result: (_) {}, current: 0, displayed: 1));
    await tester.pumpAndSettle();
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('week-picker-mode')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('week-picker-1')), findsOneWidget);
  });

  test(
    'week browsing persists before notification and preserves actual week',
    () async {
      SharedPreferences.setMockInitialValues({
        'weekIndex': 6,
        'tmpWeekIndex': 6,
        'lastWeekMonday': '2026-10-19',
      });
      final prefs = await SharedPreferences.getInstance();
      final model = MainStateModel();
      final notification = Completer<int?>();
      model.addListener(
        () => notification.complete(prefs.getInt('tmpWeekIndex')),
      );
      await model.changeTmpWeek(8);
      expect(await notification.future, 8);
      expect(prefs.getInt('weekIndex'), 6);
      expect(prefs.getString('lastWeekMonday'), '2026-10-19');
    },
  );

  test(
    'setting actual week persists actual/browsed weeks and current Monday',
    () async {
      SharedPreferences.setMockInitialValues({
        'weekIndex': 6,
        'tmpWeekIndex': 8,
        'lastWeekMonday': '2000-01-03',
      });
      final prefs = await SharedPreferences.getInstance();
      final model = MainStateModel();
      await model.changeWeek(9);
      expect(prefs.getInt('weekIndex'), 9);
      expect(prefs.getInt('tmpWeekIndex'), 9);
      final monday = DateTime.parse(prefs.getString('lastWeekMonday')!);
      final now = DateTime.now();
      expect(monday.weekday, 1);
      expect(now.difference(monday).inDays, inInclusiveRange(0, 6));
    },
  );
}
