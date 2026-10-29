import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/Settings/SettingsView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'native_editor_topbar_test.dart' show HoldingProvider;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> verifyAndCapture(
    WidgetTester tester,
    String name,
    bool dark,
  ) async {
    Map<Object?, Object?>? snapshot;
    for (var retry = 0; retry < 80; retry++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      snapshot = await tester
          .state<IOS26NativeToolbarState>(find.byType(IOS26NativeToolbar))
          .nativeSnapshot();
      final config = snapshot?['configuration'] as Map?;
      if (config?['isDark'] == dark &&
          config?['foreground'] == (dark ? 0xfff2f2f2 : 0xff191919)) {
        break;
      }
    }
    expect(snapshot?['renderer'], 'UINavigationBar');
    final config = snapshot?['configuration'] as Map;
    expect(config['isDark'], dark);
    expect(config['foreground'], dark ? 0xfff2f2f2 : 0xff191919);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(CupertinoNavigationBar), findsNothing);
    for (final page in tester.widgetList<CupertinoPageScaffold>(
      find.byType(CupertinoPageScaffold),
    )) {
      expect(page.backgroundColor, Color(dark ? 0xff000000 : 0xfff3f3f3));
    }
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_UIKIT_PAGES')) {
      final bytes = await binding.takeScreenshot(name);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$name.png');
      await file.writeAsBytes(bytes);
      debugPrint('UIKIT_PAGE_FILE: ${file.path}');
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'real UIKit settings and editor use Deadliner colors dark=$dark',
      (tester) async {
        SharedPreferences.setMockInitialValues({'weekIndex': 1});
        final preference = AdaptiveUIController();
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: MainStateModel(),
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
              home: const SettingsView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await verifyAndCapture(
          tester,
          'ios-settings-${dark ? 'dark' : 'light'}',
          dark,
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => EditCourseView(
              tableId: 3,
              classTimeList: const [],
              presenter: EditCoursePresenter(
                provider: HoldingProvider(),
                refreshWidgets: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('edit-course-name')), findsOneWidget);
        await verifyAndCapture(
          tester,
          'ios-add-${dark ? 'dark' : 'light'}',
          dark,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        preference.dispose();
      },
      skip: !Platform.isIOS,
    );
  }
}
