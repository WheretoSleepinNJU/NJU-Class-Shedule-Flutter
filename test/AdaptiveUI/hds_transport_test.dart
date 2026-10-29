import 'dart:convert';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/ohos/hds_chrome.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'HDS toolbar serializes structured content, categories and owned metrics',
    (tester) async {
      const channel = MethodChannel('nju/hds-titlebar');
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
      final backend = createHdsToolbarBackend();
      final preference = AdaptiveUIController();
      var selected = 0;
      await tester.pumpWidget(
        AdaptiveUIScope(
          controller: preference,
          child: MaterialApp(
            builder: (context, child) => platform.AdaptiveToolbarHost(
              nativeBackend: backend,
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (context, set) => AdaptiveScaffold(
                appBar: AdaptiveTopAppBar(
                  title: const Text('课程'),
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarIconBrightness: Brightness.light,
                  ),
                  tabs: AdaptiveTabRow(
                    tabs: const ['已添加', '全校', '讲座'],
                    selectedIndex: selected,
                    onSelected: (index) => set(() => selected = index),
                  ),
                ),
                body: const AdaptiveListView(children: [Text('内容')]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Map payload() =>
          jsonDecode(
                (calls.lastWhere((call) => call.method == 'update').arguments
                        as Map)['json']
                    as String,
              )
              as Map;
      final owner = payload()['owner'] as int;
      expect(payload()['tabLabels'], ['已添加', '全校', '讲座']);
      expect(payload()['title'], '课程');
      final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(platform.AdaptiveScaffold),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(overlay.value.statusBarIconBrightness, Brightness.light);
      expect(overlay.value.systemNavigationBarColor, Colors.transparent);
      expect(backend.preferredToolbarHeight, 56);
      Future<void> native(String method, Map data) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, data),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await native('metrics', {'owner': owner, 'height': 106.0});
      expect(backend.height.value, 106);
      await native('metrics', {'owner': owner + 1, 'height': 120.0});
      expect(backend.height.value, 106);
      await native('tab', {'owner': owner, 'index': 2});
      expect(selected, 2);
      await native('tab', {'owner': owner + 1, 'index': 0});
      expect(selected, 2);
      await tester.pumpWidget(const SizedBox());
      expect(calls.last.method, 'hide');
      expect((calls.last.arguments as Map)['owner'], owner);
      preference.dispose();
    },
  );

  testWidgets(
    'HDS navigation owns gestures and rejects stale or hidden callbacks',
    (tester) async {
      const channel = MethodChannel('nju/hds-navigation');
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
      var selected = 0, presses = 0, visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    height: 56,
                    child: HdsNavigation(
                      items: const [
                        {'label': '课表', 'icon': 'Months'},
                        {'label': '课程', 'icon': 'NotesFill'},
                      ],
                      selectedIndex: selected,
                      visible: visible,
                      onSelected: (index) {
                        presses++;
                        set(() => selected = index);
                      },
                      fallback: const Text('fallback'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Map payload() =>
          jsonDecode(
                (calls.lastWhere((call) => call.method == 'update').arguments
                        as Map)['json']
                    as String,
              )
              as Map;
      final owner = payload()['owner'] as int;
      expect(payload()['width'], 240);
      expect(payload()['height'], 56);
      expect(payload()['primary'], isA<int>());
      expect(payload()['onSurface'], isA<int>());
      await tester.tapAt(tester.getRect(find.byType(HdsNavigation)).center);
      await tester.pump();
      expect(
        presses,
        0,
        reason:
            'ArkUI owns physical clicks; Flutter must not dispatch a duplicate.',
      );
      Future<void> native(int sender) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('select', {'owner': sender, 'index': 1}),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await native(owner);
      expect(selected, 1);
      expect(presses, 1);
      await native(owner + 1);
      expect(presses, 1);
      update(() => visible = false);
      await tester.pumpAndSettle();
      expect(payload()['visible'], false);
      await native(owner);
      expect(presses, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'HDS transport failure reports fallback once and stops retrying every frame',
    (tester) async {
      const channel = MethodChannel('nju/hds-titlebar');
      var failures = 0, updates = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'update') {
          updates++;
          throw PlatformException(code: 'HDS_UNAVAILABLE');
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final backend = createHdsToolbarBackend(onUnavailable: () => failures++);
      final preference = AdaptiveUIController();
      await tester.pumpWidget(
        AdaptiveUIScope(
          controller: preference,
          child: MaterialApp(
            builder: (context, child) => platform.AdaptiveToolbarHost(
              nativeBackend: backend,
              child: child!,
            ),
            home: const AdaptiveScaffold(
              appBar: AdaptiveTopAppBar(title: Text('标题')),
              body: Text('内容'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(failures, 1);
      expect(updates, 1);
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );
}
