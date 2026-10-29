import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Pages/Settings/SettingsView.dart';
import 'package:wheretosleepinnju/Pages/Settings/MoreSettingsView.dart';
import 'package:wheretosleepinnju/Pages/Settings/WidgetSettingsView.dart';
import 'package:wheretosleepinnju/Pages/Settings/BackgroundSettingsView.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/Resources/Colors.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

class _TestDocuments extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = _TestDocuments();
    SharedPreferences.setMockInitialValues({'weekIndex': 8});
    PackageInfo.setMockInitialValues(
      appName: 'WhereToSleepInNJU',
      packageName: 'test',
      version: '4.1.0',
      buildNumber: '71',
      buildSignature: '',
    );
  });
  setUpAll(() async {
    final font = Platform.environment['PLATFORM_UI_PREVIEW_FONT'];
    final icons = Platform.environment['PLATFORM_UI_PREVIEW_ICON_FONT'];
    if (font != null && icons != null) {
      await (FontLoader(
        'Roboto',
      )..addFont(File(font).readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(File(icons).readAsBytes().then(ByteData.sublistView))).load();
    }
  });

  testWidgets(
    'reset course colors preserves the root route and publishes saved colors',
    (tester) async {
      for (final name in ['umeng_common_sdk', 'PonnamKarthik/fluttertoast']) {
        final channel = MethodChannel(name);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => true,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('colorPool', '[0]');
      final model = MainStateModel();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ScopedModel<MainStateModel>(
          model: model,
          child: AdaptiveApp(
            navigatorKey: navigator,
            locale: const Locale('zh', 'CN'),
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: Text('主页')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const MoreSettingsView()),
      );
      await tester.pumpAndSettle();
      String? publishedPool;
      void onRefresh() {
        publishedPool = preferences.getString('colorPool');
      }

      model.addListener(onRefresh);
      addTearDown(() => model.removeListener(onRefresh));
      await tester.ensureVisible(find.text('重置课程颜色'));
      await tester.tap(find.text('重置课程颜色'));
      await tester.pumpAndSettle();
      expect(find.byType(MoreSettingsView), findsOneWidget);
      expect(navigator.currentState!.canPop(), isTrue);
      expect(publishedPool, preferences.getString('colorPool'));
      expect(publishedPool, isNotNull);
      final saved = List<int>.from(jsonDecode(publishedPool!) as List)..sort();
      expect(saved, List<int>.generate(colorList.length, (index) => index));
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('主页'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final entry in <String, Widget>{
    'settings': const SettingsView(),
    'more': const MoreSettingsView(),
    'widget': const WidgetSettingsView(),
    'background': const BackgroundSettingsView(),
  }.entries) {
    testWidgets('${entry.key} page renders in light and dark', (tester) async {
      for (final brightness in Brightness.values) {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ScopedModel<MainStateModel>(
              model: MainStateModel(),
              child: AdaptiveApp(
                materialLightTheme: ThemeData(
                  brightness: brightness,
                  fontFamily: 'Roboto',
                ),
                locale: const Locale('zh', 'CN'),
                supportedLocales: S.delegate.supportedLocales,
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: entry.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(entry.value.runtimeType), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }
}
