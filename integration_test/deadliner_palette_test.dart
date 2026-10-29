import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Deadliner tokens reach every renderer across theme and seed changes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preference = AdaptiveUIController();
      final state = ValueNotifier<(String, ThemeMode)>((
        '#0095F9',
        ThemeMode.light,
      ));
      await tester.pumpWidget(
        ValueListenableBuilder<(String, ThemeMode)>(
          valueListenable: state,
          builder: (context, selected, _) => AdaptiveUIApp(
            controller: preference,
            themeMode: selected.$2,
            materialLightTheme: AppThemes.build(
              selected.$1,
              Brightness.light,
              useSeedScheme: true,
            ),
            materialDarkTheme: AppThemes.build(
              selected.$1,
              Brightness.dark,
              useSeedScheme: true,
            ),
            home: AdaptiveScaffold(
              appBar: AdaptiveTopAppBar(
                title: const Text('共享 Deadliner 配色'),
                actions: [
                  AdaptiveTopBarActionButton(label: '完成', onPressed: () {}),
                ],
              ),
              body: const AdaptiveListView(
                children: [
                  AdaptiveCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AdaptiveTextField(
                        key: ValueKey('palette-editor'),
                        placeholder: '保留编辑内容',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('palette-editor')),
        'draft',
      );
      for (final selection in [
        ('#0095F9', ThemeMode.light),
        ('#0095F9', ThemeMode.dark),
        ('#872574', ThemeMode.dark),
        ('#872574', ThemeMode.light),
      ]) {
        state.value = selection;
        await tester.pumpAndSettle();
        final context = tester.element(
          find.byKey(const ValueKey('palette-editor')),
        );
        final theme = Theme.of(context),
            expected = DeadlinerColorTheme.of(Theme.of(context));
        expect(
          miuix.MiuixTheme.of(context).colors.surfaceContainer,
          theme.colorScheme.surfaceContainer,
        );
        expect(
          miuix.MiuixTheme.of(context).colors.primary,
          theme.colorScheme.primary,
        );
        Map<Object?, Object?>? snapshot;
        for (var retry = 0; retry < 60; retry++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
          if (Platform.isAndroid) {
            snapshot = await const MethodChannel(
              'nju/compose-titlebar',
            ).invokeMapMethod<Object?, Object?>('diagnostics');
            final colors = snapshot?['colorSchemes'] as Map?;
            if ((colors?['materialColors'] as Map?)?['primary'] ==
                    theme.colorScheme.primary.toARGB32() &&
                (colors?['materialColors'] as Map?)?['onSurface'] ==
                    theme.colorScheme.onSurface.toARGB32()) {
              break;
            }
          } else if (Platform.isIOS) {
            snapshot = await tester
                .state<IOS26NativeToolbarState>(find.byType(IOS26NativeToolbar))
                .nativeSnapshot();
            final config = snapshot?['configuration'] as Map?;
            if (config?['isDark'] == (theme.brightness == Brightness.dark) &&
                config?['foreground'] ==
                    theme.colorScheme.onSurface.toARGB32()) {
              break;
            }
          }
        }
        if (Platform.isAndroid) {
          final actual = snapshot!['colorSchemes'] as Map;
          final wanted = expected.toNativeMap();
          expect(actual['materialColors'], wanted['materialColors']);
          expect(actual['miuixColors'], wanted['miuixColors']);
        } else if (Platform.isIOS) {
          final config = snapshot!['configuration'] as Map;
          expect(config['foreground'], theme.colorScheme.onSurface.toARGB32());
          expect(config['isDark'], theme.brightness == Brightness.dark);
        }
        if (Platform.isIOS &&
            const bool.fromEnvironment('CAPTURE_DEADLINER_PALETTE')) {
          final name =
              'palette-${selection.$1.substring(1)}-${selection.$2.name}';
          final bytes = await binding.takeScreenshot(name);
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$name.png');
          await file.writeAsBytes(bytes);
          debugPrint('DEADLINER_RENDER_FILE: ${file.path}');
        }
        expect(find.text('draft'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      preference.dispose();
    },
  );
}
