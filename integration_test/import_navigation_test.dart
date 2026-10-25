import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportFromBEView.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const selectedCases = String.fromEnvironment('QA_IMPORT_CASES');
  for (final navigation in [
    'replaceState after load',
    'pushState after load',
    'replaceState during load',
    'full page navigation',
    'redirect from SPA',
    'manual extraction',
    'pre runtime error',
    'pre syntax error',
    'extract runtime error',
    'extract syntax error',
    'missing extraction return',
  ]) {
    if (selectedCases.isNotEmpty &&
        !selectedCases.split(',').contains(navigation)) {
      continue;
    }
    testWidgets('imports after $navigation', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final previousTable = prefs.getInt('tableId');
      final tables = CourseTableProvider();
      final originalIds =
          (await tables.getAllCourseTable()).map((row) => row['id']).toSet();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final expectsError =
          navigation.startsWith('pre ') ||
          navigation.startsWith('extract ') ||
          navigation == 'missing extraction return';
      const courseName = '匿名课程 "引号" 100% & \\ 换行\n🙂';
      final payload = jsonEncode({
        'name': 'QA SPA portal',
        'courses': [
          {
            'name': courseName,
            'weeks': [1, 2],
            'week_time': 2,
            'start_time': 3,
            'time_count': 1,
          },
        ],
      });
      var calendarRequests = 0;
      server.listen((request) async {
        request.response.headers.contentType = ContentType.html;
        if (request.uri.path == '/login') {
          final portal =
              navigation == 'redirect from SPA'
                  ? '/portal/ready'
                  : '/f/info_mobile/studentIndex';
          final action =
              navigation == 'full page navigation'
                  ? 'window.location.replace("$portal");'
                  : 'history.${navigation == 'pushState after load' ? 'pushState' : 'replaceState'}(null, "", "$portal");';
          final script =
              navigation == 'manual extraction'
                  ? ''
                  : navigation == 'replaceState during load'
                  ? action
                  : 'setTimeout(() => { $action }, 1000);';
          request.response.write('''
<html><head><meta name="viewport" content="width=device-width"></head>
<body><h3>信息门户 · 匿名验证</h3><p>当前页面已加载</p><script>
$script
</script></body></html>
''');
        } else {
          if (request.uri.path == '/calendar') calendarRequests++;
          request.response.write('<html><body>Calendar ready</body></html>');
        }
        await request.response.close();
      });

      try {
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: MainStateModel(),
            child: MaterialApp(
              locale: const Locale('zh', 'CN'),
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed:
                              () => Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ImportFromBEView(
                                        testMode: true,
                                        config: {
                                          'page_title': 'SPA import regression',
                                          'initialUrl': '$base/login',
                                          'redirectUrl':
                                              navigation == 'redirect from SPA'
                                                  ? '$base/portal/'
                                                  : '',
                                          'targetUrl': '$base/f/info_mobile/',
                                          'preExtractJS':
                                              navigation == 'pre runtime error'
                                                  ? 'throw new Error("QA pre runtime");'
                                                  : navigation ==
                                                      'pre syntax error'
                                                  ? 'function ('
                                                  : 'if (document.readyState !== "complete") throw new Error("preExtractJS ran before page finished"); window.location.replace("$base/calendar");',
                                          'delayTime': 2,
                                          'extractJS':
                                              navigation ==
                                                      'extract runtime error'
                                                  ? 'throw new Error("请先登录清华研究生教学日历");'
                                                  : navigation ==
                                                      'extract syntax error'
                                                  ? 'function ('
                                                  : navigation ==
                                                      'missing extraction return'
                                                  ? 'function scheduleHtmlParser() { return "unused"; }'
                                                  : 'if (window.location.pathname !== "/calendar" || document.readyState !== "complete") throw new Error("calendar is not ready"); encodeURIComponent(JSON.stringify($payload))',
                                        },
                                      ),
                                ),
                              ),
                          child: const Text('Open import'),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open import'));
        if (navigation == 'manual extraction') {
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            if (find
                .text(S.current.import_test_waiting_url)
                .evaluate()
                .isNotEmpty) {
              break;
            }
          }
          expect(find.text(S.current.import_test_waiting_url), findsOneWidget);
          expect(
            tester
                .widget<SelectableText>(
                  find.byKey(const ValueKey('import-test-current-url')),
                )
                .data,
            contains('/login'),
          );
          debugPrint('QA_IMPORT_NAV_CAPTURE_MANUAL');
          await tester.pump(const Duration(seconds: 3));
          await tester.tap(find.byKey(const ValueKey('import-test-retry')));
        }
        for (var i = 0; i < 150; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (expectsError && find.byType(AlertDialog).evaluate().isNotEmpty) {
            break;
          }
          if (calendarRequests > 0 &&
              find.text('Open import').evaluate().isNotEmpty) {
            break;
          }
        }
        if (expectsError) {
          expect(calendarRequests, navigation.startsWith('pre ') ? 0 : 1);
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(
            find.textContaining(
              navigation.startsWith('pre ') ? 'preExtractJS' : 'extractJS',
            ),
            findsWidgets,
          );
          if (navigation == 'extract runtime error') {
            expect(find.textContaining('请先登录清华研究生教学日历'), findsWidgets);
            expect(find.textContaining('Expected a timetable'), findsNothing);
            debugPrint('QA_IMPORT_NAV_CAPTURE_EXTRACT_ERROR');
            await tester.pump(const Duration(seconds: 4));
          }
          if (navigation == 'pre runtime error') {
            debugPrint('QA_IMPORT_NAV_CAPTURE_ERROR');
            await tester.pump(const Duration(seconds: 3));
          }
          await tester.tap(find.text('关闭'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('import-test-retry')),
                )
                .onPressed,
            isNotNull,
            reason: 'Failed scripts must not leave extraction locked',
          );
          expect(
            (await tables.getAllCourseTable()).where(
              (row) => !originalIds.contains(row['id']),
            ),
            isEmpty,
          );
          return;
        }
        expect(
          calendarRequests,
          1,
          reason: 'Portal URL change must trigger preExtractJS',
        );
        expect(find.text('Open import'), findsOneWidget);
        final added =
            (await tables.getAllCourseTable())
                .where((row) => !originalIds.contains(row['id']))
                .toList();
        expect(
          added,
          hasLength(1),
          reason: 'Import only once across URL/load callbacks',
        );
        expect(added.single['name'], 'QA SPA portal');
        final rows = await CourseProvider().getAllCourses(added.single['id']);
        expect(rows, hasLength(1));
        expect(rows.single['name'], courseName);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await server.close(force: true);
        for (final table in await tables.getAllCourseTable()) {
          if (!originalIds.contains(table['id'])) {
            await tables.delete(table['id']);
          }
        }
        if (previousTable == null) {
          await prefs.remove('tableId');
        } else {
          await prefs.setInt('tableId', previousTable);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
