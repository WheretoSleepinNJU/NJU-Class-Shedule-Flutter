import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/Pages/Settings/SettingsView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'native_editor_topbar_test.dart' show HoldingProvider;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> verifyAndCapture(
    WidgetTester tester,
    String name,
    bool dark,
  ) async {
    const channel = MethodChannel('nju/compose-titlebar');
    Map<Object?, Object?>? snapshot;
    for (var retry = 0; retry < 80; retry++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      snapshot = await channel.invokeMapMethod<Object?, Object?>('diagnostics');
      if (snapshot?['toolbarVisible'] == true &&
          (snapshot?['gpuDrawCount'] as num? ?? 0) > 0) {
        break;
      }
    }
    expect(snapshot?['toolbarVisible'], true);
    expect(snapshot?['pixelCopyCount'], 0);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_ANDROID_PAGES')) {
      debugPrint('ANDROID_PAGE_READY: $name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 5)),
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'real Android settings and editor use shared cards dark=$dark',
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
          'android-settings-${dark ? 'dark' : 'light'}',
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
          'android-add-${dark ? 'dark' : 'light'}',
          dark,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        preference.dispose();
      },
      skip: !Platform.isAndroid,
    );
  }
}
