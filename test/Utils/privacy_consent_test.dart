import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/PrivacyUtil.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

Map<String, dynamic> policy(int version) => {
  'version': version,
  'title': '隐私测试协议',
  'content': '<p>同意后才初始化统计 SDK。</p>',
  'cancel_text': '不同意并退出',
  'confirm_text_first_install': '同意协议，开始导入',
  'confirm_text_for_upgrade': '同意协议，开始使用',
};

Future<void> openCheck(
  WidgetTester tester,
  PrivacyUtil privacy,
  void Function(bool) complete, {
  bool force = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
              body: TextButton(
                onPressed:
                    () async =>
                        complete(await privacy.checkPrivacy(context, force)),
                child: const Text('检查隐私'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('检查隐私'));
  await tester.pumpAndSettle();
}

void main() {
  final sdkCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sdkCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('umeng_common_sdk'), (
          call,
        ) async {
          sdkCalls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('umeng_common_sdk'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'showing, Android back and rejecting never grant consent or call SDK',
    (tester) async {
      bool? accepted;
      final privacy = PrivacyUtil(
        loadPolicy: () async => policy(1),
        countCourses: () async => 0,
      );
      await openCheck(tester, privacy, (value) => accepted = value);
      expect(find.text('隐私测试协议'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('隐私测试协议'), findsOneWidget);
      expect(accepted, isNull);
      expect(
        (await SharedPreferences.getInstance()).getInt('privacyVersion'),
        isNull,
      );
      await tester.tap(find.text('不同意并退出'));
      await tester.pumpAndSettle();
      expect(accepted, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getInt('privacyVersion'),
        isNull,
      );
      expect(sdkCalls, isEmpty);
    },
  );

  testWidgets('first agreement is persisted and offers initial import', (
    tester,
  ) async {
    bool? accepted;
    final privacy = PrivacyUtil(
      loadPolicy: () async => policy(1),
      countCourses: () async => 0,
    );
    await openCheck(tester, privacy, (value) => accepted = value);
    expect(sdkCalls, isEmpty);
    await tester.tap(find.text('同意协议，开始导入'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
    expect(privacy.requiredVersion, 1);
    expect(privacy.shouldOfferImport, isTrue);
    expect((await SharedPreferences.getInstance()).getInt('privacyVersion'), 1);
    expect(sdkCalls, isEmpty);
  });

  testWidgets('existing consent authorizes startup without repeating import', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'privacyVersion': 1});
    bool? accepted;
    final privacy = PrivacyUtil(
      loadPolicy: () async => policy(1),
      countCourses: () async => 0,
    );
    await openCheck(tester, privacy, (value) => accepted = value);
    expect(accepted, isTrue);
    expect(privacy.shouldOfferImport, isFalse);
    expect(find.text('隐私测试协议'), findsNothing);
    expect(sdkCalls, isEmpty);
  });

  testWidgets(
    'policy upgrade needs agreement and retains existing course workflow',
    (tester) async {
      SharedPreferences.setMockInitialValues({'privacyVersion': 1});
      bool? accepted;
      final privacy = PrivacyUtil(
        loadPolicy: () async => policy(2),
        countCourses: () async => 4,
      );
      await openCheck(tester, privacy, (value) => accepted = value);
      expect(accepted, isNull);
      expect(
        (await SharedPreferences.getInstance()).getInt('privacyVersion'),
        1,
      );
      await tester.tap(find.text('同意协议，开始使用'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
      expect(privacy.shouldOfferImport, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getInt('privacyVersion'),
        2,
      );
      expect(sdkCalls, isEmpty);
    },
  );

  testWidgets('reading About privacy policy never counts as accepting it', (
    tester,
  ) async {
    bool? accepted;
    final privacy = PrivacyUtil(
      loadPolicy: () async => policy(1),
      countCourses: () async => 0,
    );
    await openCheck(tester, privacy, (value) => accepted = value, force: true);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getInt('privacyVersion'),
      isNull,
    );
    expect(sdkCalls, isEmpty);
  });

  testWidgets('offline or malformed policy never authorizes analytics', (
    tester,
  ) async {
    for (final loader in <Future<dynamic> Function()>[
      () async => throw const SocketException('offline'),
      () async => {'version': 0},
      () async => {'version': '1'},
      () async => [],
    ]) {
      bool? accepted;
      final privacy = PrivacyUtil(
        loadPolicy: loader,
        countCourses: () async => 0,
      );
      await openCheck(tester, privacy, (value) => accepted = value);
      expect(accepted, isFalse);
      expect(privacy.shouldOfferImport, isFalse);
      expect(sdkCalls, isEmpty);
    }
  });
}
