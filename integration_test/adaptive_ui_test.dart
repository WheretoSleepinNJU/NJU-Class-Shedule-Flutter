import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
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
    final captured = await waitFor((d) => (d['gpuDrawCount'] as num) > 0);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    final idle = await data();
    expect(
      (idle['gpuDrawCount'] as num) - (captured['gpuDrawCount'] as num),
      lessThanOrEqualTo(3),
      reason: 'Idle chrome must not drive a continuous GPU capture loop',
    );
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
  testWidgets('MIUIX dialogs preserve arbitrary form focus and route results', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AdaptiveUIController();
    final navigator = GlobalKey<NavigatorState>();
    final first = TextEditingController();
    final second = TextEditingController();
    final mode = ValueNotifier(ThemeMode.light);
    var checked = false;
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (_, themeMode, _) => AdaptiveUIApp(
          controller: controller,
          navigatorKey: navigator,
          themeMode: themeMode,
          materialDarkTheme: ThemeData.dark(),
          home: AdaptiveScaffold(
            appBar: const AdaptiveTopAppBar(title: Text('Glass form')),
            body: ListView(
              children: [
                for (var i = 0; i < 20; i++)
                  Container(
                    height: 90,
                    color: Colors.primaries[i % Colors.primaries.length],
                    child: Text(
                      'Background $i',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<Map<Object?, Object?>> waitFor(
      bool Function(Map<Object?, Object?>) ready,
    ) async {
      Map<Object?, Object?> last = {};
      for (var i = 0; i < 80; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        last = (await channel.invokeMapMethod<Object?, Object?>(
          'diagnostics',
        ))!;
        if (ready(last)) return last;
      }
      fail('Dialog native state not reached: $last');
    }

    await waitFor((d) => d['toolbarVisible'] == true);
    final result = showDialog<bool>(
      context: navigator.currentContext!,
      barrierDismissible: false,
      builder: (context) => AdaptiveDialog(
        title: const Text('任意表单 · Flutter MIUIX'),
        scrollable: true,
        content: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('name'),
                  controller: first,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                TextField(
                  key: const ValueKey('note'),
                  controller: second,
                  decoration: const InputDecoration(labelText: '备注'),
                  maxLines: 2,
                ),
                CheckboxListTile(
                  title: const Text('保留表单状态'),
                  value: checked,
                  onChanged: (v) => setState(() => checked = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final native = await waitFor((d) => d['toolbarVisible'] == false);
    expect(native['dialogSurfaces'], 0);
    expect(find.byType(miuix.MiuixOverlayDialog), findsOneWidget);
    expect(native['pixelCopyCount'], 0);
    expect(native['toolbarVisible'], false);
    await tester.enterText(find.byKey(const ValueKey('name')), '未保存的名称');
    await tester.enterText(find.byKey(const ValueKey('note')), 'Flutter 任意内容');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    final fieldState = tester.state(find.byKey(const ValueKey('note')));
    await tester.tap(find.byKey(const ValueKey('note')));
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (MediaQuery.viewInsetsOf(
            tester.element(find.byType(AdaptiveDialog)),
          ).bottom >
          0) {
        break;
      }
    }
    await tester.pumpAndSettle();
    final media = MediaQuery.of(tester.element(find.byType(AdaptiveDialog)));
    expect(media.viewInsets.bottom, greaterThan(0));
    expect(
      tester.getBottomLeft(find.text('保存')).dy,
      lessThan(media.size.height - media.viewInsets.bottom),
    );
    final focus = tester
        .widget<EditableText>(find.byType(EditableText).last)
        .focusNode;
    expect(focus.hasFocus, true);
    await tester.runAsync(() => controller.setUseOriginalComponents(true));
    await tester.pumpAndSettle();
    await waitFor((d) => d['dialogSurfaces'] == 0);
    expect(focus.hasFocus, true);
    expect(first.text, '未保存的名称');
    expect(second.text, 'Flutter 任意内容');
    expect(checked, true);
    expect(
      identical(tester.state(find.byKey(const ValueKey('note'))), fieldState),
      true,
    );
    await tester.runAsync(() => controller.setUseOriginalComponents(false));
    await tester.pumpAndSettle();
    await waitFor((d) => d['toolbarVisible'] == false);
    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(
      identical(tester.state(find.byKey(const ValueKey('note'))), fieldState),
      true,
    );
    expect(
      Theme.of(tester.element(find.byType(AdaptiveDialog))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(await result, true);
    await waitFor(
      (d) => d['dialogSurfaces'] == 0 && d['toolbarVisible'] == true,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    controller.dispose();
    first.dispose();
    second.dispose();
    mode.dispose();
  });
}
