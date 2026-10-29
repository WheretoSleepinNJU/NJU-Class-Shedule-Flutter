import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/WeekChanger.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

class _Model extends MainStateModel {
  var reads = 0;
  @override
  Future<int> getWeek() async {
    reads++;
    return 1;
  }
}

void main() {
  testWidgets('profile week is cached until the model actually changes', (
    tester,
  ) async {
    final model = _Model();
    late StateSetter update;
    await tester.pumpWidget(
      ScopedModel<MainStateModel>(
        model: model,
        child: MaterialApp(
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StatefulBuilder(
            builder: (_, set) {
              update = set;
              // Deliberately allocate a parent widget to exercise unrelated rebuilds.
              // ignore: prefer_const_constructors
              return Scaffold(body: WeekChanger());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = model.reads;
    expect(initial, greaterThan(0));
    update(() {});
    await tester.pumpAndSettle();
    expect(model.reads, initial);
    model.refresh();
    await tester.pumpAndSettle();
    expect(model.reads, greaterThan(initial));
  });
}
