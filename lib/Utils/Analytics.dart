import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The only entry point for analytics. Events before consent are discarded.
class Analytics {
  static final ConsentAnalytics _client = ConsentAnalytics();

  static Future<bool> initializeAfterConsent(int requiredVersion) =>
      _client.initializeAfterConsent(requiredVersion);

  static void onEvent(String event, Map<String, dynamic> properties) =>
      _client.onEvent(event, properties);
}

class ConsentAnalytics {
  ConsentAnalytics({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('umeng_common_sdk');

  final MethodChannel _channel;
  bool _enabled = false;

  Future<bool> initializeAfterConsent(int requiredVersion) async {
    final preferences = await SharedPreferences.getInstance();
    if (requiredVersion <= 0 ||
        (preferences.getInt('privacyVersion') ?? 0) < requiredVersion) {
      return false;
    }
    if (_enabled) return true;
    _enabled = true;
    // The Android 1.3.0 plugin never completes Result for these methods.
    // Send in channel order without awaiting its initialization response.
    _send('initCommon', [
      '5f8ef217fac90f1c19a7b0f3',
      '5f9e1efa1c520d30739d2737',
      'Umeng',
      null,
    ]);
    _send('setPageCollectionModeAuto');
    return true;
  }

  void onEvent(String event, Map<String, dynamic> properties) {
    if (!_enabled) return;
    _send('onEvent', [event, properties]);
  }

  void _send(String method, [List<dynamic>? arguments]) {
    unawaited(
      _channel.invokeMethod<void>(method, arguments).catchError((Object error) {
        // An unavailable statistics service must not interrupt core features.
        debugPrint('Analytics unavailable: $error');
      }),
    );
  }
}
