// Runs the real Flutter pages and native persistence on a test emulator.
// The localhost recorder captures SDK screenshots before acknowledging each step.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/ClassTitle.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/Pages/Lecture/Widgets/LectureCard.dart';
import 'package:wheretosleepinnju/Pages/Share/qr_payload_codec.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';
import 'package:wheretosleepinnju/Utils/WeekUtil.dart';
import 'package:wheretosleepinnju/Utils/WidgetHelper.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

final platform = Platform.operatingSystem;
const recorderPort = int.fromEnvironment(
  'QA_RECORDER_PORT',
  defaultValue: 8768,
);
final endpoint = Uri.parse('http://127.0.0.1:$recorderPort');
Future<dynamic> record(Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(endpoint);
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(jsonEncode({'platform': platform, ...data}));
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('QA recorder rejected capture: $body');
    }
    return jsonDecode(body);
  } finally {
    client.close();
  }
}

class Offline extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy =
        (uri) => uri.host == '127.0.0.1' ? 'DIRECT' : 'PROXY 127.0.0.1:9';
    client.connectionTimeout = const Duration(seconds: 3);
    return client;
  }
}

class QaThrottledNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy =
        (uri) =>
            ['cdn.idealclover.cn', 'lecture.idealclover.cn'].contains(uri.host)
                ? 'PROXY 127.0.0.1:8774'
                : 'DIRECT';
    return client;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'three-platform checklist on native simulator',
    (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
      final prefs = await SharedPreferences.getInstance();
      final original = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final tables = CourseTableProvider();
      final courses = CourseProvider();
      final beforeIds =
          (await tables.getAllCourseTable()).map((e) => e['id']).toSet();
      final dir = await getApplicationDocumentsDirectory();
      await File(
        '${dir.path}/qa-checklist-backup.json',
      ).writeAsString(jsonEncode(original));
      await record({
        'event': 'start',
        'originalTableId': prefs.getInt('tableId'),
        'originalTableIds': beforeIds.toList(),
      });
      // Consent UI is captured separately. This local test fixture suppresses
      // repeated onboarding/review overlays and is restored in finally.
      await prefs.setInt('privacyVersion', 1000000);
      await prefs.setBool('hasShowReview', true);
      UmengCommonSdk.initCommon(
        '5f8ef217fac90f1c19a7b0f3',
        '5f9e1efa1c520d30739d2737',
        'Umeng',
      );
      final conf = await InitUtil.initialize();
      final fixtureName =
          'QA-Automated-$platform-${DateTime.now().millisecondsSinceEpoch}';
      final fixture = await tables.insert(CourseTable(fixtureName));
      await prefs.setInt('tableId', fixture.id!);
      await WeekUtil.setNowWeek(1);
      await prefs.setBool('showWeekend', true);
      await prefs.setBool('showNonCurrentWeekCourses', true);
      await prefs.setBool('showFreeClass', true);
      await prefs.setBool('forceZoom', true);
      final failures = <String>[];
      Future<void> settle([int count = 8]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder finder, [int limit = 100]) async {
        for (var i = 0; i < limit && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        expect(finder, findsWidgets);
      }

      Future<void> home() async {
        await tester.pumpWidget(
          app.MyApp(conf[0], ThemeMode.system, conf[2], key: UniqueKey()),
        );
        await until(find.byIcon(Icons.settings));
        expect(
          Localizations.localeOf(
            tester.element(find.byIcon(Icons.settings).first),
          ),
          const Locale('zh', 'CN'),
        );
        await settle();
      }

      Future<void> tap(Finder finder) async {
        await until(finder);
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await settle();
      }

      Future<void> text(String value) => tap(find.text(value));
      Future<void> settings() async {
        await home();
        await tap(find.byIcon(Icons.settings));
      }

      Future<void> snap(String name, String detail) async {
        await settle(2);
        await record({'event': 'snapshot', 'name': name, 'detail': detail});
      }

      Future<void> scenario(String id, Future<void> Function() body) async {
        const retryCases = String.fromEnvironment('QA_RETRY_CASES');
        if (retryCases.isNotEmpty && !retryCases.split(',').contains(id)) {
          return;
        }
        if (const bool.fromEnvironment('QA_PLUGIN_ONLY') &&
            id != 'R06-native-plugin-upgrade') {
          return;
        }
        if (const bool.fromEnvironment('QA_DIALOG_ONLY') &&
            !id.startsWith('R06')) {
          return;
        }
        if (const bool.fromEnvironment('QA_APPEARANCE_ONLY') &&
            !id.startsWith('R05')) {
          return;
        }
        if (const bool.fromEnvironment('QA_LAYOUT_ONLY') &&
            !id.startsWith('R02') &&
            !id.startsWith('U04')) {
          return;
        }
        try {
          await body();
          final error = tester.takeException();
          if (error != null) throw error;
          await record({'event': 'result', 'id': id, 'status': 'pass'});
        } catch (error, stack) {
          failures.add(id);
          await snap('$id-failure', error.toString());
          await record({
            'event': 'result',
            'id': id,
            'status': 'fail',
            'error': error.toString(),
            'stack': stack.toString(),
          });
          while (tester.takeException() != null) {}
        } finally {
          HttpOverrides.global = null;
          if (id == 'R01' &&
              const bool.fromEnvironment('QA_ANDROID_NETWORK_RETAKE')) {
            await record({'event': 'sdk-network', 'mode': 'restore'});
          }
        }
      }

      try {
        if (!const bool.fromEnvironment('QA_NATIVE_ONLY')) {
          await scenario('T02', () async {
            await settings();
            await text('课表管理');
            await tap(find.byIcon(Icons.add));
            await tester.enterText(
              find.byType(TextField),
              'QA-Delete-$platform',
            );
            await text('确认');
            await prefs.reload();
            final addedId = prefs.getInt('tableId');
            expect(addedId, isNot(fixture.id));
            await text('课表管理');
            await text(fixtureName);
            await prefs.reload();
            expect(prefs.getInt('tableId'), fixture.id);
            await snap('T02-switch', '通过界面新增并切回独立测试课表，确认持久化 tableId。');
            final row = find.ancestor(
              of: find.text('QA-Delete-$platform'),
              matching: find.byType(ListTile),
            );
            await tap(
              find.descendant(of: row, matching: find.byIcon(Icons.delete)),
            );
            await text('确认');
            expect(await tables.getCourseTable(addedId!), isNull);
            await text('课表管理');
            await snap('T02-deleted', '临时课表已删除；原课表均保留。当前产品没有课表改名入口。');
          });
          await scenario('S03', () async {
            await settings();
            await text('导入/导出课表');
            await tester.tap(find.text('导出当前课表'));
            await tester.pump(const Duration(milliseconds: 200));
            await record({
              'event': 'snapshot',
              'name': 'S03-empty',
              'detail': '原生 Toast 截图，另确认没有生成二维码。',
            });
            expect(find.text('复制完整分享串'), findsNothing);
            expect((await courses.getAllCourses(fixture.id!)).isEmpty, isTrue);
          });
          await scenario('D04', () async {
            await settings();
            await text('手动添加');
            await tap(find.widgetWithText(TextButton, '添加课程'));
            expect(find.text('请输入课程名称'), findsOneWidget);
            await snap('D04-validation', '空名称阻止保存，数据库保持为空。');
            expect((await courses.getAllCourses(fixture.id!)).isEmpty, isTrue);
            await tester.enterText(
              find.byType(TextField).at(0),
              'QA-Delete-Course',
            );
            await tap(find.widgetWithText(TextButton, '添加课程'));
            expect((await courses.getAllCourses(fixture.id!)).length, 1);
            await home();
            await tester.longPress(find.byType(CourseWidget).first);
            await settle();
            await snap(
              'D04-delete-confirm',
              '仅删除本轮创建的 QA-Delete-Course。当前版本未提供编辑入口。',
            );
            await text('确认');
            expect((await courses.getAllCourses(fixture.id!)).isEmpty, isTrue);
            await snap('D04-deleted', '长按删除后课表和数据库均无该课程。');
          });
          await scenario('U03', () async {
            final fixtures = [
              Course(
                fixture.id,
                'QA-Odd',
                '[1,3]',
                1,
                1,
                0,
                0,
                classroom: 'QA-101',
              ),
              Course(
                fixture.id,
                'QA-Even',
                '[2,4]',
                2,
                3,
                0,
                0,
                classroom: 'QA-202',
              ),
              Course(
                fixture.id,
                'QA-Conflict-A',
                '[1,2]',
                3,
                5,
                1,
                0,
                classroom: 'QA-301',
              ),
              Course(
                fixture.id,
                'QA-Conflict-B',
                '[1,2]',
                3,
                5,
                1,
                0,
                classroom: 'QA-302',
              ),
              Course(
                fixture.id,
                'QA-Free',
                '[1,2]',
                0,
                0,
                0,
                0,
                classroom: 'QA-Free-Room',
              ),
            ];
            for (final course in fixtures) {
              await courses.insert(course);
            }
            await prefs.setInt('tmpWeekIndex', 1);
            await home();
            expect(
              find.text('QA-Odd@QA-101', findRichText: true),
              findsWidgets,
            );
            expect(
              find.text('[非本周]QA-Even@QA-202', findRichText: true),
              findsWidgets,
            );
            await snap('U03-week1', '真实数据库夹具：单周活跃，双周标记非本周，冲突与自由时间同时存在。');
            await tester.drag(
              find.byType(PageView).first,
              const Offset(-450, 0),
            );
            await settle();
            expect(
              find.text('[非本周]QA-Odd@QA-101', findRichText: true),
              findsWidgets,
            );
            expect(
              find.text('QA-Even@QA-202', findRichText: true),
              findsWidgets,
            );
            await snap('U03-week2', '通过横向手势切到第2周，单双周显示反转。');
            await tap(
              find.text('QA-Conflict-B@QA-302', findRichText: true).last,
            );
            await snap('U03-conflict', '展开重叠课程，核对两条课程。');
            await home();
            await text('查看');
            await snap('U03-free', '展开自由时间课程。');
          });
          if (!const bool.fromEnvironment('QA_SKIP_SHARE')) {
            await scenario('S02', () async {
              await settings();
              await text('导入/导出课表');
              await text('导出当前课表');
              await until(find.text('复制完整分享串'));
              await text('复制完整分享串');
              final share = (await Clipboard.getData('text/plain'))!.text!;
              final frame = QrPayloadCodec.parseFrame(share)!;
              final payload = QrPayloadCodec.decodeEncodedPayload(
                frame.payload,
              );
              expect((payload['courses'] as List).length, 5);
              await snap('S02-export', '从真实导出界面复制分享串，解码核对5门夹具课程。');
              final other = await record({
                'event': 'exchange',
                'share': share,
                'payload': payload,
              });
              await settings();
              await text('导入/导出课表');
              await text('导入课表');
              await Clipboard.setData(ClipboardData(text: other['share']));
              await text('从剪贴板导入');
              await prefs.reload();
              final rows = await courses.getAllCourses(
                prefs.getInt('tableId')!,
              );
              expect(rows.length, 5);
              expect(rows.map((e) => e['name']).toSet(), {
                'QA-Odd',
                'QA-Even',
                'QA-Conflict-A',
                'QA-Conflict-B',
                'QA-Free',
              });
              await home();
              await snap(
                'S02-import',
                '分享串来源：${other['source']}；导入后5门课程姓名、教室、周次、节次逐字段比对。',
              );
              final normalized =
                  rows
                      .map(
                        (e) => {
                          for (final k in [
                            'name',
                            'classroom',
                            'weeks',
                            'week_time',
                            'start_time',
                            'time_count',
                          ])
                            k: e[k],
                        },
                      )
                      .toList();
              await record({
                'event': 'import-readback',
                'source': other['source'],
                'rows': normalized,
              });
              await prefs.setInt('tableId', fixture.id!);
            });
          }
          await scenario('A01-A02', () async {
            await settings();
            await text('自定义选项');
            await tap(find.byWidgetPredicate((w) => w is DropdownButton<int>));
            await text('深色模式');
            expect(
              Theme.of(tester.element(find.text('自定义选项'))).brightness,
              Brightness.dark,
            );
            await snap('A01-dark', '实际选择深色模式，随后恢复跟随系统。');
            await tap(find.byWidgetPredicate((w) => w is DropdownButton<int>));
            await text('跟随系统');
            for (final label in ['显示周末', '显示课程时间']) {
              final row = find.ancestor(
                of: find.text(label),
                matching: find.byType(ListTile),
              );
              await tap(
                find.descendant(of: row, matching: find.byType(Switch)),
              );
            }
            await home();
            expect(find.text('周六'), findsNothing);
            expect(find.text('周日'), findsNothing);
            await prefs.reload();
            expect(prefs.getBool('showWeekend'), isFalse);
            expect(prefs.getBool('showClassTime'), isFalse);
            await snap('A02-weekend-time', '通过设置关闭周末、上课时间，检查主课表显示。');
            await prefs.setBool('showWeekend', true);
            await prefs.setBool('showClassTime', true);
            await home();
          });
          await scenario('L01', () async {
            await settings();
            await text('查看/添加讲座');
            await until(find.byType(LectureCard));
            await snap('L01-online', '真实服务端返回讲座列表，不使用虚构的线上数据。');
            final card = tester.widget<LectureCard>(
              find.byType(LectureCard).first,
            );
            expect(card.lecture.expired, isFalse);
            await tap(find.textContaining('加入当前课表').first);
            if (find.text('确认').evaluate().isNotEmpty) {
              await text('确认');
            }
            final found = (await courses.getAllCourses(
              fixture.id!,
            )).where((r) => r['name'] == card.lecture.name);
            expect(found.length, 1);
            expect(found.first['classroom'], card.lecture.classroom);
            for (final field in [
              'weeks',
              'week_time',
              'start_time',
              'time_count',
            ]) {
              expect(found.first[field], card.lecture.toMap()[field]);
            }
            await until(find.textContaining('已添加('));
            await Scrollable.ensureVisible(
              tester.element(find.byType(LectureCard).first),
              alignment: 0,
            );
            await settle();
            await snap('L01-added', '讲座实际导入，数据库名称、教室、周次和节次核对。');
            await record({'event': 'lecture-readback', 'row': found.first});
          });
          if (platform != 'ohos') {
            await scenario('W01-settings', () async {
              await settings();
              await text('小组件设置');
              await tap(
                find.byWidgetPredicate((w) => w is DropdownButton<int>).first,
              );
              await text('30 分钟');
              await tap(
                find.byWidgetPredicate((w) => w is DropdownButton<int>).last,
              );
              await text('20:00');
              await prefs.reload();
              expect(prefs.getInt('widgetApproachingMinutes'), 30);
              expect(prefs.getInt('widgetTomorrowPreviewHour'), 20);
              await snap('W01-settings', '实际修改为提前30分钟、20:00明日预览；结束后恢复。');
            });
          }
          await scenario('R01', () async {
            if (const bool.fromEnvironment('QA_ANDROID_NETWORK_RETAKE')) {
              await record({'event': 'sdk-network', 'mode': 'offline'});
            } else {
              HttpOverrides.global = Offline();
            }
            await settings();
            await text('导入课程表');
            await settle(25);
            await until(find.text('暂时无法获取学校列表'));
            await snap(
              'R01-school-failed',
              const bool.fromEnvironment('QA_ANDROID_NETWORK_RETAKE')
                  ? '通过SDK关闭模拟器Wi-Fi与移动数据，确认无默认网络，检查学校列表错误状态。'
                  : '测试进程连接拒绝注入（非断开 Mac 网络），检查错误状态。',
            );
            expect(find.text('加载中...'), findsNothing, reason: '失败后不能永久显示加载中');
            await settings();
            await text('查看/添加讲座');
            await settle(25);
            await until(find.text('网络错误，请重试'));
            await snap('R01-lecture-failed', '讲座网络失败状态。');
            final error = tester.takeException();
            if (error != null) throw error;
            HttpOverrides.global = null;
            if (const bool.fromEnvironment('QA_ANDROID_NETWORK_RETAKE')) {
              await record({'event': 'sdk-network', 'mode': 'restore'});
            }
            await settings();
            await text('查看/添加讲座');
            await until(find.byType(LectureCard));
            await snap(
              'R01-recovered',
              const bool.fromEnvironment('QA_ANDROID_NETWORK_RETAKE')
                  ? '通过SDK恢复模拟器原网络状态后重新进入列表，真实讲座数据恢复。'
                  : '解除连接拒绝后重新进入列表，数据恢复。',
            );
          });
          await scenario('R01-throttled', () async {
            HttpOverrides.global = QaThrottledNetwork();
            await record({'event': 'network-mode', 'mode': 'slow'});
            final timer = Stopwatch()..start();
            await settings();
            await text('导入课程表');
            await settle(55);
            expect(find.text('暂时无法获取学校列表'), findsNothing);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(find.byType(ListTile), findsWidgets);
            expect(timer.elapsedMilliseconds, greaterThan(2500));
            await snap(
              'R01-slow-real-tls',
              '真实线上学校配置经端到端 TLS 隧道，连接延迟3秒、下行32KiB/s。',
            );
            await record({'event': 'network-mode', 'mode': 'drop'});
            await settings();
            await text('导入课程表');
            await until(find.text('暂时无法获取学校列表'));
            await snap(
              'R01-dropped-connection',
              '在本地 TLS 隧道中断开上游连接；页面进入可重试错误态。',
            );
            await record({'event': 'network-mode', 'mode': 'normal'});
            HttpOverrides.global = null;
            await text('重新加载');
            await settle(40);
            expect(find.text('暂时无法获取学校列表'), findsNothing);
            expect(find.byType(ListTile), findsWidgets);
            await snap('R01-retry-real-network', '恢复连接并点击同页重新加载，线上学校列表恢复。');
          });
          await scenario('R05-accessibility', () async {
            await prefs.setInt('tableId', fixture.id!);
            await prefs.setInt('tmpWeekIndex', 1);
            await courses.deleteByTable(fixture.id!);
            await courses.insert(
              Course(
                fixture.id,
                'QA-大字体长课程名称测试',
                '[1]',
                1,
                1,
                0,
                0,
                classroom: 'QA-101',
              ),
            );
            tester.platformDispatcher.textScaleFactorTestValue = 3.2;
            await home();
            // A full-width period column must not consume most of the overview.
            expect(
              tester.getSize(find.byType(ClassTitle).first).width,
              lessThan(
                tester.view.physicalSize.width /
                    tester.view.devicePixelRatio *
                    .2,
              ),
            );
            final courseText = tester.widget<RichText>(
              find
                  .descendant(
                    of: find.byType(CourseWidget).first,
                    matching: find.byType(RichText),
                  )
                  .first,
            );
            expect(
              courseText.textScaler.scale(12),
              greaterThan(12),
              reason: 'Course text must grow along with the period labels.',
            );
            expect(courseText.maxLines, greaterThan(0));
            expect(courseText.overflow, TextOverflow.ellipsis);
            await snap(
              'R05-max-font',
              '3.2倍文字比例，实际设备尺寸不变；七列标题、节次和课程共同排版，长课程省略显示。',
            );
            await tap(find.byType(CourseWidget).first);
            final detail = find.text('QA-大字体长课程名称测试');
            await until(detail);
            expect(
              MediaQuery.textScalerOf(tester.element(detail.first)).scale(12),
              closeTo(24, .01),
              reason: 'Dialog typography uses a coherent 2x maximum.',
            );
            await snap('R05-course-detail', '弹窗标题、正文、操作统一使用最高2倍文字比例，长内容可滚动。');
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          await scenario('R06-dialogs', () async {
            await prefs.setInt('tableId', fixture.id!);
            await prefs.setInt('tmpWeekIndex', 1);
            await courses.deleteByTable(fixture.id!);
            const longTitle = 'QA-超过十五字的完整课程名称与课堂讨论实践';
            final course = await courses.insert(
              Course(
                fixture.id,
                longTitle,
                '[1,2,3,4,5]',
                1,
                1,
                0,
                0,
                classroom: '仙林校区教学楼三层 QA-101',
                teacher: '测试教师',
                info:
                    List.filled(6, '这是用于测试的长备注。请在上课前完成预习。').join('\n') +
                    '\nQA-END-完整内容',
              ),
            );
            tester.platformDispatcher.textScaleFactorTestValue = 3.2;
            await home();
            await tap(find.byType(CourseWidget).first);
            await until(find.byType(CourseDetailDialog));
            expect(find.text(longTitle), findsOneWidget);
            final body = tester.widgetList<SelectableLinkify>(
              find.byType(SelectableLinkify),
            );
            expect(body.every((text) => text.textScaleFactor == 2), isTrue);
            expect(find.text('确认').hitTestable(), findsOneWidget);
            await snap(
              'R06-detail-long-top',
              '3.2倍系统文字比例注入，弹窗统一最高2倍；完整长标题换行，正文同步放大，确认按钮固定可见。',
            );
            final scroll =
                find
                    .descendant(
                      of: find.byType(AlertDialog),
                      matching: find.byType(SingleChildScrollView),
                    )
                    .first;
            await tester.drag(scroll, const Offset(0, -1800));
            await settle();
            expect(find.text('确认').hitTestable(), findsOneWidget);
            await snap(
              'R06-detail-long-bottom',
              '实际滚动长备注到底部，QA-END可读，确认按钮仍可点击。',
            );
            await text('确认');
            expect(find.byType(CourseDetailDialog), findsNothing);
            await tester.longPress(find.byType(CourseWidget).first);
            await settle();
            expect(find.text('取消').hitTestable(), findsOneWidget);
            expect(find.text('确认').hitTestable(), findsOneWidget);
            await snap('R06-delete-confirm', '大字删除确认弹窗，两项操作均可见；实际点击取消，不删除课程。');
            await text('取消');
            expect((await courses.getCourse(course.id!))?.name, longTitle);
            await settings();
            await text('课表管理');
            await tap(find.byIcon(Icons.add));
            await tester.enterText(find.byType(TextField), 'QA-大字新增课表');
            await snap(
              'R06-add-input',
              '大字新增课表输入回归；集成输入不保证显示系统软键盘，键盘遮挡另用正常产品包实拍。',
            );
            expect(find.text('取消').hitTestable(), findsOneWidget);
            expect(find.text('确认').hitTestable(), findsOneWidget);
            await text('取消');
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          await scenario('R06-scanner-upgrade', () async {
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            await prefs.setInt('tableId', fixture.id!);
            final expectedRows = await courses.getAllCourses(fixture.id!);
            expect(expectedRows, hasLength(1));
            await settings();
            await text('导入/导出课表');
            await text('导出当前课表');
            await text('复制完整分享串');
            final share = (await Clipboard.getData('text/plain'))!.text!;
            await settings();
            await text('导入/导出课表');
            await text('导入课表');
            await snap(
              'R06-scanner-open',
              '升级后真实扫码插件页面可打开；模拟器无实体摄像头，拍摄识别不在此项验收。',
            );
            await Clipboard.setData(ClipboardData(text: share));
            await text('从剪贴板导入');
            await prefs.reload();
            final imported = await courses.getAllCourses(
              prefs.getInt('tableId')!,
            );
            expect(imported, hasLength(1));
            for (final field in [
              'name',
              'classroom',
              'teacher',
              'weeks',
              'info',
            ]) {
              expect(imported.single[field], expectedRows.single[field]);
            }
            await home();
            await snap(
              'R06-scanner-import',
              '经新版扫码页面完成分享串导入；数据库回读核对课程名、教室、教师、周次和长备注。',
            );
          });
          await scenario('R06-native-plugin-upgrade', () async {
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            final bridge = Completer<String>();
            final loaded = Completer<void>();
            final controller = WebViewController();
            await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
            await controller.setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (_) {
                  if (!loaded.isCompleted) loaded.complete();
                },
              ),
            );
            await controller.addJavaScriptChannel(
              'QaBridge',
              onMessageReceived: (message) {
                if (!bridge.isCompleted) bridge.complete(message.message);
              },
            );
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: SafeArea(child: WebViewWidget(controller: controller)),
                ),
              ),
            );
            await settle();
            await controller.loadHtmlString('''
              <html><head><meta name="viewport" content="width=device-width">
              <title>QA-WebView</title></head><body>
              <h1>QA · WebView 插件验证</h1><p>本地测试 HTML，不连接校园账号。</p>
              <p id="result">JavaScript 与原生消息桥已加载</p>
              <script>QaBridge.postMessage('QA-原生桥接');</script>
              </body></html>
            ''');
            final message = await tester.runAsync(
              () => bridge.future.timeout(const Duration(seconds: 20)),
            );
            expect(message, 'QA-原生桥接');
            await tester.runAsync(
              () => loaded.future.timeout(const Duration(seconds: 20)),
            );
            expect(
              (await controller.runJavaScriptReturningResult(
                'document.title',
              )).toString(),
              contains('QA-WebView'),
            );
            expect(await Fluttertoast.showToast(msg: 'QA 插件调用通过'), isTrue);
            await Fluttertoast.cancel();
            // WKWebView paints asynchronously after navigation/JS completion.
            // Give its native surface time to render before the SDK screenshot.
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(seconds: 2)),
            );
            await snap(
              'R07-native-webview',
              '测试诊断页：新版 WebView 本地 HTML 加载、JavaScript 返回值和原生消息桥断言通过；Toast 原生调用成功。不是教务登录截图。',
            );
            await home();
          });
          await scenario('R02-layout', () async {
            tester.platformDispatcher.textScaleFactorTestValue = 1.8;
            await home();
            await snap('R02-large-font', '在原生模拟器测试进程注入1.8倍系统文字比例，检查布局溢出。');
            final error = tester.takeException();
            if (error != null) throw error;
            await tap(find.byIcon(Icons.settings));
            await snap('R02-large-font-settings', '1.8倍文字设置页。');
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          await scenario('R02-small-rotate', () async {
            tester.view.devicePixelRatio = 3;
            tester.view.physicalSize = const Size(960, 1920);
            await home();
            await record({
              'event': 'layout-check',
              'name': 'R02-small',
              'detail': '320×640框架布局检查；原生surface不随测试视口同步，SDK截图不作为尺寸证据。',
            });
            var error = tester.takeException();
            if (error != null) throw error;
            tester.view.physicalSize = const Size(1920, 960);
            await home();
            await record({
              'event': 'layout-check',
              'name': 'R02-landscape',
              'detail': '640×320框架布局检查；实际系统旋转另在正常产品包验证。',
            });
            error = tester.takeException();
            if (error != null) throw error;
            tester.view.padding = const FakeViewPadding(
              left: 171,
              right: 171,
              bottom: 63,
            );
            tester.view.viewPadding = const FakeViewPadding(
              left: 171,
              right: 171,
              bottom: 63,
            );
            await home();
            await record({
              'event': 'layout-check',
              'name': 'R02-landscape-safe-area',
              'detail': '横屏视口加入左右各57逻辑像素安全边距，检查框架布局无溢出；实际截图见正常产品包。',
            });
            error = tester.takeException();
            if (error != null) throw error;
            // Dispose the landscape tree before restoring the test viewport. Its
            // async data load caches layout sizes, so changing the viewport under
            // that old tree otherwise leaks an overflow into the following case.
            await tester.pumpWidget(const SizedBox.shrink());
            tester.view.resetPadding();
            tester.view.resetViewPadding();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            await tester.pump();
          });
          await scenario('U04-mixed-overlap', () async {
            await prefs.setInt('tableId', fixture.id!);
            await prefs.setInt('tmpWeekIndex', 1);
            await courses.deleteByTable(fixture.id!);
            await courses.insert(
              Course(
                fixture.id,
                'QA-Active-Single',
                '[1]',
                1,
                1,
                0,
                0,
                classroom: 'QA-101',
              ),
            );
            await courses.insert(
              Course(fixture.id, 'QA-Hidden-A', '[2]', 1, 1, 0, 0),
            );
            await courses.insert(
              Course(fixture.id, 'QA-Hidden-B', '[2]', 1, 1, 0, 0),
            );
            await home();
            expect(
              find.textContaining('QA-Active-Single', findRichText: true),
              findsWidgets,
            );
            await snap('U04-mixed-overlap', '修复后本周单节课程位于冲突卡片首位，不再被非本周课程遮盖。');
          });
        }
        if (const bool.fromEnvironment('QA_NATIVE_WIDGETS')) {
          await scenario('W03-native-fixture', () async {
            await prefs.setInt('tableId', fixture.id!);
            await prefs.setInt('tmpWeekIndex', 1);
            await courses.deleteByTable(fixture.id!);
            final now = DateTime.now();
            String time(int offset) {
              const quick = bool.fromEnvironment('QA_WIDGET_QUICK');
              final t = now.add(
                Duration(minutes: quick ? (offset - 4) ~/ 2 : offset),
              );
              return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            }

            fixture.data = jsonEncode({
              'class_time_list': [
                {'start': time(6), 'end': time(8)},
                {'start': time(10), 'end': time(12)},
              ],
            });
            await tables.update(fixture);
            await prefs.setInt('widgetApproachingMinutes', 5);
            await prefs.setInt('widgetTomorrowPreviewHour', 19);
            await courses.insert(
              Course(
                fixture.id,
                'QA-Widget-Arrival',
                '[1]',
                now.weekday,
                1,
                0,
                0,
                classroom: 'QA-101',
              ),
            );
            await courses.insert(
              Course(
                fixture.id,
                'QA-Widget-Next',
                '[1]',
                now.weekday,
                2,
                0,
                0,
                classroom: 'QA-202',
              ),
            );
            await courses.insert(
              Course(
                fixture.id,
                'QA-Other-Week-A',
                '[2]',
                now.weekday,
                1,
                0,
                0,
                classroom: 'NOT-TODAY',
              ),
            );
            await courses.insert(
              Course(
                fixture.id,
                'QA-Other-Week-B',
                '[2]',
                now.weekday,
                1,
                0,
                0,
                classroom: 'NOT-TODAY',
              ),
            );
            await home();
            await WidgetHelper.refreshWidget(fixture.id!);
            await snap('W03-app-fixture', '真实时钟下两门课程；另两门重叠课程仅第2周发生，应排除。');
            await record({
              'event': 'native-start',
              'tableId': fixture.id,
              'start': time(6),
              'end': time(8),
              'nextStart': time(10),
              'nextEnd': time(12),
            });
            for (var i = 0; i < 600; i++) {
              final status = await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(seconds: 2));
                return record({'event': 'native-poll'});
              });
              if (status['done'] == true) break;
              if (status['mode'] != null) {
                final mode = status['mode'] as String;
                final instant = DateTime.now();
                String offsetTime(int minutes) {
                  final value = instant.add(Duration(minutes: minutes));
                  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
                }

                final offsets = switch (mode) {
                  'approaching' => [3, 8, 25, 30],
                  'in-class' => [-2, 3, 20, 25],
                  'between' => [-10, -5, 20, 25],
                  'ended' || 'tomorrow' => [-20, -15, -10, -5],
                  _ => [60, 65, 90, 95],
                };
                fixture.data = jsonEncode({
                  'class_time_list': [
                    {
                      'start': offsetTime(offsets[0]),
                      'end': offsetTime(offsets[1]),
                    },
                    {
                      'start': offsetTime(offsets[2]),
                      'end': offsetTime(offsets[3]),
                    },
                  ],
                });
                await tables.update(fixture);
                await prefs.setInt('widgetApproachingMinutes', 5);
                await prefs.setInt(
                  'widgetTomorrowPreviewHour',
                  mode == 'tomorrow' ? 0 : 23,
                );
                await courses.deleteByTable(fixture.id!);
                if (mode != 'empty') {
                  for (var index = 0; index < 2; index++) {
                    await courses.insert(
                      Course(
                        fixture.id,
                        'QA-Widget-${index + 1}',
                        '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]',
                        instant.weekday,
                        index + 1,
                        0,
                        0,
                        classroom: 'QA-${index + 1}01',
                      ),
                    );
                  }
                  await courses.insert(
                    Course(
                      fixture.id,
                      'QA-Tomorrow',
                      '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]',
                      instant.add(const Duration(days: 1)).weekday,
                      1,
                      0,
                      0,
                      classroom: 'QA-301',
                    ),
                  );
                }
                await WidgetHelper.refreshWidget(fixture.id!);
                await record({'event': 'native-mode-applied', 'mode': mode});
              }
            }
          });
        }
      } finally {
        HttpOverrides.global = null;
        tester.platformDispatcher.clearAllTestValues();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
        await settle(2);
        for (final row in await tables.getAllCourseTable()) {
          if (!beforeIds.contains(row['id'])) {
            await tables.delete(row['id']);
          }
        }
        for (final key in prefs.getKeys().toList()) {
          if (!original.containsKey(key)) await prefs.remove(key);
        }
        for (final entry in original.entries) {
          final v = entry.value;
          if (v is bool) await prefs.setBool(entry.key, v);
          if (v is int) await prefs.setInt(entry.key, v);
          if (v is double) await prefs.setDouble(entry.key, v);
          if (v is String) await prefs.setString(entry.key, v);
          if (v is List<String>) await prefs.setStringList(entry.key, v);
        }
        await WidgetRefreshHelper.manualRefresh();
        if (prefs.getInt('tableId') != null) {
          await WidgetHelper.refreshWidget(prefs.getInt('tableId')!);
        }
        await record({
          'event': 'complete',
          'failed': failures,
          'restoredTableId': prefs.getInt('tableId'),
          'tableIds':
              (await tables.getAllCourseTable()).map((r) => r['id']).toList(),
        });
      }
      expect(failures, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
