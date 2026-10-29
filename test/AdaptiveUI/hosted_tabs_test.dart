import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_navigation.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_title_bar.dart';

void main() {
  testWidgets(
    'hosted categories share native header, insets, owner and preserved list state',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final scroll = ScrollController();
      final lectureScroll = ScrollController();
      final calls = <MethodCall>[];
      const channel = MethodChannel('nju/compose-titlebar');
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
      final backend = createComposeTitleBarBackend();
      var selected = 0;
      await tester.pumpWidget(
        AdaptiveUIScope(
          controller: preference,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24),
                viewPadding: const EdgeInsets.only(top: 24),
              ),
              child: platform.AdaptiveToolbarHost(
                nativeBackend: backend,
                child: child!,
              ),
            ),
            home: StatefulBuilder(
              builder: (context, set) => AdaptiveScaffold(
                appBar: AdaptiveTopAppBar(
                  title: const Text('课程'),
                  tabs: AdaptiveTabRow(
                    tabs: const ['已添加', '全校', '讲座'],
                    selectedIndex: selected,
                    onSelected: (index) => set(() => selected = index),
                  ),
                ),
                body: IndexedStack(
                  index: selected,
                  children: [
                    AdaptiveListView(
                      controller: scroll,
                      padding: EdgeInsets.zero,
                      children: [
                        for (var i = 0; i < 30; i++)
                          SizedBox(height: 80, child: Text('课程 $i')),
                      ],
                    ),
                    const SizedBox.shrink(),
                    AdaptiveListView(
                      controller: lectureScroll,
                      children: [
                        for (var i = 0; i < 30; i++)
                          SizedBox(height: 80, child: Text('讲座 $i')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Map update() =>
          calls.lastWhere((call) => call.method == 'update').arguments as Map;
      final owner = update()['owner'];
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

      await native('metrics', {'owner': owner, 'height': 102.0});
      expect(tester.getTopLeft(find.byType(Scrollable)).dy, 0);
      expect(tester.getTopLeft(find.text('课程 0')).dy, 126);
      expect(find.byType(ComposeTabRow), findsNothing);
      final tabs = tester.getRect(find.byType(AdaptiveTabRow));
      expect(tabs.top, 76);
      scroll.jumpTo(180);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(AdaptiveTabRow)), tabs);
      await native('tab', {'owner': owner, 'index': 2});
      expect(selected, 2);
      await native('tab', {'owner': owner + 1, 'index': 0});
      await native('tab', {'owner': owner, 'index': 10});
      expect(selected, 2);
      expect(update()['scrollOffset'], 0);
      lectureScroll.jumpTo(90);
      await tester.pumpAndSettle();
      await native('tab', {'owner': owner, 'index': 0});
      expect(update()['scrollOffset'], 180);
      expect(scroll.offset, 180);
      await native('tab', {'owner': owner, 'index': 2});
      expect(update()['scrollOffset'], 90);
      expect(lectureScroll.offset, 90);
      await native('tab', {'owner': owner, 'index': 0});
      final scrollState = tester.state(find.byType(Scrollable));
      await preference.setUseOriginalComponents(true);
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(
        identical(tester.state(find.byType(Scrollable)), scrollState),
        true,
      );
      expect(scroll.offset, 180);
      await preference.setUseOriginalComponents(false);
      await tester.pumpAndSettle();
      expect(
        identical(tester.state(find.byType(Scrollable)), scrollState),
        true,
      );
      expect(scroll.offset, 180);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      lectureScroll.dispose();
      preference.dispose();
    },
  );
}
