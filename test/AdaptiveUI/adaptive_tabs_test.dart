import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_navigation.dart';

void main() {
  testWidgets(
    'page tabs and home navigation retain independent native owners and callbacks',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String, List<MethodCall>>{};
      for (final name in ['nju/compose-navigation', 'nju/compose-tabs']) {
        calls[name] = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(name),
          (call) async {
            calls[name]!.add(call);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            MethodChannel(name),
            null,
          ),
        );
      }
      final preference = AdaptiveUIController();
      var selected = 0, navTaps = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => AdaptiveUIScope(
            controller: preference,
            nativeGlassSupported: true,
            child: child!,
          ),
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return Scaffold(
                body: Column(
                  children: [
                    AdaptiveTabRow(
                      tabs: const ['已添加', '全校', '讲座'],
                      selectedIndex: selected,
                      onSelected: (index) => set(() => selected = index),
                    ),
                    SizedBox(
                      width: 240,
                      height: 54,
                      child: ComposeNavigation(
                        items: const [
                          {'label': '主页', 'icon': 'Months'},
                        ],
                        selectedIndex: 0,
                        visible: true,
                        onSelected: (_) => navTaps++,
                        fallback: const Text('fallback'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Map lastUpdate(String channel) =>
          calls[channel]!.lastWhere((call) => call.method == 'update').arguments
              as Map;
      final tabsOwner = lastUpdate('nju/compose-tabs')['owner'];
      final navOwner = lastUpdate('nju/compose-navigation')['owner'];
      expect(tabsOwner, isNot(navOwner));
      Future<void> select(String name, Object owner, int index) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('select', {'owner': owner, 'index': index}),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await select('nju/compose-tabs', tabsOwner, 2);
      expect(selected, 2);
      expect(navTaps, 0);
      await select('nju/compose-navigation', navOwner, 0);
      expect(navTaps, 1);
      final context = tester.element(find.byType(AdaptiveTabRow));
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('popup')),
      );
      await tester.pumpAndSettle();
      expect(lastUpdate('nju/compose-tabs')['visible'], false);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(lastUpdate('nju/compose-tabs')['visible'], true);
      await preference.setUseOriginalComponents(true);
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      await select('nju/compose-navigation', navOwner, 0);
      expect(
        navTaps,
        2,
        reason: 'Disposing page tabs cannot unregister the home handler.',
      );
      update(() => selected = 1);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
            .selected,
        {1},
      );
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );

  testWidgets('tabs fit narrow screens at large text without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 600),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AdaptiveTabRow(
                tabs: const ['已添加', '全校', '讲座'],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(AdaptiveTabRow)).right,
      lessThanOrEqualTo(304),
    );
  });
}
