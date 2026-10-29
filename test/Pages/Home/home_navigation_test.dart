import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_title_bar.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/Home/CoursesView.dart';
import 'package:wheretosleepinnju/Pages/About/Widgets/RainDropWidget.dart';
import 'package:wheretosleepinnju/Resources/Constant.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import '../EditCourse/edit_course_test.dart' show localized;

class _Courses extends CourseProvider {
  final reads = <int>[];
  @override
  Future<List> getAllCourses(int id) async {
    reads.add(id);
    return [
      for (var index = 0; index < (id == 1 ? 2 : 1); index++)
        Course(
          id,
          id == 1 ? '多时段课程' : '新学期课程',
          '[1,2]',
          index + 1,
          1,
          1,
          0,
          id: index + 1,
          courseId: 7,
          teacher: '老师',
        ).toMap(),
    ];
  }
}

class _Tables extends CourseTableProvider {
  @override
  Future<List<Map>> getClassTimeList(int id) async => Constant.CLASS_TIME_LIST;
}

void main() {
  testWidgets(
    'tab ownership, retained drafts, back-to-home and full-screen routes',
    (tester) async {
      const channel = MethodChannel('nju/compose-titlebar');
      final calls = <Map>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'update') calls.add(call.arguments as Map);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final navigator = GlobalKey<NavigatorState>();
      final draft = TextEditingController();
      var selected = 0;
      final pages = [
        AdaptiveScaffold(
          appBar: const AdaptiveTopAppBar(title: Text('Timetable toolbar')),
          body: AdaptivePageList(children: [TextField(controller: draft)]),
        ),
        const AdaptiveScaffold(
          appBar: AdaptiveTopAppBar(title: Text('Courses toolbar')),
          body: Text('Courses body'),
        ),
        const AdaptiveScaffold(
          appBar: AdaptiveTopAppBar(title: Text('Profile toolbar')),
          body: Text('Profile body'),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => platform.AdaptiveToolbarHost(
            nativeBackend: createComposeTitleBarBackend(),
            child: child!,
          ),
          home: StatefulBuilder(
            builder: (_, update) => AdaptiveNavigationShell(
              selectedIndex: selected,
              onSelected: (index) => update(() => selected = index),
              pages: pages,
              items: const [
                AdaptiveNavigationItem(
                  label: '课表',
                  icon: Icons.calendar_month,
                  selectedIcon: Icons.calendar_month,
                  iosSymbol: 'calendar',
                  iosSelectedSymbol: 'calendar',
                ),
                AdaptiveNavigationItem(
                  label: '课程',
                  icon: Icons.book,
                  selectedIcon: Icons.book,
                  iosSymbol: 'book',
                  iosSelectedSymbol: 'book',
                ),
                AdaptiveNavigationItem(
                  label: '我的',
                  icon: Icons.person,
                  selectedIcon: Icons.person,
                  iosSymbol: 'person',
                  iosSelectedSymbol: 'person',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.last['title'], 'Timetable toolbar');
      await tester.enterText(find.byType(TextField), 'retained draft');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('课程'),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.last['title'], 'Courses toolbar');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('我的'),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.last['title'], 'Profile toolbar');
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const AdaptiveScaffold(
            appBar: AdaptiveTopAppBar(title: Text('Detail')),
            body: Text('Detail body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.last['title'], 'Detail');
      expect(find.byType(NavigationBar), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(calls.last['title'], 'Profile toolbar');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(selected, 0);
      expect(calls.last['title'], 'Timetable toolbar');
      expect(draft.text, 'retained draft');
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'added courses group meetings and reload after timetable changes',
    (tester) async {
      SharedPreferences.setMockInitialValues({'tableId': 1});
      final provider = _Courses();
      final key = GlobalKey<CoursesViewState>();
      await localized(
        tester,
        (_) => ScopedModel<MainStateModel>(
          model: MainStateModel(),
          child: CoursesView(key: key, provider: provider, tables: _Tables()),
        ),
      );
      expect(find.text('多时段课程'), findsOneWidget);
      expect(find.textContaining('2 个上课时段'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tableId', 2);
      key.currentState!.reload();
      await tester.pumpAndSettle();
      expect(find.text('多时段课程'), findsNothing);
      expect(find.text('新学期课程'), findsOneWidget);
      expect(provider.reads, [1, 2]);
    },
  );

  testWidgets('rain background pauses with route visibility and lifecycle', (
    tester,
  ) async {
    var visible = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, set) {
            update = set;
            return TickerMode(enabled: visible, child: const RainDropWidget());
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    update(() => visible = false);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    update(() => visible = true);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Material tabs consume navigation padding once and never status padding',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      for (final bottom in [24.0, 48.0]) {
        tester.view.padding = FakeViewPadding(top: 48, bottom: bottom);
        double? clearance;
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveNavigationShell(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                AdaptiveNavigationItem(
                  label: '课表',
                  icon: Icons.calendar_month,
                  selectedIcon: Icons.calendar_month,
                  iosSymbol: 'calendar',
                  iosSelectedSymbol: 'calendar',
                ),
                AdaptiveNavigationItem(
                  label: '我的',
                  icon: Icons.person,
                  selectedIcon: Icons.person,
                  iosSymbol: 'person',
                  iosSelectedSymbol: 'person',
                ),
              ],
              pages: [
                Builder(
                  builder: (context) {
                    clearance = AdaptiveNavigationScope.scrollClearanceOf(
                      context,
                    );
                    return const ColoredBox(color: Colors.blue);
                  },
                ),
                const SizedBox(),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byType(NavigationBar));
        expect(rect.height, 64 + bottom);
        expect(rect.bottom, 800);
        expect(rect.top, 800 - 64 - bottom);
        expect(clearance, 64 + bottom);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
