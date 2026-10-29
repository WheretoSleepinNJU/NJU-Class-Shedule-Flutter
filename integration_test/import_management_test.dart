import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportView.dart';
import 'package:wheretosleepinnju/Pages/ManageTable/ManageTableView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/Utils/WidgetHelper.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'course_edit_test.dart' show report;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'rename, offline recovery, hidden test mode and real WebView import',
    (tester) async {
      final oldErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(
          'QA_FRAMEWORK_ERROR: ${details.exception}\n${details.stack}',
        );
        oldErrorHandler?.call(details);
      };
      final prefs = await SharedPreferences.getInstance();
      final previous = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final tables = CourseTableProvider(), courses = CourseProvider();
      final originalIds =
          (await tables.getAllCourseTable()).map((e) => e['id']).toSet();
      final metadata = jsonEncode({
        'class_time_list': [
          for (var i = 0; i < 12; i++)
            {'start': '08:${i.toString().padLeft(2, '0')}', 'end': '23:59'},
        ],
        'semester_start_monday': '2026-10-19',
      });
      final fixture = await tables.insert(
        CourseTable('本学期 · 匿名验证', data: metadata),
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final visits = <String>[];
      server.listen((request) async {
        visits.add(request.uri.path);
        request.response.headers.contentType = ContentType.html;
        if (request.uri.path == '/login') {
          request.response.statusCode = 302;
          request.response.headers.set('Location', '$base/portal');
        } else {
          request.response.write(
            '<html><head><meta name="viewport" content="width=device-width"></head><body><h2>匿名导入验证</h2><p>${request.uri.path}</p></body></html>',
          );
        }
        await request.response.close();
      });
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> snap(String name, String note) async {
        await settle();
        await report({'event': 'snapshot', 'name': name, 'note': note});
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await settle();
      }

      Future<void> enter(String key, String value) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        if (Platform.operatingSystem == 'ohos') {
          // Keep the test input independent of the emulator IME's cached value.
          tester.widget<AdaptiveTextFormField>(finder).controller!.text = value;
        } else {
          await tester.enterText(finder, value);
        }
        await settle(2);
      }

      Future<void> page(Widget child) async {
        await tester.pumpWidget(
          ScopedModel<MainStateModel>(
            model: MainStateModel(),
            child: MaterialApp(
              key: UniqueKey(),
              theme: AppThemes.build(
                '#0095F9',
                Brightness.light,
                useSeedScheme: false,
              ),
              locale: const Locale('zh', 'CN'),
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: child,
            ),
          ),
        );
        await settle(15);
      }

      try {
        await ColorPool.shuffleColorPool();
        await prefs.setInt('tableId', fixture.id!);
        await WeekUtil.setNowWeek(1);
        for (var i = 1; i <= 12; i++) {
          await courses.insert(
            Course(
              fixture.id,
              '验证课程 ${i.toString().padLeft(2, '0')}',
              '[1,2]',
              DateTime.now().weekday,
              i,
              0,
              1,
              classroom: '仙林 $i 号教室',
              color: '#0095F9',
            ),
          );
        }
        final before = await courses.getAllCourses(fixture.id!);
        await page(const ManageTableView());
        await tap(find.byKey(ValueKey('rename-table-${fixture.id}')));
        await enter('table-name-input', '2026 秋季学期');
        await snap('rename-dialog', '修改当前课表名称，课程与学期设置保留');
        await tap(find.text('保存'));
        expect((await tables.getCourseTable(fixture.id!))!.name, '2026 秋季学期');
        expect((await tables.getCourseTable(fixture.id!))!.data, metadata);
        expect(await courses.getAllCourses(fixture.id!), before);
        expect(prefs.getInt('tableId'), fixture.id);
        await snap('renamed-table', '名称已写入 SQLite；12 门课程、作息表和选中状态保持');

        var attempts = 0;
        await page(
          Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      child: const Text('打开导入'),
                      onPressed:
                          () => Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ImportView(
                                    loadSchools: () async {
                                      if (++attempts == 1) {
                                        throw const SocketException(
                                          'QA offline'
                                        );
                                      }
                                      return [
                                        {
                                          'title': '匿名验证学校',
                                          'pinyin': 'test',
                                          'description': '登录后自动获取本学期课表',
                                        },
                                      ];
                                    },
                                  ),
                            ),
                          ),
                    ),
                  ),
                ),
          ),
        );
        await tap(find.text('打开导入'));
        expect(find.text('暂时无法获取学校列表'), findsOneWidget);
        await snap('offline-import', '网络获取失败空态：提示、重试入口；旧手动导入入口和说明已移除');
        await tap(find.byKey(const ValueKey('retry-schools')));
        expect(find.text('匿名验证学校'), findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tap(find.byKey(const ValueKey('import-title')));
        }
        expect(find.byKey(const ValueKey('import-test-button')), findsNothing);
        await tap(find.byKey(const ValueKey('import-title')));
        await snap('test-unlocked', '前四次无测试按钮，第五次出现；网络重试恢复列表');
        await tap(find.byKey(const ValueKey('import-test-button')));
        await enter('import-field-initialUrl', '$base/login');
        await enter('import-field-redirectUrl', '$base/portal');
        await enter('import-field-targetUrl', '$base/classes');
        await enter('import-field-preExtractJS', 'window.qaReady = true;');
        await enter('import-field-delayTime', '1');
        final payload = jsonEncode({
          'name': '测试导入 · 匿名课表',
          'courses': [
            {
              'name': '数据结构',
              'weeks': [1, 2, 3],
              'week_time': 2,
              'start_time': 3,
              'time_count': 1,
              'classroom': '仙 I-101',
              'teacher': '测试老师',
            },
            {
              'name': '大学物理',
              'weeks': [2, 4],
              'week_time': 5,
              'start_time': 6,
              'time_count': 0,
              'classroom': '实验楼',
            },
          ],
        });
        await enter(
          'import-field-extractJS',
          '(() => { if (!window.qaReady) throw new Error("preExtractJS missing"); return encodeURIComponent(JSON.stringify($payload)); })()',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(
          find.byKey(const ValueKey('import-field-initialUrl')),
        );
        await snap(
          'test-config-urls',
          '测试表单的 initialUrl、redirectUrl 和 targetUrl',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('start-import-test')),
        );
        await snap(
          'test-config-script',
          'preExtractJS、延时 1 秒、extractJS 使用同一导入管线',
        );
        await tap(find.byKey(const ValueKey('start-import-test')));
        for (var i = 0; i < 180 && find.text('打开导入').evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(find.text('打开导入'), findsOneWidget);
        expect(visits, containsAllInOrder(['/login', '/portal', '/classes']));
        final importedId = prefs.getInt('tableId')!;
        expect(importedId, isNot(fixture.id));
        final imported = await courses.getAllCourses(importedId);
        expect(imported.length, 2);
        expect(imported.first['name'], '数据结构');
        expect(imported.first['time_count'], 1);
        await page(const ManageTableView());
        await snap(
          'test-import-success',
          '真实 WebView 登录页→门户→课表页，preExtractJS 与 extractJS 执行，2 门课程完整落库',
        );
        await report({
          'event': 'result',
          'renamePreservedRows': 12,
          'testImportRows': 2,
          'visits': visits,
          'unlockTapCount': 5,
        });
        if (Platform.operatingSystem == 'ohos') {
          await prefs.setInt('tableId', fixture.id!);
          await WidgetHelper.refreshWidget(fixture.id!);
          await report({
            'event': 'widget-ready',
            'tableId': fixture.id,
            'courses': 12,
          });
          await courses.deleteByTable(fixture.id!);
          await WidgetHelper.refreshWidget(fixture.id!);
          await report({
            'event': 'widget-empty-ready',
            'tableId': fixture.id,
            'courses': 0,
          });
        }
        expect(tester.takeException(), isNull);
      } finally {
        FlutterError.onError = oldErrorHandler;
        await server.close(force: true);
        await tester.pumpWidget(const SizedBox.shrink());
        for (final table in await tables.getAllCourseTable()) {
          if (!originalIds.contains(table['id'])) {
            await tables.delete(table['id']);
          }
        }
        await prefs.clear();
        for (final e in previous.entries) {
          final v = e.value;
          if (v is String) await prefs.setString(e.key, v);
          if (v is int) await prefs.setInt(e.key, v);
          if (v is bool) await prefs.setBool(e.key, v);
          if (v is double) await prefs.setDouble(e.key, v);
          if (v is List<String>) await prefs.setStringList(e.key, v);
        }
        if (Platform.operatingSystem == 'ohos') {
          final originalTableId = prefs.getInt('tableId');
          if (originalTableId != null &&
              await tables.getCourseTable(originalTableId) != null) {
            await WidgetHelper.refreshWidget(originalTableId);
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
