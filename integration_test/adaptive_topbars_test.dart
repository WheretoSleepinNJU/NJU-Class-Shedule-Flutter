import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nju/compose-titlebar');
  Future<Map<Object?, Object?>> waitFor(
    WidgetTester tester,
    bool Function(Map<Object?, Object?>) ready,
  ) async {
    Map<Object?, Object?> last = {};
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      last = (await channel.invokeMapMethod<Object?, Object?>('diagnostics'))!;
      if (ready(last)) return last;
    }
    fail('Native state not reached: $last');
  }

  Future<void> nativeEvent(
    WidgetTester tester,
    String method,
    Map<String, Object?> data,
  ) async {
    await tester.runAsync(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(method, data),
            ),
            (_) {},
          ),
    );
  }

  testWidgets(
    'custom title, text action and footer require the complete native toolbar',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final navigator = GlobalKey<NavigatorState>();
      final scroll = ScrollController();
      final text = TextEditingController();
      final busy = ValueNotifier(false);
      var titleTaps = 0;
      await tester.pumpWidget(
        AdaptiveUIApp(
          controller: preference,
          navigatorKey: navigator,
          home: ValueListenableBuilder<bool>(
            valueListenable: busy,
            builder: (context, saving, _) => AdaptiveScaffold(
              appBar: AdaptiveTopAppBar(
                title: GestureDetector(
                  onTap: () => titleTaps++,
                  child: const Text('Custom title'),
                ),
                actions: [
                  AdaptiveTopBarActionButton(
                    buttonKey: const ValueKey('save'),
                    label: 'Save',
                    onPressed: saving ? null : () => busy.value = true,
                    loading: saving,
                  ),
                ],
              ),
              bottomNavigationBar: const SafeArea(
                top: false,
                child: Text('Fixed footer'),
              ),
              body: SafeArea(
                child: AdaptiveListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(12),
                  children: [
                    const SizedBox(
                      key: ValueKey('first'),
                      height: 60,
                      child: Text('First row'),
                    ),
                    TextField(controller: text),
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 60, child: Text('Item $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final data = await waitFor(
        tester,
        (d) => d['toolbarVisible'] == true && d['title'] == 'Custom title',
      );
      expect(find.byType(AppBar), findsNothing);
      expect(
        data['glassTopBars'],
        0,
        reason: 'A glass background behind Flutter chrome is insufficient.',
      );
      expect(find.text('Fixed footer'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(ListView)).dy, 0);
      final barBottom = AdaptiveContentInsets.topOf(
        tester.element(find.byType(AdaptiveListView)),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('first'))).dy,
        closeTo(barBottom + 12, 1),
      );
      scroll.jumpTo(16);
      await tester.pumpAndSettle();
      await waitFor(tester, (d) => (d['progress'] as num? ?? 0) > .49);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('first'))).dy,
        lessThan(barBottom),
      );
      await tester.enterText(find.byType(TextField), 'unsaved form');
      await tester.pumpAndSettle();
      final field = tester.state(find.byType(TextField));
      final owner = (await channel.invokeMapMethod('diagnostics'))!['owner'];
      await nativeEvent(tester, 'title', {'owner': owner});
      await nativeEvent(tester, 'action', {'owner': owner, 'index': 0});
      await tester.pump();
      expect(titleTaps, 1);
      await waitFor(
        tester,
        (d) => (d['actions'] as List).first['loading'] == true,
      );
      expect(find.byType(AppBar), findsNothing);
      await tester.runAsync(() => preference.setUseOriginalComponents(true));
      await tester.pump();
      await waitFor(tester, (d) => d['toolbarVisible'] == false);
      expect(find.byType(AppBar), findsOneWidget);
      expect(identical(tester.state(find.byType(TextField)), field), true);
      expect(text.text, 'unsaved form');
      await tester.runAsync(() => preference.setUseOriginalComponents(false));
      await tester.pump();
      await waitFor(tester, (d) => d['toolbarVisible'] == true);
      expect(find.byType(AppBar), findsNothing);
      expect(identical(tester.state(find.byType(TextField)), field), true);
      expect(
        (await channel.invokeMapMethod('diagnostics'))!['pixelCopyCount'],
        0,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      preference.dispose();
      scroll.dispose();
      text.dispose();
      busy.dispose();
    },
  );

  testWidgets(
    'floating home title stays in place with a native glass settings action',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final navigator = GlobalKey<NavigatorState>();
      var opened = 0;
      await tester.pumpWidget(
        AdaptiveUIApp(
          controller: preference,
          navigatorKey: navigator,
          home: AdaptiveScaffold(
            extendBodyBehindAppBar: true,
            appBar: AdaptiveTopAppBar(
              preserveLayout: true,
              toolbarHeight: 56,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: const Column(
                key: ValueKey('week-title'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Week 1'), Text('2026/10/27')],
              ),
              actions: [
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    opened++;
                    navigator.currentState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdaptiveScaffold(
                          appBar: AdaptiveTopAppBar(
                            title: Text('Settings route'),
                          ),
                          body: AdaptiveListView(
                            children: [Text('Settings content')],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: const SizedBox.expand(key: ValueKey('home-body')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        (d) => d['glassIconButtons'] == 1 && d['dialogBackdropReady'] == true,
      );
      final header = tester.getRect(find.byKey(const ValueKey('week-title')));
      final body = tester.getRect(find.byKey(const ValueKey('home-body')));
      expect(body.top, 0);
      expect(
        (await channel.invokeMapMethod('diagnostics'))!['glassTopBars'],
        0,
      );
      await tester.runAsync(() => preference.setUseOriginalComponents(true));
      await tester.pumpAndSettle();
      await waitFor(tester, (d) => d['glassIconButtons'] == 0);
      expect(tester.getRect(find.byKey(const ValueKey('week-title'))), header);
      expect(tester.getRect(find.byKey(const ValueKey('home-body'))), body);
      await tester.runAsync(() => preference.setUseOriginalComponents(false));
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        (d) => d['glassIconButtons'] == 1 && d['dialogBackdropReady'] == true,
      );
      await tester.tap(find.byType(PlatformViewLink));
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        (d) =>
            d['toolbarVisible'] == true &&
            d['title'] == 'Settings route' &&
            d['glassIconButtons'] == 0,
      );
      expect(opened, 1);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        (d) => d['glassIconButtons'] == 1 && d['dialogBackdropReady'] == true,
      );
      expect(tester.getRect(find.byKey(const ValueKey('week-title'))), header);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      preference.dispose();
    },
  );
}
