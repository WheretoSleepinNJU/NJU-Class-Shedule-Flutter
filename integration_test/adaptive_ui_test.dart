import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/PlatformSettings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nju/compose-titlebar');
  testWidgets('adaptive GPU top bars preserve page state when reverting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AdaptiveUIController();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      AdaptiveUIApp(
        controller: controller,
        navigatorKey: navigator,
        themeMode: ThemeMode.light,
        home: SettingsScaffold(
          title: 'Adaptive page',
          body: SettingsListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AdaptiveAppearanceSwitch(),
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('Row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<Map<Object?, Object?>> data() async =>
        (await channel.invokeMapMethod<Object?, Object?>('diagnostics'))!;
    Future<Map<Object?, Object?>> waitFor(
      bool Function(Map<Object?, Object?>) ready,
    ) async {
      Map<Object?, Object?> last = {};
      for (var i = 0; i < 50; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        last = await data();
        if (ready(last)) return last;
      }
      fail('Native state not reached: $last');
    }

    final first = await waitFor((d) => d['toolbarVisible'] == true);
    expect(first['transport'], 'gpu-layer');
    expect(first['pixelCopyCount'], 0);
    expect(find.byType(AppBar), findsNothing);
    final scrollState = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final scroll = scrollState.position;
    scroll.jumpTo(16);
    await tester.pumpAndSettle();
    final middle = await waitFor((d) => (d['progress'] as num? ?? 0) > .49);
    expect(middle['progress'] as num, closeTo(.5, .01));
    await tester.runAsync(() => controller.setUseOriginalComponents(true));
    await tester.pumpAndSettle();
    await waitFor((d) => d['toolbarVisible'] == false);
    expect(find.byType(AppBar), findsOneWidget);
    final revertedScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    debugPrint(
      'Revert keeps ScrollableState: ${identical(scrollState, revertedScroll)}, offset: ${revertedScroll.position.pixels}',
    );
    expect(identical(scrollState, revertedScroll), true);
    expect(revertedScroll.position.pixels, 16);
    await tester.runAsync(() => controller.setUseOriginalComponents(false));
    await tester.pumpAndSettle();
    await waitFor((d) => d['toolbarVisible'] == true);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      16,
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const AdaptiveScaffold(
          appBar: AdaptiveTopAppBar(title: Text('Second page')),
          body: Text('same layout'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      (await waitFor((d) => d['title'] == 'Second page'))['canBack'],
      true,
    );
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await waitFor((d) => d['title'] == 'Adaptive page');
    final dialog = showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    await waitFor((d) => d['toolbarVisible'] == false);
    navigator.currentState!.pop();
    await dialog;
    await tester.pumpAndSettle();
    await waitFor((d) => d['toolbarVisible'] == true);
    expect((await data())['pixelCopyCount'], 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    controller.dispose();
  });
}
