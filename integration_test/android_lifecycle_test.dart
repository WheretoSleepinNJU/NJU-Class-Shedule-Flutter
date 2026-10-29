import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

/// The host drives real Android MotionEvents, notification shade and lock screen.
/// Set DRIVE_ANDROID_LIFECYCLE and run with the external emulator interaction.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real touches survive focus loss, interrupted presses and repeated unlock',
    (tester) async {
      final binding = tester.binding;
      final previousPointerPolicy = binding.shouldPropagateDevicePointerEvents;
      binding.shouldPropagateDevicePointerEvents = true;
      addTearDown(
        () =>
            binding.shouldPropagateDevicePointerEvents = previousPointerPolicy,
      );
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final navigator = GlobalKey<NavigatorState>();
      final counts = ValueNotifier<(int, int)>((0, 0));
      final homeCounts = ValueNotifier<(int, int)>((0, 0));
      final draft = TextEditingController(text: '恢复后保留的草稿');
      var returned = false, visibleWhileUnfocused = false;
      String? previousTrace;
      counts.addListener(() => debugPrint('ANDROID_COUNTERS: ${counts.value}'));
      await tester.pumpWidget(
        AdaptiveUIApp(
          controller: preference,
          navigatorKey: navigator,
          materialLightTheme: AppThemes.build(
            '#0095F9',
            Brightness.light,
            useSeedScheme: true,
          ),
          materialDarkTheme: AppThemes.build(
            '#0095F9',
            Brightness.dark,
            useSeedScheme: true,
          ),
          home: ValueListenableBuilder<(int, int)>(
            valueListenable: homeCounts,
            builder: (_, value, _) => AdaptiveScaffold(
              appBar: AdaptiveTopAppBar(
                preserveLayout: true,
                title: const Text('入口'),
                actions: [
                  AdaptiveIconButton(
                    tooltip: '嵌入计数',
                    icon: const Icon(Icons.settings),
                    onPressed: () =>
                        homeCounts.value = (value.$1 + 1, value.$2),
                  ),
                ],
              ),
              body: AdaptivePageList(
                children: [
                  AdaptiveSection(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('主页原生:${value.$1} Flutter:${value.$2}'),
                      AdaptiveButton.filled(
                        onPressed: () =>
                            homeCounts.value = (value.$1, value.$2 + 1),
                        child: const Text('主页Flutter计数'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!
          .push(
            MaterialPageRoute<void>(
              builder: (_) => AdaptiveScaffold(
                appBar: AdaptiveTopAppBar(
                  title: const Text('恢复验证'),
                  actions: [
                    AdaptiveTopBarActionButton(
                      label: '原生计数',
                      onPressed: () =>
                          counts.value = (counts.value.$1 + 1, counts.value.$2),
                    ),
                  ],
                ),
                body: AdaptivePageList(
                  children: [
                    AdaptiveSection(
                      padding: const EdgeInsets.all(16),
                      separated: false,
                      children: [
                        ValueListenableBuilder<(int, int)>(
                          valueListenable: counts,
                          builder: (_, value, _) => Text(
                            '原生:${value.$1} Flutter:${value.$2}',
                            key: const ValueKey('lifecycle-counts'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AdaptiveTextField(controller: draft),
                        const SizedBox(height: 16),
                        AdaptiveButton.filled(
                          onPressed: () => counts.value = (
                            counts.value.$1,
                            counts.value.$2 + 1,
                          ),
                          child: const Text('Flutter计数'),
                        ),
                      ],
                    ),
                    const AdaptiveSection(
                      padding: EdgeInsets.all(16),
                      children: [Text('通知栏失焦、锁屏中断按压、连续解锁后，两个按钮都应继续响应。')],
                    ),
                  ],
                ),
              ),
            ),
          )
          .then((_) => returned = true);
      await tester.pumpAndSettle();
      const channel = MethodChannel('nju/compose-titlebar');
      for (var i = 0; i < 80; i++) {
        final snapshot = await channel.invokeMapMethod<Object?, Object?>(
          'diagnostics',
        );
        if (snapshot?['toolbarVisible'] == true) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      debugPrint('ANDROID_LIFECYCLE_READY');
      for (var i = 0; i < 3600 && !returned; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        final snapshot = await channel.invokeMapMethod<Object?, Object?>(
          'diagnostics',
        );
        final trace =
            'lifecycle=${binding.lifecycleState} resumed=${snapshot?['resumed']} focus=${snapshot?['windowFocus']} down=${snapshot?['touchDowns']} up=${snapshot?['touchUps']} actions=${snapshot?['nativeActions']}/${snapshot?['dispatchedActions']} interactive=${snapshot?['interactive']} owner=${snapshot?['owner']}';
        if (trace != previousTrace) {
          debugPrint('WINDOW_TRACE: $trace');
          previousTrace = trace;
        }
        if (snapshot?['windowFocus'] == false &&
            snapshot?['toolbarVisible'] == true) {
          visibleWhileUnfocused = true;
        }
      }
      expect(
        returned,
        true,
        reason: 'Host must tap the real native back button',
      );
      expect(counts.value.$1, greaterThanOrEqualTo(5));
      expect(counts.value.$2, greaterThanOrEqualTo(5));
      expect(visibleWhileUnfocused, true);
      expect(draft.text, '恢复后保留的草稿');
      debugPrint('ANDROID_HOME_READY');
      for (
        var i = 0;
        i < 900 && (homeCounts.value.$1 < 1 || homeCounts.value.$2 < 1);
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      binding.shouldPropagateDevicePointerEvents = previousPointerPolicy;
      expect(homeCounts.value, (1, 1));
      expect(find.text('入口'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      counts.dispose();
      homeCounts.dispose();
      draft.dispose();
      preference.dispose();
    },
    skip:
        !Platform.isAndroid ||
        !const bool.fromEnvironment('DRIVE_ANDROID_LIFECYCLE'),
  );
}
