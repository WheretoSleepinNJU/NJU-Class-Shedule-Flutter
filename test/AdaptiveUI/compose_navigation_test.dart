import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_navigation.dart';

void main() {
  testWidgets(
    'Activity navigation deduplicates geometry, hides and resyncs on resume',
    (tester) async {
      const channel = MethodChannel('nju/compose-navigation');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      late StateSetter update;
      var visible = true;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (_, set) {
              update = set;
              return Center(
                child: SizedBox(
                  width: 240,
                  height: 54,
                  child: ComposeNavigation(
                    items: const [
                      {'label': '课表', 'icon': 'Months'},
                    ],
                    selectedIndex: 0,
                    visible: visible,
                    onSelected: (_) {},
                    fallback: const Text('fallback'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = calls.single.arguments as Map;
      expect(first['width'], 240);
      expect(first['height'], 54);
      update(() {});
      await tester.pumpAndSettle();
      expect(calls.length, 1);
      visible = false;
      update(() {});
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['visible'], false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls.length, 3);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls.last.method, 'hide');
      expect((calls.last.arguments as Map)['owner'], first['owner']);
    },
  );
  testWidgets('replacing an owner cannot remove the new native callback', (
    tester,
  ) async {
    const channel = MethodChannel('nju/compose-navigation');
    final updates = <Map>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'update') updates.add(call.arguments as Map);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    var selections = 0;
    Widget page(String key) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 240,
          height: 54,
          child: ComposeNavigation(
            key: ValueKey(key),
            items: const [
              {'label': '课表', 'icon': 'Months'},
            ],
            selectedIndex: 0,
            visible: true,
            onSelected: (_) => selections++,
            fallback: const Text('fallback'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(page('old'));
    await tester.pumpAndSettle();
    final oldOwner = updates.last['owner'];
    await tester.pumpWidget(page('new'));
    await tester.pumpAndSettle();
    final newOwner = updates.last['owner'];
    expect(newOwner, isNot(oldOwner));
    Future<void> nativeSelect(Object? owner) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('select', {'owner': owner, 'index': 0}),
        ),
        (_) {},
      );
      await tester.pump();
    }

    await nativeSelect(oldOwner);
    expect(selections, 0);
    await nativeSelect(newOwner);
    expect(selections, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'native bounds track a retained route through push and pop transforms',
    (tester) async {
      const channel = MethodChannel('nju/compose-navigation');
      final updates = <Map>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'update') updates.add(call.arguments as Map);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          routes: {'/': (_) => const SizedBox()},
          onGenerateInitialRoutes: (_) => [
            PageRouteBuilder<void>(
              transitionsBuilder: (_, animation, secondaryAnimation, child) =>
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 1,
                      end: .8,
                    ).animate(secondaryAnimation),
                    child: child,
                  ),
              pageBuilder: (_, __, ___) => Center(
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 240,
                    height: 54,
                    child: ComposeNavigation(
                      items: const [
                        {'label': '课表', 'icon': 'Months'},
                      ],
                      selectedIndex: 0,
                      visible: true,
                      onSelected: (_) {},
                      fallback: const Text('fallback'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, __, ___) => const Scaffold(body: Text('Detail')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(
        updates.any((data) => ((data['width'] as num) - 240).abs() > .1),
        true,
      );
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(updates.last['width'], closeTo(240, .01));
      expect(updates.last['height'], closeTo(54, .01));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
