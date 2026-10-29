import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

void main() {
  for (final systemDark in [false, true]) {
    testWidgets(
      'navigation contrast belongs to its page and preserves app palette, dark=$systemDark',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        const channel = MethodChannel('nju/compose-navigation');
        final updates = <Map>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'update') updates.add(call.arguments as Map);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final controller = AdaptiveUIController();
        final theme = AppThemes.build(
          '#872574',
          systemDark ? Brightness.dark : Brightness.light,
          useSeedScheme: true,
        );
        var selected = 0;
        Color? foreground = Colors.white;
        var publish = true;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (_, child) => AdaptiveUIScope(
              controller: controller,
              nativeGlassSupported: true,
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (_, set) {
                update = set;
                return AdaptiveNavigationShell(
                  selectedIndex: selected,
                  onSelected: (index) => set(() => selected = index),
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
                  pages: [
                    if (publish)
                      AdaptiveNavigationAppearance(
                        foregroundColor: foreground,
                        child: const Text('timetable body'),
                      )
                    else
                      const Text('timetable body'),
                    const Text('courses body'),
                    const Text('profile body'),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(updates.last['dark'], true); // White title: dark capsule.
        final owner = updates.last['owner'];
        expect(
          Theme.of(tester.element(find.text('timetable body'))).brightness,
          theme.brightness,
        );
        update(() => selected = 1);
        await tester.pumpAndSettle();
        expect(updates.last['dark'], systemDark);
        update(() {
          selected = 2;
          foreground = Colors.black;
        });
        await tester.pumpAndSettle();
        expect(
          updates.last['dark'],
          systemDark,
        ); // Hidden timetable cannot recolor My.
        update(() => selected = 0);
        await tester.pumpAndSettle();
        expect(updates.last['dark'], false);
        expect(updates.last['owner'], owner);
        final expected = DeadlinerColorTheme.fromSeed(
          seed: const Color(0xff872574),
          brightness: Brightness.light,
          useMonet: true,
        ).toNativeMap();
        expect(updates.last['onSurface'], expected['onSurface']);
        await controller.setUseOriginalComponents(true);
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.light,
        );
        update(() => selected = 1);
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          theme.brightness,
        );
        update(() {
          selected = 0;
          foreground = null;
        });
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          theme.brightness,
        );
        update(() => foreground = Colors.white);
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.dark,
        );
        update(() => publish = false);
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          theme.brightness,
        );
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }
}
