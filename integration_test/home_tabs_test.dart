import 'dart:io';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart'
    as native_toolbar;
import 'dart:ui' as ui;
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_navigation.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/Home/HomeView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/FreeCoursesEntry.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/TimetableHeader.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/WeekTitle.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/Pages/Home/CoursesView.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseSummaryTile.dart';
import 'package:wheretosleepinnju/Pages/About/AboutView.dart';
import 'package:wheretosleepinnju/Pages/About/Widgets/RainDropWidget.dart';
import 'package:wheretosleepinnju/Pages/Settings/SettingsView.dart';
import 'package:wheretosleepinnju/Pages/Settings/MoreSettingsView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  for (final dark in [false, true]) {
    testWidgets('real home tabs, native chrome, profile and animated About dark=$dark', (
      tester,
    ) async {
      final previousPointerPolicy = binding.shouldPropagateDevicePointerEvents;
      binding.shouldPropagateDevicePointerEvents = true;
      final semantics = tester.ensureSemantics();
      try {
        SharedPreferences.setMockInitialValues({
          'privacyVersion': 1000000000,
          'weekIndex': 1,
          'hasShowReview': true,
        });
        await InitUtil.checkDataBase();
        await WeekUtil.setNowWeek(1);
        final tables = CourseTableProvider(), courses = CourseProvider();
        final table = await tables.insert(CourseTable('导航验证'));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('tableId', table.id!);
        final documents = await getApplicationDocumentsDirectory();
        final backgroundName =
            'home-tab-background-${dark ? 'light' : 'dark'}.png';
        final background = File('${documents.path}/$backgroundName');
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(
          dark ? const Color(0xfff0ece5) : const Color(0xff26384c),
          ui.BlendMode.src,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(16, 16);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await background.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        await prefs.setString('bgImgPath', background.path);
        await prefs.setStringList('backgroundImages', [backgroundName]);
        await prefs.setString(
          'backgroundWhiteModes',
          '{"$backgroundName":${!dark}}',
        );
        await courses.insert(
          Course(table.id!, '自主研学', '[1,2,3]', 0, 0, 0, 0, courseId: 99),
        );
        for (var index = 0; index < 2; index++) {
          await courses.insert(
            Course(
              table.id!,
              '高等数学',
              '[1,2,3]',
              index + 1,
              index * 2 + 1,
              1,
              0,
              courseId: 7,
              teacher: '示例老师',
              classroom: '仙Ⅰ-201',
              info: '每周课前完成习题，课堂讨论后提交学习记录。',
            ),
          );
        }
        for (var i = 0; i < 12; i++) {
          await courses.insert(
            Course(
              table.id!,
              '滚动验收课程 $i',
              '[1,2,3]',
              3,
              1,
              1,
              0,
              courseId: 200 + i,
              teacher: '老师',
              classroom: '仙Ⅰ-201',
            ),
          );
        }
        final navigator = GlobalKey<NavigatorState>();
        final preference = AdaptiveUIController();
        final mainModel = MainStateModel();
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: mainModel,
            child: AdaptiveUIApp(
              controller: preference,
              navigatorKey: navigator,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              materialLightTheme: AppThemes.build(
                '#0095F9',
                Brightness.light,
                useSeedScheme: true,
              ),
              materialDarkTheme: AppThemes.build(
                '#0095F9',
                Brightness.dark,
                useSeedScheme: true,
              ),
              supportedLocales: const [Locale('zh', 'CN')],
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const HomeView(),
            ),
          ),
        );
        Future<void> until(bool Function() ready) async {
          for (var retry = 0; retry < 150; retry++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
            if (ready()) return;
          }
          if (Platform.isAndroid) {
            final snapshot = (await const MethodChannel(
              'nju/compose-titlebar',
            ).invokeMapMethod<Object?, Object?>('diagnostics'))!;
            debugPrint(
              'HOME_NATIVE_FAILURE: ${Map.fromEntries(snapshot.entries.where((entry) => !entry.key.toString().contains("color")))}',
            );
          }
          fail('Home state not reached');
        }

        Future<Map<Object?, Object?>> android() async =>
            (await const MethodChannel(
              'nju/compose-titlebar',
            ).invokeMapMethod<Object?, Object?>('diagnostics'))!;
        Future<void> select(int index) async {
          if (Platform.isIOS) {
            final state = tester.state<platform.IOS26NativeTabBarState>(
              find.byType(platform.IOS26NativeTabBar),
            );
            await state.activateNativeItem(index);
          } else {
            final label = ['课表', '课程', '我的'][index];
            final finder = find
                .byWidgetPredicate(
                  (widget) =>
                      widget is Semantics &&
                      widget.properties.label == label &&
                      widget.properties.button == true,
                )
                .last;
            if (const bool.fromEnvironment('DRIVE_ANDROID_NAV')) {
              final rect = tester.getRect(find.byType(ComposeNavigation));
              final point = Offset(
                rect.left + rect.width * (index + .5) / 3,
                rect.center.dy,
              );
              final ratio = tester.view.devicePixelRatio;
              debugPrint(
                'HOME_NAV_TAP: ${(point.dx * ratio).round()} ${(point.dy * ratio).round()}',
              );
              for (var i = 0; i < 100; i++) {
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 100)),
                );
                await tester.pump();
                if ((await android())['navigationSelectedIndex'] == index) {
                  break;
                }
              }
              if ((await android())['navigationSelectedIndex'] != index) {
                final state = await android();
                debugPrint(
                  'HOME_NATIVE_FAILURE: ${Map.fromEntries(state.entries.where((entry) => !entry.key.toString().contains("color")))}',
                );
              }
              expect((await android())['navigationSelectedIndex'], index);
            } else {
              tester.binding.renderViews.first.owner!.semanticsOwner!
                  .performAction(
                    tester.getSemantics(finder).id,
                    ui.SemanticsAction.tap,
                  );
            }
          }
          await tester.pump();
        }

        Future<void> capture(String page) async {
          expect(tester.takeException(), isNull);
          if (!const bool.fromEnvironment('CAPTURE_HOME_TABS')) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 1500)),
          );
          await tester.pump();
          final name = '$page-${dark ? 'dark' : 'light'}';
          if (Platform.isIOS) {
            final bytes = await binding.takeScreenshot(name);
            final folder = await getApplicationDocumentsDirectory();
            final file = File('${folder.path}/$name.png');
            await file.writeAsBytes(bytes);
            debugPrint('HOME_UIKIT_FILE: ${file.path}');
            debugPrint('HOME_PAGE_READY: $name');
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(seconds: 4)),
            );
          } else {
            debugPrint('HOME_PAGE_READY: $name');
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(seconds: 4)),
            );
          }
        }

        await until(
          () =>
              find.byType(AdaptiveNavigationShell).evaluate().isNotEmpty &&
              find
                  .textContaining('高等数学', findRichText: true)
                  .evaluate()
                  .isNotEmpty,
        );
        await until(() => find.byType(FreeCoursesEntry).evaluate().isNotEmpty);
        final entry = tester.widget<FreeCoursesEntry>(
          find.byType(FreeCoursesEntry),
        );
        expect(entry.backgroundSeed, isNotNull);
        final entryCard = tester.widget<AdaptiveCard>(
          find.descendant(
            of: find.byType(FreeCoursesEntry),
            matching: find.byType(AdaptiveCard),
          ),
        );
        final palette = ColorScheme.fromSeed(
          seedColor: Color(
            int.parse(entry.backgroundSeed!.substring(1), radix: 16) |
                0xff000000,
          ),
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        expect(entryCard.color, palette.primaryContainer);
        expect(
          Theme.of(
            tester.element(find.byType(FreeCoursesEntry)),
          ).colorScheme.primary,
          AppThemes.build(
            '#0095F9',
            dark ? Brightness.dark : Brightness.light,
            useSeedScheme: true,
          ).colorScheme.primary,
        );
        final entryRect = tester.getRect(find.byType(FreeCoursesEntry));
        if (Platform.isAndroid) {
          expect(
            entryRect.top,
            greaterThanOrEqualTo(
              tester.getRect(find.byType(TimetableHeader)).bottom,
            ),
          );
        } else {
          // UIKit owns the title; no Flutter TimetableHeader is mounted.
          expect(
            entryRect.top,
            greaterThanOrEqualTo(
              tester.view.padding.top / tester.view.devicePixelRatio + 44,
            ),
          );
        }
        expect(
          entryRect.bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(WeekTitle)).top),
        );
        if (Platform.isIOS) {
          // WidgetTester pointers cannot activate a native UIKit UIButton.
          // Exercise the Adaptive action contract; Android uses a real tap.
          tester
              .widget<AdaptiveButton>(
                find.descendant(
                  of: find.byType(FreeCoursesEntry),
                  matching: find.byType(AdaptiveButton),
                ),
              )
              .onPressed!();
        } else {
          await tester.tap(find.byType(FreeCoursesEntry));
        }
        await until(
          () =>
              find.byType(CourseDetailsDialog).evaluate().isNotEmpty &&
              find.text('自主研学').evaluate().isNotEmpty,
        );
        expect(find.text('自主研学'), findsWidgets);
        navigator.currentState!.pop();
        await until(() => find.byType(CourseDetailsDialog).evaluate().isEmpty);
        await prefs.setBool('showFreeClass', false);
        mainModel.refresh();
        await until(
          () =>
              find.byType(FreeCoursesEntry).evaluate().isEmpty &&
              find.byType(WeekTitle).evaluate().isNotEmpty,
        );
        expect(
          tester.getRect(find.byType(WeekTitle)).top,
          closeTo(entryRect.top, .5),
        );
        await prefs.setBool('showFreeClass', true);
        mainModel.refresh();
        await until(() => find.byType(FreeCoursesEntry).evaluate().isNotEmpty);
        expect(tester.getRect(find.byType(FreeCoursesEntry)), entryRect);
        if (Platform.isAndroid) {
          for (var i = 0; i < 80; i++) {
            final state = await android();
            if (state['glassNavigationBars'] == 1 &&
                state['dialogBackdropReady'] == true &&
                state['navigationInputReady'] == true) {
              break;
            }
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
          }
          final state = await android();
          expect(state['glassNavigationBars'], 1);
          expect(state['navigationRenderer'], 'activity-compose');
          expect(state['navigationInputReady'], true);
          expect(state['navigationDark'], !dark);
          expect(
            tester
                .widget<TimetableHeader>(find.byType(TimetableHeader))
                .foregroundColor,
            dark ? Colors.black : Colors.white,
          );
          expect(state['navigationLayout'], 'stacked');
          expect(state['navigationItems'], [
            'Months',
            'NotesFill',
            'ContactsCircle',
          ]);
          final bounds = state['navigationBounds'] as List;
          expect(bounds[3], 54);
          expect(
            (tester.view.physicalSize.height / tester.view.devicePixelRatio) -
                (bounds[1] as num) -
                (bounds[3] as num),
            closeTo(
              tester.view.padding.bottom / tester.view.devicePixelRatio + 2,
              .5,
            ),
          );
          expect(state['pixelCopyCount'], 0);
          expect(state['dialogBackdropReady'], true);
        } else {
          final state = tester.state<platform.IOS26NativeTabBarState>(
            find.byType(platform.IOS26NativeTabBar),
          );
          Map<Object?, Object?>? snapshot;
          for (var i = 0; i < 80; i++) {
            snapshot = await state.nativeSnapshot();
            if (snapshot?['attached'] == true &&
                snapshot?['isDark'] == dark &&
                snapshot?['height'] == snapshot?['fittedHeight']) {
              break;
            }
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
          }
          debugPrint('HOME_UIKIT_DIAGNOSTICS: $snapshot');
          expect(snapshot?['renderer'], 'UITabBar');
          expect(snapshot?['labels'], ['课表', '课程', '我的']);
          expect(snapshot?['isDark'], dark);
          expect(snapshot?['height'], snapshot?['fittedHeight']);
        }
        await capture('home-timetable');
        await select(1);
        await until(
          () =>
              find.byType(CoursesView).evaluate().isNotEmpty &&
              find.textContaining('2 个上课时段').evaluate().isNotEmpty,
        );
        if (Platform.isAndroid) {
          expect((await android())['navigationDark'], dark);
        }
        await capture('home-courses');
        final categoriesRect = tester.getRect(find.byType(AdaptiveTabRow));
        final scrollable = find
            .descendant(
              of: find.byType(CoursesView),
              matching: find.byType(Scrollable),
            )
            .first;
        final scroll = tester.state<ScrollableState>(scrollable).position;
        expect(tester.getTopLeft(scrollable).dy, lessThan(categoriesRect.top));
        for (final fraction in [.45, 1.0]) {
          scroll.jumpTo(scroll.maxScrollExtent * fraction);
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.getRect(find.byType(AdaptiveTabRow)), categoriesRect);
          if (Platform.isAndroid) {
            final snapshot = await android();
            expect(snapshot['headerTabLabels'], ['已添加', '全校', '讲座']);
            expect(snapshot['progress'], 1);
            expect(
              snapshot['toolbarHitHeight'] as num,
              greaterThan(categoriesRect.bottom * tester.view.devicePixelRatio),
            );
          } else {
            final toolbar = tester
                .state<native_toolbar.IOS26NativeToolbarState>(
                  find.byType(native_toolbar.IOS26NativeToolbar).last,
                );
            final snapshot = await toolbar.nativeSnapshot();
            final bounds = snapshot?['tabsBounds'] as List;
            expect(bounds[3], 42);
            expect(
              snapshot?['headerHeight'] as num,
              greaterThan((bounds[1] as num) + (bounds[3] as num)),
            );
            expect(
              ((snapshot?['configuration'] as Map)['scrollOffset'] as num),
              greaterThan(20),
            );
          }
          await capture(
            'courses-header-scroll-${fraction == 1 ? 'end' : 'middle'}',
          );
        }
        scroll.jumpTo(0);
        await tester.pump(const Duration(milliseconds: 400));
        Future<void> category(int index) async {
          if (Platform.isIOS) {
            final toolbar = tester
                .state<native_toolbar.IOS26NativeToolbarState>(
                  find.byType(native_toolbar.IOS26NativeToolbar).last,
                );
            final snapshot = await toolbar.nativeSnapshot();
            expect(snapshot?['tabsRenderer'], 'UISegmentedControl');
            expect(snapshot?['tabsEnabled'], true);
            await toolbar.activateNativeTab(index);
          } else if ((await android())['headerTabLabels'] is List &&
              ((await android())['headerTabLabels'] as List).isNotEmpty) {
            final rect = tester.getRect(find.byType(AdaptiveTabRow));
            final point = Offset(
              rect.left + rect.width * (index + .5) / 3,
              rect.center.dy,
            );
            if (const bool.fromEnvironment('DRIVE_ANDROID_NAV')) {
              final ratio = tester.view.devicePixelRatio;
              debugPrint(
                'HOME_NAV_TAP: ${(point.dx * ratio).round()} ${(point.dy * ratio).round()}',
              );
            } else {
              await tester.tapAt(point);
            }
          } else {
            await tester.tap(
              find.descendant(
                of: find.byType(AdaptiveTabRow),
                matching: find.text(['已添加', '全校', '讲座'][index]),
              ),
            );
          }
          await until(
            () =>
                tester
                    .widget<AdaptiveTabRow>(find.byType(AdaptiveTabRow))
                    .selectedIndex ==
                index,
          );
        }

        if (Platform.isAndroid) {
          await until(() => find.byType(AdaptiveTabRow).evaluate().isNotEmpty);
          for (var i = 0; i < 60; i++) {
            if ((await android())['tabsInputReady'] == true) break;
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
          }
          expect((await android())['tabsVisible'], true);
          expect((await android())['tabsInputReady'], true);
        }
        await category(2);
        await category(0);

        Future<void> courseDetails(String name) async {
          final tile = find.byWidgetPredicate(
            (w) => w is CourseSummaryTile && w.meetings.first.name == '高等数学',
          );
          await tester.tap(
            find.descendant(of: tile, matching: find.text('高等数学')),
          );
          await until(
            () =>
                find.byType(CourseDetailsDialog).evaluate().isNotEmpty &&
                find.text('时段 2').evaluate().isNotEmpty,
          );
          if (Platform.isAndroid) {
            expect((await android())['tabsVisible'], false);
          }
          if (Platform.isIOS) {
            final toolbar = tester
                .state<native_toolbar.IOS26NativeToolbarState>(
                  find.byType(native_toolbar.IOS26NativeToolbar).last,
                );
            expect((await toolbar.nativeSnapshot())?['tabsEnabled'], false);
          }
          await capture(name);
          navigator.currentState!.pop();
          await until(
            () => find.byType(CourseDetailsDialog).evaluate().isEmpty,
          );
        }

        await courseDetails('course-details');

        if (Platform.isAndroid &&
            const bool.fromEnvironment('DRIVE_ANDROID_NAV')) {
          for (var cycle = 0; cycle < 3; cycle++) {
            final before = (await android())['navigationInputEpoch'] as int;
            final rect = tester.getRect(find.byType(ComposeNavigation));
            final ratio = tester.view.devicePixelRatio;
            debugPrint(
              'HOME_INTERRUPT_LOCK: ${(rect.center.dx * ratio).round()} ${(rect.center.dy * ratio).round()} ${((rect.left + rect.width * 5 / 6) * ratio).round()} ${(rect.center.dy * ratio).round()}',
            );
            for (var retry = 0; retry < 120; retry++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 100)),
              );
              await tester.pump();
              if (tester
                      .widget<AdaptiveNavigationShell>(
                        find.byType(AdaptiveNavigationShell),
                      )
                      .selectedIndex ==
                  2) {
                break;
              }
            }
            final resumed = await android();
            debugPrint(
              'HOME_LOCK_RESULT: cycle=$cycle epoch=${resumed['navigationInputEpoch']} selected=${resumed['navigationSelectedIndex']} actions=${resumed['navigationActions']} lastIndex=${resumed['navigationLastIndex']} owner=${resumed['navigationOwner']} downs=${resumed['touchDowns']} ups=${resumed['touchUps']}',
            );
            expect(
              resumed['navigationInputEpoch'],
              greaterThanOrEqualTo(before),
            );
            expect(resumed['resumed'], true);
            expect(resumed['windowFocus'], true);
            expect(
              tester
                  .widget<AdaptiveNavigationShell>(
                    find.byType(AdaptiveNavigationShell),
                  )
                  .selectedIndex,
              2,
            );
            await select(1);
          }
        }
        await select(2);
        await until(() => find.byType(SettingsView).evaluate().isNotEmpty);
        expect(find.text('手动添加'), findsNothing);
        if (Platform.isAndroid) {
          expect((await android())['navigationDark'], dark);
        }
        if (Platform.isAndroid) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 2)),
          );
          await tester.pump();
          final before = (await android())['gpuDrawCount'] as int;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 2)),
          );
          await tester.pump();
          final idle = (await android())['gpuDrawCount'] as int;
          debugPrint('HOME_PROFILE_IDLE_GPU_DRAWS: ${idle - before}');
          expect(idle - before, lessThan(10));
        }
        await capture('home-profile');
        // Open the real About route, allowing the new background to paint beneath cards.
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const AboutView()),
        );
        await until(() => find.byType(RainDropWidget).evaluate().isNotEmpty);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 700)),
        );
        await tester.pump();
        expect(find.byType(AdaptiveSection), findsWidgets);
        if (Platform.isAndroid) {
          for (var i = 0; i < 60; i++) {
            if ((await android())['glassNavigationBars'] == 0) break;
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
          }
          expect((await android())['glassNavigationBars'], 0);
        } else {
          expect(find.byType(platform.IOS26NativeTabBar), findsNothing);
        }
        await capture('about-cards');
        navigator.currentState!.pop();
        await until(() => find.byType(AboutView).evaluate().isEmpty);
        if (Platform.isAndroid) {
          navigator.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => const MoreSettingsView()),
          );
          await until(
            () => find.byType(MoreSettingsView).evaluate().isNotEmpty,
          );
          await preference.setUseOriginalComponents(true);
          navigator.currentState!.pop();
          await until(() => find.byType(MoreSettingsView).evaluate().isEmpty);
          await until(() => find.byType(NavigationBar).evaluate().isNotEmpty);
          final materialRect = tester.getRect(find.byType(NavigationBar));
          final ratio = tester.view.devicePixelRatio;
          expect(
            materialRect.height,
            closeTo(64 + tester.view.padding.bottom / ratio, .5),
          );
          expect(
            materialRect.bottom,
            closeTo(tester.view.physicalSize.height / ratio, .5),
          );
          for (final index in [1, 0, 2]) {
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(['课表', '课程', '我的'][index]),
              ),
            );
            await tester.pump();
            expect(
              tester
                  .widget<AdaptiveNavigationShell>(
                    find.byType(AdaptiveNavigationShell),
                  )
                  .selectedIndex,
              index,
            );
            if (index == 1) {
              await until(
                () => find.byType(CourseSummaryTile).evaluate().isNotEmpty,
              );
              await capture('home-material-courses');
              await courseDetails('course-details-material');
            }
            if (index == 0) {
              expect(
                Theme.of(tester.element(find.byType(NavigationBar))).brightness,
                dark ? Brightness.light : Brightness.dark,
              );
              await capture('home-material-timetable');
            }
          }
          expect(
            Theme.of(tester.element(find.byType(NavigationBar))).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          await capture('home-material-profile');
          navigator.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => const MoreSettingsView()),
          );
          await until(
            () => find.byType(MoreSettingsView).evaluate().isNotEmpty,
          );
          await preference.setUseOriginalComponents(false);
          navigator.currentState!.pop();
          await until(() => find.byType(MoreSettingsView).evaluate().isEmpty);
          await until(
            () => find.byType(ComposeNavigation).evaluate().isNotEmpty,
          );
        }
        await select(0);
        await until(
          () => find
              .textContaining('高等数学', findRichText: true)
              .evaluate()
              .isNotEmpty,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        preference.dispose();
        await tables.delete(table.id!);
        await background.delete();
      } finally {
        semantics.dispose();
        binding.shouldPropagateDevicePointerEvents = previousPointerPolicy;
      }
    }, skip: !Platform.isAndroid && !Platform.isIOS);
  }
}
