import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheretosleepinnju/main.dart' as app;
import 'package:wheretosleepinnju/Pages/CourseTable/CourseTableView.dart';
import 'package:wheretosleepinnju/Pages/Import/ImportView.dart';
import 'package:wheretosleepinnju/Pages/Settings/SettingsView.dart';
import 'package:wheretosleepinnju/core/widget_data/utils/widget_refresh_helper.dart';

Future<void> saveEvidence(String name, List<int> bytes) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:8770/$name'),
    );
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode != 200) throw StateError('Evidence capture failed');
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'scene startup registers plugins, syncs widgets and opens product pages',
    (tester) async {
      Future<void> settle([int count = 8]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> until(Finder finder) async {
        for (var i = 0; i < 160 && finder.evaluate().isEmpty; i++) {
          await settle(1);
        }
        expect(finder, findsWidgets);
      }

      Future<void> snap(String name) async {
        await settle();
        await saveEvidence(name, await binding.takeScreenshot(name));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Exercise recovery of an obsolete custom-theme sentinel before runApp.
      await prefs.setInt('themeIndex', 9);
      await prefs.setInt('themeModeIndex', 99);
      await prefs.setString('colorPool', '[');
      await prefs.setString('lastWeekMonday', 'invalid');
      app.main();
      await until(find.byType(CourseTableView));
      await until(find.byIcon(Icons.settings));
      await settle(10);
      const channel = MethodChannel('com.wheretosleepinnju/widget_data');
      final info = Map<String, dynamic>.from(
        await channel.invokeMapMethod<String, dynamic>('getPlatformInfo') ?? {},
      );
      expect(info['platform'], 'ios');
      expect(await WidgetRefreshHelper.manualRefresh(), isTrue);
      final data = await channel.invokeMapMethod<String, dynamic>(
        'debugReadWidgetData',
      );
      expect(data, isNotNull);
      await snap('ios27-scene-startup.png');
      // This is the same application agreement already authorized for QA simulators.
      final agree = find.text('同意协议，开始导入');
      for (var i = 0; i < 60 && agree.evaluate().isEmpty; i++) {
        await settle(1);
      }
      if (agree.evaluate().isNotEmpty) {
        await tester.tap(agree);
        await settle();
        expect(find.byType(ImportView), findsOneWidget);
        Navigator.of(tester.element(find.byType(ImportView))).pop();
        await settle();
      }
      await tester.tap(find.byIcon(Icons.settings));
      await until(find.byType(SettingsView));
      await snap('ios27-scene-settings.png');
      expect(await launchUrl(Uri.parse('ncs://qa-scene-smoke')), isTrue);
      await settle(10);
      expect(find.byType(SettingsView), findsOneWidget);
      expect(await channel.invokeMapMethod('getPlatformInfo'), isNotNull);
      expect(tester.takeException(), isNull);
      await saveEvidence(
        'ios27-scene-result.json',
        utf8.encode(
          jsonEncode({
            'nativePlatform': info,
            'startupWithStalePreferences': true,
            'widgetAppGroupRoundTrip': true,
            'settingsOpened': true,
            'warmURLLaunch': true,
            'runtimeScope':
                'Debug simulator; exported App Store IPA requires physical device',
          }),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
