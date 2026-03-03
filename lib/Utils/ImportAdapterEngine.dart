import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScriptSourceConfig {
  final String type;
  final String? url;
  final String? code;
  final String? path;
  final String? sha256Hash;

  ScriptSourceConfig({
    required this.type,
    this.url,
    this.code,
    this.path,
    this.sha256Hash,
  });

  factory ScriptSourceConfig.fromDynamic(dynamic raw) {
    if (raw is String) {
      return ScriptSourceConfig(type: 'remote', url: raw);
    }
    if (raw is Map) {
      return ScriptSourceConfig(
        type: (raw['type'] ?? 'remote').toString(),
        url: raw['url']?.toString(),
        code: raw['code']?.toString(),
        path: raw['path']?.toString(),
        sha256Hash: raw['sha256Hash']?.toString(),
      );
    }
    throw Exception('Invalid script source config.');
  }
}

class ScriptLoader {
  final Dio _dio = Dio();

  Future<String> load(ScriptSourceConfig source) async {
    String script;
    if (source.type == 'inline') {
      script = source.code ?? '';
    } else if (source.type == 'asset') {
      final assetPath = source.path ?? '';
      if (assetPath.isEmpty) {
        throw Exception('Asset script path is empty.');
      }
      script = await rootBundle.loadString(assetPath);
    } else {
      final url = source.url ?? '';
      if (url.isEmpty) {
        throw Exception('Remote script url is empty.');
      }
      final rsp = await _dio.get(url);
      script = rsp.data.toString();
    }
    _validateHashIfNeeded(script, source.sha256Hash);
    return script;
  }

  void _validateHashIfNeeded(String script, String? expectedHash) {
    if (expectedHash == null || expectedHash.trim().isEmpty) return;
    final actual = sha256.convert(utf8.encode(script)).toString();
    final normalizedExpected = expectedHash.trim().toLowerCase();
    if (actual.toLowerCase() != normalizedExpected) {
      throw Exception('Script hash verification failed.');
    }
  }
}

class ImportAdapterEngine {
  final ScriptLoader scriptLoader;

  ImportAdapterEngine({ScriptLoader? scriptLoader})
      : scriptLoader = scriptLoader ?? ScriptLoader();

  bool shouldUseAdapter(Map config) {
    return config['provider'] != null && config['parser'] != null;
  }

  Future<Map<String, dynamic>> run(
    WebViewController controller,
    Map config,
  ) async {
    if (!shouldUseAdapter(config)) {
      throw Exception('Adapter config is incomplete.');
    }
    final providerScript =
        await scriptLoader.load(ScriptSourceConfig.fromDynamic(config['provider']));
    final parserScript =
        await scriptLoader.load(ScriptSourceConfig.fromDynamic(config['parser']));
    final timerRaw = config['timer'];
    final timerScript = timerRaw == null
        ? null
        : await scriptLoader.load(ScriptSourceConfig.fromDynamic(timerRaw));

    final providerResult = await _executeProvider(controller, providerScript);
    final parserResult = await _executeParser(controller, parserScript, providerResult);
    final timingResult = timerScript == null
        ? <String, dynamic>{}
        : await _executeTimer(controller, timerScript, providerResult, parserResult);

    return <String, dynamic>{
      'name': (parserResult['name'] ?? '').toString(),
      'courses': parserResult['courses'] ?? <Map<String, dynamic>>[],
      'timing': timingResult,
    };
  }

  Future<String> _executeProvider(
    WebViewController controller,
    String providerScript,
  ) async {
    final js = '''
      (async function() {
        $providerScript
        var __res = await Promise.resolve(scheduleHtmlProvider());
        if (typeof __res !== 'string') {
          __res = JSON.stringify(__res);
        }
        return encodeURIComponent(__res);
      })();
    ''';
    final raw = await controller.runJavaScriptReturningResult(js);
    final cleaned = _cleanJsResult(raw);
    return Uri.decodeComponent(cleaned);
  }

