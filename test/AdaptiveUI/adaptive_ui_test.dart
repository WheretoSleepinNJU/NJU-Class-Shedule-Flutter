import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('original-component preference survives a new controller', () async {
    final controller = AdaptiveUIController();
    await controller.setUseOriginalComponents(true);
    final restored = AdaptiveUIController();
    await restored.restore();
    expect(restored.useOriginalComponents, true);
    await restored.setUseOriginalComponents(false);
    await controller.restore();
    expect(controller.useOriginalComponents, false);
    controller.dispose();
    restored.dispose();
  });

  testWidgets('renderer toggle preserves form, scroll position and route', (
    tester,
  ) async {
    final preference = AdaptiveUIController();
    final scroll = ScrollController();
    final text = TextEditingController();
    final navigator = GlobalKey<NavigatorState>();
    final calls = <MethodCall>[];
    const channel = MethodChannel('nju/compose-titlebar');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    await tester.pumpWidget(
      AdaptiveUIScope(
        controller: preference,
        child: MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => platform.AdaptiveToolbarHost(
            androidBackend: createComposeTitleBarBackend(),
            debugAndroidToolbar: true,
            child: child!,
          ),
          home: AdaptiveScaffold(
            appBar: const AdaptiveTopAppBar(title: Text('Same page')),
            body: ListView(
              controller: scroll,
              children: [
                const SizedBox(height: 240),
                TextField(controller: text),
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('Row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unsaved input');
    await tester.pumpAndSettle();
    scroll.jumpTo(160);
    await tester.pumpAndSettle();
    // MediaQuery/viewport changes may legitimately replace ScrollPosition;
    // the ScrollableState and the user's scroll offset must survive.
    final scrollState = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final fieldState = tester.state(find.byType(TextField));
    expect(find.byType(AppBar), findsNothing);
    await tester.runAsync(() => preference.setUseOriginalComponents(true));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(text.text, 'unsaved input');
    expect(identical(tester.state(find.byType(TextField)), fieldState), true);
    expect(
      identical(
        tester.state<ScrollableState>(find.byType(Scrollable).first),
        scrollState,
      ),
      true,
    );
    expect(scroll.offset, 160);
    expect(navigator.currentState!.canPop(), false);
    await tester.runAsync(() => preference.setUseOriginalComponents(false));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(identical(tester.state(find.byType(TextField)), fieldState), true);
    expect(
      identical(
        tester.state<ScrollableState>(find.byType(Scrollable).first),
        scrollState,
      ),
      true,
    );
    expect(scroll.offset, 160);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    preference.dispose();
    scroll.dispose();
    text.dispose();
  });

  testWidgets('custom titles and busy actions retain their page contracts', (
    tester,
  ) async {
    var clicked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          appBar: AdaptiveTopAppBar(
            title: GestureDetector(
              onTap: () => clicked++,
              child: const Text('Week selector'),
            ),
            actions: [
              const TextButton(
                key: ValueKey('busy-save'),
                onPressed: null,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          body: const Text('same content'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Week selector'));
    expect(clicked, 1);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('busy-save')))
          .onPressed,
      isNull,
    );
    expect(find.text('same content'), findsOneWidget);
  });
}
