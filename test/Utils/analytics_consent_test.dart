import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/Analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('umeng_common_sdk');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('unconsented and stale-consent events never reach the SDK', () async {
    final analytics = ConsentAnalytics();
    analytics.onEvent('privacy_dialog', {'action': 'show'});
    expect(await analytics.initializeAfterConsent(1), isFalse);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('privacyVersion', 1);
    expect(await analytics.initializeAfterConsent(2), isFalse);
    expect(await analytics.initializeAfterConsent(0), isFalse);
    analytics.onEvent('privacy_dialog', {'action': 'cancel'});
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
  });

  test(
    'only persisted consent starts SDK once and does not replay earlier events',
    () async {
      final analytics = ConsentAnalytics();
      analytics.onEvent('before_consent', {});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('privacyVersion', 1);
      expect(await analytics.initializeAfterConsent(1), isTrue);
      expect(await analytics.initializeAfterConsent(1), isTrue);
      analytics.onEvent('after_consent', {'action': 'accepted'});
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((call) => call.method), [
        'initCommon',
        'setPageCollectionModeAuto',
        'onEvent',
      ]);
      expect(calls.last.arguments, [
        'after_consent',
        {'action': 'accepted'},
      ]);
    },
  );

  test(
    'returning user still waits for policy verification on every process start',
    () async {
      SharedPreferences.setMockInitialValues({'privacyVersion': 1});
      final analytics = ConsentAnalytics();
      analytics.onEvent('startup', {});
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty);
      expect(await analytics.initializeAfterConsent(1), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((call) => call.method), [
        'initCommon',
        'setPageCollectionModeAuto',
      ]);
    },
  );

  test(
    'native init without a reply does not block consent or later events',
    () async {
      final nativeReply = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initCommon') await nativeReply.future;
            return null;
          });
      SharedPreferences.setMockInitialValues({'privacyVersion': 1});
      final analytics = ConsentAnalytics();
      expect(await analytics.initializeAfterConsent(1), isTrue);
      analytics.onEvent('after_consent', {});
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((call) => call.method), [
        'initCommon',
        'setPageCollectionModeAuto',
        'onEvent',
      ]);
      nativeReply.complete();
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('missing SDK cannot escape as an unhandled application error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw MissingPluginException(),
        );
    SharedPreferences.setMockInitialValues({'privacyVersion': 1});
    final analytics = ConsentAnalytics();
    expect(await analytics.initializeAfterConsent(1), isTrue);
    analytics.onEvent('test', {});
    await Future<void>.delayed(Duration.zero);
  });
}
