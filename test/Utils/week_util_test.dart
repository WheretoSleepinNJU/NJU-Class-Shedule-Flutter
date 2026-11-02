import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String monday({int offset = 0}) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1 - offset * 7))
        .toIso8601String()
        .split('T')
        .first;
  }

  test(
    'cold startup resets the viewed week without changing the actual week',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': monday(),
        'weekIndex': 6,
        'tmpWeekIndex': 8,
      });
      await WeekUtil.checkWeek(resetDisplayedWeek: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 6);
      expect(prefs.getInt('tmpWeekIndex'), 6);
      expect(prefs.getString('lastWeekMonday'), monday());
    },
  );

  test('same-week foreground checks retain the week being browsed', () async {
    SharedPreferences.setMockInitialValues({
      'lastWeekMonday': monday(),
      'weekIndex': 6,
      'tmpWeekIndex': 8,
    });
    await WeekUtil.checkWeek();
    await WeekUtil.checkWeek();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('weekIndex'), 6);
    expect(prefs.getInt('tmpWeekIndex'), 8);
  });

  test(
    'cold startup advances the calendar week before resetting the view',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': monday(offset: -1),
        'weekIndex': 6,
        'tmpWeekIndex': 12,
      });
      await WeekUtil.checkWeek(resetDisplayedWeek: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 7);
      expect(prefs.getInt('tmpWeekIndex'), 7);
      expect(prefs.getString('lastWeekMonday'), monday());
    },
  );

  test(
    'foreground checks still return to the new current week across Monday',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': monday(offset: -1),
        'weekIndex': 6,
        'tmpWeekIndex': 12,
      });
      await WeekUtil.checkWeek();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 7);
      expect(prefs.getInt('tmpWeekIndex'), 7);
    },
  );

  for (final week in [-2, 0]) {
    test(
      'cold startup keeps pre-semester $week but displays week one',
      () async {
        SharedPreferences.setMockInitialValues({
          'lastWeekMonday': monday(),
          'weekIndex': week,
          'tmpWeekIndex': 8,
        });
        await WeekUtil.checkWeek(resetDisplayedWeek: true);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('weekIndex'), week);
        expect(prefs.getInt('tmpWeekIndex'), 1);
      },
    );
  }

  test(
    'entering the week before semester clamps the cold-start view',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': monday(offset: -1),
        'weekIndex': -1,
        'tmpWeekIndex': 8,
      });
      await WeekUtil.checkWeek(resetDisplayedWeek: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 0);
      expect(prefs.getInt('tmpWeekIndex'), 1);
    },
  );

  test(
    'cold startup repairs a broken anchor while preserving a calibrated week',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': 'invalid',
        'weekIndex': 9,
        'tmpWeekIndex': 15,
      });
      await WeekUtil.checkWeek(resetDisplayedWeek: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 9);
      expect(prefs.getInt('tmpWeekIndex'), 9);
      expect(prefs.getString('lastWeekMonday'), monday());
    },
  );

  test(
    'missing viewed week initializes during an ordinary foreground check',
    () async {
      SharedPreferences.setMockInitialValues({
        'lastWeekMonday': monday(),
        'weekIndex': 6,
      });
      await WeekUtil.checkWeek();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('weekIndex'), 6);
      expect(prefs.getInt('tmpWeekIndex'), 6);
    },
  );
}
