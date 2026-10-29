import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportView.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportTestView.dart';
import 'package:wheretosleepinnju/Utils/OnlineImportService.dart';
import 'package:wheretosleepinnju/Utils/ImportTestScript.dart';
import '../EditCourse/edit_course_test.dart' show localized;

void main() {
  testWidgets(
    'offline retry recovers, legacy entry removed, fifth tap unlocks',
    (tester) async {
      var attempts = 0;
      await localized(
        tester,
        (_) => ImportView(
          loadSchools: () async {
            if (++attempts == 1) throw Exception('offline');
            return [
              {'title': '验证大学', 'pinyin': 'yanzheng', 'description': '登录后获取课表'},
            ];
          },
        ),
      );
      expect(find.text('暂时无法获取学校列表'), findsOneWidget);
      expect(find.text('手动导入'), findsNothing);
      expect(find.textContaining('从服务器获取的最新配置'), findsNothing);
      expect(find.byKey(const ValueKey('import-test-button')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('retry-schools')));
      await tester.pumpAndSettle();
      expect(find.text('验证大学'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('import-title')));
        await tester.pump();
      }
      expect(find.byKey(const ValueKey('import-test-button')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('import-title')));
      await tester.pump();
      expect(find.byKey(const ValueKey('import-test-button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('import-test-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ImportTestView), findsOneWidget);
    },
  );

  testWidgets('empty school list has its own retry state', (tester) async {
    await localized(
      tester,
      (_) => ImportView(loadSchools: () async => []),
      scale: 2,
    );
    expect(find.text('暂时没有可用的学校'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-schools')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test config validates and preserves scripts after returning', (
    tester,
  ) async {
    Map<String, dynamic>? received;
    await localized(
      tester,
      (_) => ImportTestView(
        runImport: (c, config) async {
          received = config;
          return false;
        },
      ),
    );
    Future<void> enter(String name, String value) async {
      final field = find.byKey(ValueKey('import-field-$name'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, value);
    }

    Future<void> start() async {
      await tester.ensureVisible(
        find.byKey(const ValueKey('start-import-test')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-import-test')));
      await tester.pumpAndSettle();
    }

    await start();
    expect(received, isNull);
    await enter('initialUrl', 'https://example.edu/login');
    await enter('targetUrl', 'https://example.edu/classes');
    await enter('preExtractJS', 'window.ready = true;');
    await enter('extractJS', 'JSON.stringify({name:"测试", courses:[]})');
    await enter('delayTime', '-1');
    await start();
    expect(received, isNull);
    await enter('delayTime', '2');
    await start();
    expect(received!['redirectUrl'], '');
    expect(received!['delayTime'], 2);
    expect(received!['preExtractJS'], 'window.ready = true;');
    final field = tester.widget<AdaptiveTextFormField>(
      find.byKey(const ValueKey('import-field-extractJS')),
    );
    expect(field.controller!.text, received!['extractJS']);
  });

  final payload = {
    'name': '带"引号"及100% 的课表',
    'courses': [
      {
        'name': '课程 A',
        'weeks': [1, 3],
        'week_time': 2,
        'start_time': 1,
        'time_count': 1,
      },
    ],
  };
  for (final encoded in [
    jsonEncode(payload),
    Uri.encodeComponent(jsonEncode(payload)),
    jsonEncode(Uri.encodeComponent(jsonEncode(payload))),
    jsonEncode(jsonEncode(payload)),
  ]) {
    test('decode raw or webview-wrapped encoded result ${encoded.length}', () {
      expect(decodeOnlineImportResult(encoded), payload);
    });
  }
  test('malformed or missing courses rejected before persistence', () {
    for (final value in [
      'undefined',
      'null',
      '42',
      '{"name":"x","courses":3}',
      '{"courses":[]}',
    ]) {
      expect(() => decodeOnlineImportResult(value), throwsFormatException);
    }
    expect(
      decodeOnlineImportResult(
        jsonEncode({'name': 'legacy', 'courses': jsonEncode(jsonEncode([]))}),
      )['courses'],
      [],
    );
  });
  test('test extraction reports native-wrapped JavaScript exceptions', () {
    final error = jsonEncode({
      '__nju_schedule_extract_error__': true,
      'name': 'Error',
      'message': '请先登录清华研究生教学日历',
    });
    for (final value in [error, jsonEncode(error)]) {
      expect(
        () => validateImportTestExtraction(
          value,
          emptyResultMessage: 'extractJS empty',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('请先登录清华研究生教学日历'),
          ),
        ),
      );
    }
  });
  test(
    'test extraction distinguishes empty completion from timetable data',
    () {
      for (final value in ['', 'null', '"null"', 'undefined']) {
        expect(
          () => validateImportTestExtraction(
            value,
            emptyResultMessage: 'extractJS empty',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'extractJS empty',
            ),
          ),
        );
      }
      final encoded = Uri.encodeComponent(jsonEncode(payload));
      for (final value in [
        encoded,
        jsonEncode(encoded),
        jsonEncode(payload),
        payload,
      ]) {
        validateImportTestExtraction(
          value,
          emptyResultMessage: 'extractJS empty',
        );
        expect(decodeOnlineImportResult(value), payload);
      }
    },
  );
}