  Future<Map<String, dynamic>> _executeParser(
    WebViewController controller,
    String parserScript,
    String providerResult,
  ) async {
    final js = '''
      (async function() {
        $parserScript
        var __res = await Promise.resolve(
          scheduleHtmlParser(${jsonEncode(providerResult)})
        );
        return encodeURIComponent(JSON.stringify(__res));
      })();
    ''';
    final raw = await controller.runJavaScriptReturningResult(js);
    final cleaned = _cleanJsResult(raw);
    final jsonText = Uri.decodeComponent(cleaned);
    final decoded = jsonDecode(jsonText);

    if (decoded is Map) {
      final courses = _normalizeCourses(_decodeMaybeJson(decoded['courses']));
      final name = decoded['name']?.toString() ?? '';
      return <String, dynamic>{'name': name, 'courses': courses};
    }

    if (decoded is List) {
      final courses = _normalizeCourses(decoded);
      return <String, dynamic>{'name': '', 'courses': courses};
    }

    throw Exception('Parser returned unsupported data type.');
  }

  Future<Map<String, dynamic>> _executeTimer(
    WebViewController controller,
    String timerScript,
    String providerResult,
    Map<String, dynamic> parserResult,
  ) async {
    final parserJson = jsonEncode(parserResult);
    final js = '''
      (async function() {
        $timerScript
        if (typeof scheduleTimer !== 'function') {
          return encodeURIComponent(JSON.stringify({}));
        }
        var __res = await Promise.resolve(scheduleTimer({
          providerRes: ${jsonEncode(providerResult)},
          parserRes: $parserJson
        }));
        return encodeURIComponent(JSON.stringify(__res || {}));
      })();
    ''';
    final raw = await controller.runJavaScriptReturningResult(js);
    final cleaned = _cleanJsResult(raw);
    final jsonText = Uri.decodeComponent(cleaned);
    final decoded = jsonDecode(jsonText);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  dynamic _decodeMaybeJson(dynamic value) {
    if (value is! String) return value;
    final text = value.trim();
    if (text.isEmpty) return value;
    if (!(text.startsWith('[') || text.startsWith('{'))) return value;
    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  List<Map<String, dynamic>> _normalizeCourses(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> out = [];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      if (map.containsKey('day') || map.containsKey('sections')) {
        final day = _toInt(map['day'], 0);
        final sections = _toIntList(map['sections']);
        if (sections.isEmpty) continue;
        final start = sections.reduce((a, b) => a < b ? a : b);
        final end = sections.reduce((a, b) => a > b ? a : b);
        out.add(<String, dynamic>{
          'name': (map['name'] ?? '').toString(),
          'classroom': (map['position'] ?? map['classroom'] ?? '').toString(),
          'class_number': (map['class_number'] ?? '').toString(),
          'teacher': (map['teacher'] ?? '').toString(),
          'test_time': (map['test_time'] ?? '').toString(),
          'test_location': (map['test_location'] ?? '').toString(),
          'link': map['link'],
          'weeks': _toIntList(map['weeks']),
          'week_time': day,
          'start_time': start,
          'time_count': end - start,
          'import_type': _toInt(map['import_type'], 1),
          'info': (map['info'] ?? '').toString(),
          'data': map['data'],
        });
      } else {
        out.add(map);
      }
    }
    return out;
  }

  List<int> _toIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _toInt(e, -1)).where((e) => e > 0).toList();
    }
    if (value == null) return <int>[];
    final text = value.toString();
    final matches = RegExp(r'\d+').allMatches(text);
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '') ?? -1)
        .where((e) => e > 0)
        .toList();
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  String _cleanJsResult(Object? raw) {
    if (raw == null) return '';
    String text = raw.toString();
    if (text.startsWith('"') && text.endsWith('"') && text.length >= 2) {
      text = text.substring(1, text.length - 1);
    }
    text = text.replaceAll(r'\"', '"');
    text = text.replaceAll(r'\\n', '\n');
    return text;
  }
}
