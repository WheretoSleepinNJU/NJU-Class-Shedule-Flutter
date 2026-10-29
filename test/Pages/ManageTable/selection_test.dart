import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/ManageTable/ManageTableView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

class Tables extends CourseTableProvider {
  @override
  Future<List> getAllCourseTable() async => [
    {'id': 1, 'name': '当前学期'},
    {'id': 2, 'name': '下个学期'},
  ];
}

class StateModel extends MainStateModel {
  int? selected;
  @override
  Future<bool> changeclassTable(int id) async {
    selected = id;
    // Deliberately leave preferences stale to exercise the selection/rebuild race.
    return true;
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'table selection is visible and persists on rebuild: $brightness',
      (tester) async {
        SharedPreferences.setMockInitialValues({'tableId': 1});
        final state = StateModel();
        final theme = AppThemes.build(
          '#0095F9',
          brightness,
          useSeedScheme: false,
        );
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: state,
            child: MaterialApp(
              theme: theme,
              locale: const Locale('zh', 'CN'),
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: ManageTableView(provider: Tables()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        AdaptiveListTile tile(String name) => tester.widget<AdaptiveListTile>(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(AdaptiveListTile),
          ),
        );
        expect(tile('当前学期').selected, isTrue);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        final fg = (tile('当前学期').title as Text).style!.color!;
        final bg = theme.colorScheme.primaryContainer;
        final high = fg.computeLuminance() > bg.computeLuminance() ? fg : bg;
        final low = fg.computeLuminance() > bg.computeLuminance() ? bg : fg;
        expect(
          (high.computeLuminance() + .05) / (low.computeLuminance() + .05),
          greaterThan(4.5),
        );
        expect(bg, isNot(theme.colorScheme.surface));
        await tester.tap(find.text('下个学期'));
        await tester.pumpAndSettle();
        expect(state.selected, 2);
        expect(tile('下个学期').selected, isTrue);
        expect(tile('当前学期').selected, isFalse);
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('下个学期'),
              matching: find.byType(AdaptiveListTile),
            ),
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
