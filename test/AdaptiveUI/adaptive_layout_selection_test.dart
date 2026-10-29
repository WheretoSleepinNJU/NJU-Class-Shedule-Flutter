import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/adaptive_miuix_theme.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final miuix in [false, true]) {
    for (final rtl in [false, true]) {
      testWidgets(
        'long trailing values and popup options fit 320px at 2x text miuix=$miuix rtl=$rtl',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final preference = AdaptiveUIController();
          var value = 1;
          const label = '右侧当前选项的完整名称';
          const option = '这是一条很长的候选选项，需要换行才能完整显示末尾';
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
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(
                  textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: AdaptiveUIScope(
                    controller: preference,
                    debugMiuix: miuix,
                    child: AdaptiveMiuixTheme(child: child!),
                  ),
                ),
              ),
              home: StatefulBuilder(
                builder: (_, update) => AdaptiveScaffold(
                  body: AdaptivePageList(
                    children: [
                      AdaptiveSection(
                        children: [
                          AdaptiveListTile(
                            title: const Text('设置名称'),
                            subtitle: const Text('说明也可以换行'),
                            trailing: AdaptiveDropdown<int>(
                              value: value,
                              items: const [
                                AdaptiveOption(value: 1, child: Text(label)),
                                AdaptiveOption(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      Icon(Icons.settings),
                                      Text(
                                        option,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (next) => update(() => value = next!),
                            ),
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
          expect(tester.takeException(), isNull);
          final closed = tester.getRect(find.text(label));
          expect(closed.left, greaterThanOrEqualTo(16));
          expect(closed.right, lessThanOrEqualTo(304));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          final text = find.text(option);
          final rect = tester.getRect(text);
          expect(rect.left, greaterThanOrEqualTo(12));
          expect(rect.right, lessThanOrEqualTo(308));
          expect(
            tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
            false,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text(option), findsNothing);
          expect(value, 1);
          expect(find.text('设置名称'), findsOneWidget);
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          await tester.ensureVisible(text);
          await tester.tap(text);
          await tester.pumpAndSettle();
          expect(value, 2);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          preference.dispose();
        },
      );
    }
  }
  testWidgets(
    'wide pages share one bounded content column and semantic cards',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffold(
            body: AdaptivePageList(
              children: [
                AdaptiveSection(
                  title: Text('分组'),
                  children: [AdaptiveListTile(title: Text('内容'))],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(AdaptiveCard));
      expect(card.width, 760 - 32);
      expect(card.center.dx, 700);
      expect(tester.takeException(), isNull);
    },
  );
}
