import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/ManageTable/ManageTableView.dart';
import 'package:wheretosleepinnju/Resources/Constant.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import '../EditCourse/edit_course_test.dart' show localized;

class Tables extends CourseTableProvider {
  final savedTimes = <int, List<Map>>{};

  @override
  Future<List<Map>> getClassTimeList(int id) async =>
      savedTimes[id] ?? Constant.CLASS_TIME_LIST;

  @override
  Future<bool> updateClassTimeList(int id, List<Map> times) async {
    savedTimes[id] = times;
    return true;
  }

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
  testWidgets('class times save per timetable and reload when reopened', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'tableId': 1});
    final state = StateModel();
    final tables = Tables();
    await localized(
      tester,
      (_) => ScopedModel<MainStateModel>(
        model: state,
        child: ManageTableView(provider: tables),
      ),
    );

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final edit = find.byKey(const ValueKey('edit-class-times-1'));
    final input = find.byType(TextField);
    final save = find.text('保存');
    await tap(edit);
    final defaultTimes = Constant.CLASS_TIME_LIST
        .map((time) => "${time['start']}-${time['end']}")
        .join('\n');
    expect(tester.widget<TextField>(input).controller!.text, defaultTimes);
    await tester.enterText(input, '08:00-08:45');
    await tap(save);
    expect(tables.savedTimes, isEmpty);
    expect(tester.widget<TextField>(input).decoration!.errorText, isNotNull);

    for (final invalidPeriod in ['07:00-07:50', '08:40-09:50']) {
      await tester.enterText(
        input,
        defaultTimes.replaceFirst('09:00-09:50', invalidPeriod),
      );
      await tap(save);
      expect(tables.savedTimes, isEmpty);
      expect(tester.widget<TextField>(input).decoration!.errorText, isNotNull);
    }

    await tap(find.text('FDU'));
    await tap(save);
    expect(tables.savedTimes.keys, [1]);
    expect(tables.savedTimes[1], hasLength(13));
    expect(tables.savedTimes[1]!.last, {'start': '20:20', 'end': '21:05'});
    expect(state.selected, 1);

    await tap(edit);
    final reopenedTimes = tester.widget<TextField>(input).controller!.text;
    expect(reopenedTimes, startsWith('08:00-08:45\n'));
    await tester.enterText(input, reopenedTimes.replaceFirst('08:00', '08:05'));
    await tap(save);
    expect(tables.savedTimes[1]!.first, {'start': '08:05', 'end': '08:45'});

    await tap(edit);
    await tap(find.text('NJU'));
    await tap(save);
    expect(tables.savedTimes[1], Constant.CLASS_TIME_LIST);
  });

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
        ListTile tile(String name) => tester.widget<ListTile>(
          find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
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
              matching: find.byType(ListTile),
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
