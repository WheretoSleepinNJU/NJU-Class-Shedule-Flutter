import 'dart:convert';

import 'package:dio/dio.dart';

import '../Resources/Url.dart';

class ImportRemoteDataSource {
  ImportRemoteDataSource._();

  static final ImportRemoteDataSource instance = ImportRemoteDataSource._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
    ),
  );

  final Map<String, Future<dynamic>> _jsonCache = <String, Future<dynamic>>{};
  final Map<String, Future<String>> _textCache = <String, Future<String>>{};

  Future<List<bool>> fetchImportVisibility({bool forceRefresh = false}) async {
    try {
      final data = await _remember<dynamic>(
        _jsonCache,
        '${Url.UPDATE_ROOT}/importVisibility.json',
        () =>
            _dio.get<dynamic>('${Url.UPDATE_ROOT}/importVisibility.json').then(
                  (Response<dynamic> rsp) => _normalizeJsonPayload(rsp.data),
                ),
        forceRefresh: forceRefresh,
      );
      final List<dynamic> values = _extractListPayload(data);
      if (values.length < 3) {
        return <bool>[true, false, false];
      }
      return values
          .map((dynamic value) => value == true || value.toString() == 'true')
          .toList(growable: false);
    } catch (_) {
      return <bool>[true, false, false];
    }
  }

  Future<List<dynamic>> fetchSchoolList({bool forceRefresh = false}) async {
    try {
      final data = await _remember<dynamic>(
        _jsonCache,
        '${Url.UPDATE_ROOT}/schoolList.json',
        () => _dio.get<dynamic>('${Url.UPDATE_ROOT}/schoolList.json').then(
              (Response<dynamic> rsp) => _normalizeJsonPayload(rsp.data),
            ),
        forceRefresh: forceRefresh,
      );
      return _extractListPayload(data);
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<String> fetchText(String url, {bool forceRefresh = false}) {
    return _remember<String>(
      _textCache,
      url,
      () async {
        final Response<String> rsp = await _dio.get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        return rsp.data?.toString() ?? '';
      },
      forceRefresh: forceRefresh,
    );
  }

  Future<void> postImportErrorLog(Map<String, String> info) async {
    await _dio.post<dynamic>(
      '${Url.URL_BACKEND}/log/log',
      data: FormData.fromMap(info),
    );
  }

  Future<T> _remember<T>(
    Map<String, Future<T>> cache,
    String key,
    Future<T> Function() loader, {
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      cache.remove(key);
    }
    final existing = cache[key];
    if (existing != null) {
      return existing;
    }
    final future = loader().catchError((Object error) {
      cache.remove(key);
      throw error;
    });
    cache[key] = future;
    return future;
  }

  dynamic _normalizeJsonPayload(dynamic raw) {
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  List<dynamic> _extractListPayload(dynamic raw) {
    final dynamic normalized = _normalizeJsonPayload(raw);
    if (normalized is Map && normalized['data'] is List) {
      return List<dynamic>.from(normalized['data'] as List);
    }
    if (normalized is List) {
      return List<dynamic>.from(normalized);
    }
    return <dynamic>[];
  }
}
