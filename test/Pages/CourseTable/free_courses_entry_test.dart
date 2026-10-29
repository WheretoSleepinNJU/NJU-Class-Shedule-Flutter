import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/adaptive_miuix_theme.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/FreeCoursesEntry.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'background palette colors only the entry; missing image restores surface ($brightness)',
      (tester) async {
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: brightness,
          ),
        );
        for (final seed in ['#336699', '#aa5522', null]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              locale: const Locale('zh', 'CN'),
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: FreeCoursesEntry(
                  count: 1,
                  onTap: () {},
                  backgroundSeed: seed,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = tester.widget<AdaptiveCard>(find.byType(AdaptiveCard));
          final expected = seed == null
              ? theme.colorScheme.surfaceContainer
              : ColorScheme.fromSeed(
                  seedColor: Color(
                    int.parse(seed.substring(1), radix: 16) | 0xff000000,
                  ),
                  brightness: brightness,
                ).primaryContainer;
          expect(card.color, expected);
          expect(
            Theme.of(
              tester.element(find.byType(FreeCoursesEntry)),
            ).colorScheme.primary,
            theme.colorScheme.primary,
          );
        }
      },
    );
  }
  for (final original in [false, true]) {
    testWidgets(
      'compact entry remains tappable at 320dp and large text, original=$original',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        final controller = AdaptiveUIController(
          useOriginalComponents: original,
        );
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            builder: (_, child) => AdaptiveUIScope(
              controller: controller,
              debugMiuix: true,
              child: AdaptiveMiuixTheme(
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 640),
                    textScaler: TextScaler.linear(2),
                  ),
                  child: child!,
                ),
              ),
            ),
            home: Scaffold(
              body: FreeCoursesEntry(count: 128, onTap: () => taps++),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(FreeCoursesEntry)).height,
          FreeCoursesEntry.extent(const TextScaler.linear(2)),
        );
        expect(find.text('自由时间课程 · 128 门'), findsOneWidget);
        await tester.tap(find.text('查看'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.schedule_rounded));
        await tester.pumpAndSettle();
        expect(taps, 2);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }
}
