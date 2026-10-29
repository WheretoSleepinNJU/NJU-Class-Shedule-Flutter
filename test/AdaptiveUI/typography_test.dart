import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/adaptive_miuix_theme.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'renderer switch preserves text hierarchy and compact rows at ${scale}x',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = AdaptiveUIController();
        addTearDown(controller.dispose);
        var taps = 0;
        final heights = <double>[];
        for (final miuix in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppThemes.build(
                '#0095F9',
                Brightness.light,
                useSeedScheme: true,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: AdaptiveUIScope(
                  controller: controller,
                  debugMiuix: miuix,
                  child: AdaptiveMiuixTheme(child: child!),
                ),
              ),
              home: Scaffold(
                body: AdaptivePageList(
                  children: [
                    AdaptiveSection(
                      children: [
                        AdaptiveListTile(
                          key: const ValueKey('row'),
                          title: const Text('课表设置'),
                          subtitle: const Text('背景与显示'),
                          leading: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(Icons.settings),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => taps++,
                        ),
                        const AdaptiveListTile(
                          title: Text.rich(
                            TextSpan(
                              text: '关于长文',
                              style: AdaptiveTypography.body,
                            ),
                          ),
                        ),
                        AdaptiveButton.text(
                          onPressed: () {},
                          child: const Text('操作'),
                        ),
                        const AdaptiveTextField(placeholder: '输入', style: null),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          TextStyle rendered(String text) =>
              tester.renderObject<RenderParagraph>(find.text(text)).text.style!;
          expect(rendered('课表设置').fontSize, 16);
          expect(rendered('背景与显示').fontSize, 13);
          expect(rendered('操作').fontSize, 15);
          // Explicit rich text must not be flattened/lost in the MIUIX adapter.
          expect(find.text('关于长文', findRichText: true), findsWidgets);
          final row = tester.getRect(find.byKey(const ValueKey('row')));
          heights.add(row.height);
          expect(row.height, greaterThanOrEqualTo(56));
          if (scale == 1) expect(row.height, lessThanOrEqualTo(72));
          await tester.tap(find.text('课表设置'));
          expect(tester.takeException(), isNull);
        }
        expect(taps, 2);
        expect(heights[0], closeTo(heights[1], 6));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
