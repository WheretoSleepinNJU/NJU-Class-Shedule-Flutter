import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/ThemeUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/Resources/Colors.dart';
import 'package:wheretosleepinnju/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final value in [
    null,
    '',
    '[',
    '[]',
    '[999]',
    '[0,0,0]',
    '[1.1]',
    '{"bad":true}',
  ]) {
    test('startup repairs unusable color pool: $value', () async {
      SharedPreferences.setMockInitialValues({
        if (value != null) 'colorPool': value,
      });
      await ColorPool.checkColorPool();
      final pool = await ColorPool.getColorPool();
      expect(pool.length, colorList.length);
      expect(pool.toSet(), List.generate(colorList.length, (i) => i).toSet());
      expect(
        (await SharedPreferences.getInstance()).getString('colorPool'),
        isNotNull,
      );
    });
  }
  test('valid palette is retained across startup', () async {
    final pool = List.generate(colorList.length, (i) => i).reversed.toList();
    SharedPreferences.setMockInitialValues({'colorPool': pool.toString()});
    await ColorPool.checkColorPool();
    expect(await ColorPool.getColorPool(), pool);
  });
  for (final prefs in [
    <String, Object>{'lastWeekMonday': 'invalid'},
    <String, Object>{'lastWeekMonday': '2020-01-01'},
    <String, Object>{'weekIndex': 8, 'lastWeekMonday': ''},
  ]) {
    test('startup repairs incomplete week anchor $prefs', () async {
      SharedPreferences.setMockInitialValues(prefs);
      await WeekUtil.checkWeek();
      final sp = await SharedPreferences.getInstance();
      expect(DateTime.tryParse(sp.getString('lastWeekMonday')!), isNotNull);
      expect(sp.getInt('weekIndex'), prefs['weekIndex'] ?? 1);
      expect(sp.getInt('tmpWeekIndex'), prefs['weekIndex'] ?? 1);
    });
  }
  test('custom theme sentinel falls back safely if its color is lost', () {
    expect(normalizeThemeIndex(9, 9, ''), 0);
    expect(normalizeThemeIndex(-1, 9, '#0095F9'), 0);
    expect(normalizeThemeIndex(99, 9, 'bad'), 0);
    expect(normalizeThemeIndex(9, 9, '#0095F9'), 9);
    expect(normalizeThemeIndex(2, 9, ''), 2);
    expect(normalizeThemeModeIndex(99, 3), 0);
  });
  testWidgets('upgraded preferences cannot index past the theme list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'themeIndex': 9,
      'themeCustomColor': '',
      'themeModeIndex': 99,
    });
    await tester.pumpWidget(const MyApp(9, ThemeMode.system, ''));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final model = MainStateModel();
    await model.initThemeState();
    expect(model.themeMode, ThemeMode.system);
  });
  for (final response in [
    '',
    [],
    {'showReview': 'true'},
    {'showReview': false},
  ]) {
    test('malformed rating response is optional: $response', () async {
      SharedPreferences.setMockInitialValues({});
      await InitUtil.showReview(isIOS: true, loadConfig: () async => response);
      expect((await SharedPreferences.getInstance()).getInt('openTimes'), 1);
    });
  }
  test(
    'offline review request cannot escape startup as an unhandled error',
    () async {
      SharedPreferences.setMockInitialValues({});
      await InitUtil.showReview(
        isIOS: true,
        loadConfig: () async => throw const SocketException('offline'),
      );
      expect((await SharedPreferences.getInstance()).getInt('openTimes'), 1);
    },
  );
}
