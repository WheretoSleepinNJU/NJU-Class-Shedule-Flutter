import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/MiuixSettings.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/SettingsCard.dart';

Widget host(Widget body, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ),
      home: SettingsScaffold(title: '设置', body: body),
    );

void main() {
  if (Platform.environment['MIUIX_PREVIEW_FONT'] != null &&
      Platform.environment['MIUIX_PREVIEW_ICON_FONT'] != null) {
    setUpAll(() async {
      final textFont = FontLoader('Roboto')
        ..addFont(
          File(
            Platform.environment['MIUIX_PREVIEW_FONT']!,
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      final iconFont = FontLoader('MaterialIcons')
        ..addFont(
          File(
            Platform.environment['MIUIX_PREVIEW_ICON_FONT']!,
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await textFont.load();
      await iconFont.load();
    });
  }

  testWidgets('settings theme follows application brightness', (tester) async {
    for (final brightness in Brightness.values) {
      MiuixThemeData? actual;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              actual = MiuixTheme.of(context);
              return const Text('主题');
            },
          ),
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(actual!.brightness, brightness);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('entry supports tap and long press and respects disabled state', (
    tester,
  ) async {
    var taps = 0, holds = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            SettingsEntry(
              icon: Icons.info,
              iconColor: Colors.blue,
              title: const Text('反馈'),
              onTap: () => taps++,
              onLongPress: () => holds++,
            ),
            SettingsEntry(
              icon: Icons.info,
              iconColor: Colors.grey,
              title: const Text('不可用'),
              enabled: false,
              onTap: () => taps++,
              onLongPress: () => holds++,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('反馈'));
    await tester.longPress(find.text('反馈'));
    await tester.tap(find.text('不可用'));
    await tester.longPress(find.text('不可用'));
    expect(taps, 1);
    expect(holds, 1);
  });

  testWidgets('switch preference toggles from row and disables while saving', (
    tester,
  ) async {
    var value = false;
    var calls = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, update) => Column(
            children: [
              SettingsSwitchTile(
                title: const Text('开关'),
                value: value,
                onChanged: (next) => update(() {
                  value = next;
                  calls++;
                }),
              ),
              const SettingsSwitchTile(
                title: Text('保存中'),
                value: false,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('开关'));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(find.text('保存中'));
    expect(calls, 1);
  });

  testWidgets('dropdown selects and dismisses within settings popup host', (
    tester,
  ) async {
    var selected = 5;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, update) => SettingsDropdown<int>(
            value: selected,
            items: const [
              SettingsOption(value: 5, child: Text('5 分钟')),
              SettingsOption(value: 15, child: Text('15 分钟')),
            ],
            onChanged: (next) => update(() => selected = next!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 分钟'));
    await tester.pumpAndSettle();
    expect(find.text('15 分钟'), findsOneWidget);
    await tester.tap(find.text('15 分钟'));
    await tester.pumpAndSettle();
    expect(selected, 15);
    expect(find.text('5 分钟'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MIUIX dialog returns result and leaves settings route mounted', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MiuixButton(
            child: const Text('编辑周次'),
            onPressed: () async {
              result = await showDialog<int>(
                context: context,
                builder: (dialogContext) => SettingsActionDialog(
                  '当前周',
                  const Text('第 2 周'),
                  widgetCancelAction: () => Navigator.pop(dialogContext),
                  widgetOKAction: () => Navigator.pop(dialogContext, 2),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑周次'));
    await tester.pumpAndSettle();
    expect(find.text('当前周'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, 2);
    expect(find.text('编辑周次'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('narrow settings with large text: ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: brightness, fontFamily: 'Roboto'),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.4),
              ),
              child: SettingsScaffold(
                title: '设置',
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SettingsCard(
                      children: [
                        SettingsEntry(
                          icon: Icons.download_rounded,
                          iconColor: Colors.blue,
                          title: const Text('导入课表'),
                          subtitle: const Text('从教务系统导入本学期课程'),
                          onTap: () {},
                        ),
                        SettingsEntry(
                          icon: Icons.date_range,
                          iconColor: Colors.green,
                          title: const Text('修改当前周'),
                          subtitle: const Text('当前为第 8 周'),
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsCard(
                      children: [
                        SettingsSwitchTile(
                          title: const Text('显示非本周课程'),
                          subtitle: const Text('在课表中保留其他周次的课程信息'),
                          value: true,
                          onChanged: (_) {},
                        ),
                        SettingsTile(
                          title: const Text('课前提醒时间'),
                          subtitle: const Text('同时用于小组件'),
                          trailing: SettingsDropdown<int>(
                            value: 15,
                            items: const [
                              SettingsOption(value: 15, child: Text('15 分钟')),
                            ],
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Optional local visual evidence, kept outside the repository.
      if (Platform.environment['MIUIX_PREVIEW_DIR']
          case final String directory) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$directory/settings-${brightness.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
