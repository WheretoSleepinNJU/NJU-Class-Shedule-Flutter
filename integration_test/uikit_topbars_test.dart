import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/TimetableHeader.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'native_editor_topbar_test.dart' show HoldingProvider;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> capture(String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UIKIT_RENDER')) return;
    final bytes = await binding.takeScreenshot(name);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$name.png');
    await file.writeAsBytes(bytes);
    debugPrint('UIKIT_RENDER_FILE: ${file.path}');
  }

  Future<Map<Object?, Object?>> snapshot(
    WidgetTester tester,
    bool Function(Map<Object?, Object?>) ready,
  ) async {
    Map<Object?, Object?> last = {};
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      final state = tester.state<IOS26NativeToolbarState>(
        find.byType(IOS26NativeToolbar),
      );
      last = await state.nativeSnapshot() ?? {};
      if (ready(last)) return last;
    }
    fail('UIKit state not reached: $last');
  }

  Future<void> nativeEvent(
    WidgetTester tester,
    String method, [
    Object? data,
  ]) async {
    final state = tester.state<IOS26NativeToolbarState>(
      find.byType(IOS26NativeToolbar),
    );
    await tester.runAsync(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            state.nativeChannelName!,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(method, data),
            ),
            (_) {},
          ),
    );
  }

  AdaptiveUIApp app(
    Widget home,
    AdaptiveUIController preference, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) => AdaptiveUIApp(
    controller: preference,
    navigatorKey: navigatorKey,
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
  void nativeOnly() {
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(CupertinoNavigationBar), findsNothing);
    expect(find.byType(IOS26NativeToolbar), findsOneWidget);
  }

  testWidgets('home title, date, week interaction and settings are all UIKit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preference = AdaptiveUIController();
    final navigator = GlobalKey<NavigatorState>();
    var weekTaps = 0, settingsTaps = 0;
    await tester.pumpWidget(
      app(
        AdaptiveScaffold(
          extendBodyBehindAppBar: true,
          appBar: AdaptiveTopAppBar(
            preserveLayout: true,
            toolbarHeight: 56,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: TimetableHeader(
              displayedWeek: 1,
              currentWeek: 1,
              date: DateTime(2026, 10, 27),
              onTap: () => weekTaps++,
            ),
            actions: [
              IconButton(
                tooltip: '设置',
                icon: const Icon(Icons.settings),
                onPressed: () {
                  settingsTaps++;
                  navigator.currentState!.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdaptiveScaffold(
                        appBar: AdaptiveTopAppBar(title: Text('UIKit 子页面')),
                        body: Text('Back navigation'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: const Center(child: Text('课表内容')),
        ),
        preference,
        navigatorKey: navigator,
      ),
    );
    await tester.pumpAndSettle();
    final data = await snapshot(
      tester,
      (d) => (d['titleWidth'] as num? ?? 0) > 120,
    );
    expect(data['renderer'], 'UINavigationBar');
    expect(data['titleRenderer'], 'UIKit');
    final config = data['configuration'] as Map;
    expect(config['leadingTitle'], true);
    expect(config['subtitle'], contains('2026/10/27'));
    expect((config['actions'] as List).first['icon'], 'gearshape');
    nativeOnly();
    await capture('uikit-home');
    expect(
      find.byType(TimetableHeader),
      findsNothing,
      reason: 'No Flutter title overlay is mounted.',
    );
    await nativeEvent(tester, 'onTitleTapped');
    await nativeEvent(tester, 'onActionTapped', {'index': 0});
    expect(weekTaps, 1);
    expect(settingsTaps, 1);
    await tester.pumpAndSettle();
    final child = await snapshot(tester, (d) => d['title'] == 'UIKit 子页面');
    expect((child['configuration'] as Map)['leading'], '');
    await nativeEvent(tester, 'onLeadingTapped');
    await tester.pumpAndSettle();
    await snapshot(
      tester,
      (d) => (d['configuration'] as Map)['leadingTitle'] == true,
    );
    nativeOnly();
    await tester.runAsync(() => preference.setUseOriginalComponents(true));
    await tester.pumpAndSettle();
    nativeOnly();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    preference.dispose();
  });

  for (final creating in [true, false]) {
    testWidgets(
      'UIKit ${creating ? 'add' : 'edit'} toolbar keeps native saving and footer',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final preference = AdaptiveUIController();
        final provider = HoldingProvider();
        await tester.pumpWidget(
          app(
            EditCourseView(
              tableId: 3,
              classTimeList: const [],
              course: creating
                  ? null
                  : Course(3, '课程', '[1,2]', 1, 1, 0, 1, id: 17),
              presenter: EditCoursePresenter(
                provider: provider,
                refreshWidgets: () async {},
              ),
            ),
            preference,
          ),
        );
        await tester.pumpAndSettle();
        final data = await snapshot(
          tester,
          (d) => d['renderer'] == 'UINavigationBar',
        );
        nativeOnly();
        expect(data['titleRenderer'], 'UIKit');
        await capture('uikit-${creating ? 'add' : 'edit'}');
        expect(
          tester.getTopLeft(find.text('全部')).dy,
          tester.getTopLeft(find.text('单周')).dy,
          reason:
              'Native buttons must keep the original horizontal week-action layout.',
        );
        expect(
          find.byKey(const ValueKey('delete-course')),
          creating ? findsNothing : findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('edit-course-name')),
          'UIKit 未保存内容',
        );
        await tester.pumpAndSettle();
        final field = tester.state(
          find.byKey(const ValueKey('edit-course-name')),
        );
        await nativeEvent(tester, 'onActionTapped', {'index': 0});
        await tester.pump();
        final saving = await snapshot(
          tester,
          (d) =>
              ((d['configuration'] as Map?)?['actions'] as List?)
                  ?.first['loading'] ==
              true,
        );
        nativeOnly();
        expect(saving['actionViews'], contains('UIActivityIndicatorView'));
        await capture('uikit-${creating ? 'add' : 'edit'}-saving');
        await nativeEvent(tester, 'onActionTapped', {'index': 0});
        expect(provider.calls, 1);
        provider.result.complete(false);
        await tester.pumpAndSettle();
        await snapshot(
          tester,
          (d) =>
              (d['configuration'] as Map)['actions'].first['loading'] == false,
        );
        await tester.runAsync(() => preference.setUseOriginalComponents(true));
        await tester.pumpAndSettle();
        nativeOnly();
        expect(
          identical(
            tester.state(find.byKey(const ValueKey('edit-course-name'))),
            field,
          ),
          true,
        );
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(40);
        await tester.pumpAndSettle();
        await snapshot(
          tester,
          (d) => ((d['configuration'] as Map)['scrollOffset'] as num) >= 40,
        );
        expect(tester.getTopLeft(find.byType(ListView)).dy, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        preference.dispose();
      },
    );
  }
}
