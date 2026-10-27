import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/android/compose_title_bar.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/PlatformSettings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nju/compose-titlebar');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Map latest() => calls.lastWhere((c) => c.method == 'update').arguments as Map;
  Future<void> native(WidgetTester tester, String method, Object data) =>
      tester.runAsync(() async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              const StandardMethodCodec().encodeMethodCall(
                MethodCall(method, data),
              ),
              (_) {},
            );
      });

  testWidgets(
    'fixed backend follows route ownership, callbacks, dialogs and scroll insets',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final backend = createComposeTitleBarBackend();
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => AdaptiveToolbarHost(
            androidBackend: backend,
            debugAndroidToolbar: true,
            child: child!,
          ),
          home: SettingsScaffold(
            title: 'A',
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: '详情',
                onPressed: () => actions++,
              ),
            ],
            body: SettingsListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('item $i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(latest()['title'], 'A');
      expect(latest()['visible'], true);
      expect(latest()['canBack'], false);
      expect(
        tester.getTopLeft(find.text('item 0')).dy,
        greaterThanOrEqualTo(52),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(latest()['scrollOffset'] as double, greaterThan(40));
      final savedOffset = latest()['scrollOffset'];
      final firstOwner = latest()['owner'];
      await native(tester, 'action', {'owner': firstOwner, 'index': 0});
      expect(actions, 1);

      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const SettingsScaffold(
            title: 'B',
            body: SettingsListView(children: [Text('page B')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(latest()['title'], 'B');
      expect(latest()['canBack'], true);
      expect(latest()['scrollOffset'], 0);
      final secondOwner = latest()['owner'];
      await native(tester, 'back', {'owner': secondOwner});
      await tester.pumpAndSettle();
      expect(latest()['title'], 'A');
      expect(latest()['scrollOffset'], savedOffset);
      await native(tester, 'action', {'owner': secondOwner, 'index': 0});
      expect(
        actions,
        1,
      ); // Events from the departed page cannot act on its replacement.

      final context = tester.element(find.byType(ListView));
      final dialog = showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();
      expect(latest()['visible'], false);
      navigator.currentState!.pop();
      await dialog;
      await tester.pumpAndSettle();
      expect(latest()['title'], 'A');
      expect(latest()['visible'], true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(calls.last.method, 'hide');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom title keeps its Flutter AppBar and no backend preserves Material',
    (tester) async {
      final backend = createComposeTitleBarBackend();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AdaptiveToolbarHost(
            androidBackend: backend,
            debugAndroidToolbar: true,
            child: child!,
          ),
          home: const AdaptiveScaffold(
            appBar: AdaptiveAppBar(titleWidget: Text('custom')),
            body: Text('body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(latest()['visible'], false);
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScaffold(title: 'Material', body: Text('legacy')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
    },
  );
  testWidgets('native pages update transparent system bars with the theme', (
    tester,
  ) async {
    final backend = createComposeTitleBarBackend();
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => AdaptiveToolbarHost(
            androidBackend: backend,
            debugAndroidToolbar: true,
            child: child!,
          ),
          home: const SettingsScaffold(title: 'native', body: Text('content')),
        ),
      );
      await tester.pumpAndSettle();
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(AdaptiveScaffold),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.systemStatusBarContrastEnforced, false);
      expect(
        region.value.statusBarIconBrightness,
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );
    }
  });
}
