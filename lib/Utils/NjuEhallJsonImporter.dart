import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Reads the NJU eHall JSON APIs from the authenticated WebView and adapts the
/// response to the legacy `name` / `courses` import contract used by this app.
///
/// The endpoint paths and response layouts follow the cooperating calendar
/// importer. Requests deliberately run inside the existing WebView: its SSO
/// cookies are HttpOnly on some platforms, so moving them into a separate Dio
/// client would be less portable than using the already authenticated origin.
class NjuEhallJsonImporter {
  static const undergraduatePinyin = '1nanjingdaxuebenkejiaowu';
  static const graduatePinyin = '1nanjingdaxueyanjiujiaowu';

  static Future<Map<String, dynamic>> fetchCourseTableMap(
    WebViewController controller, {
    required String pinyin,
  }) async {
    switch (pinyin) {
      case undergraduatePinyin:
        return _adaptUndergraduate(await _readUndergraduate(controller));
      case graduatePinyin:
        return _adaptGraduate(await _readGraduate(controller));
      default:
        throw ArgumentError('Unsupported NJU eHall import source: $pinyin');
    }
  }

  static Future<Map<String, dynamic>> _readUndergraduate(
      WebViewController controller) async {
    return _runApiScript(controller, r'''
      var current = request('GET',
        'https://ehallapp.nju.edu.cn/jwapp/sys/wdkb/modules/jshkcb/dqxnxq.do');
      var semesterRows = rows(current, ['datas', 'dqxnxq', 'rows']);
      if (!semesterRows.length) throw new Error('eHall did not return a current semester');
      var semester = semesterRows[0];
      var semesterId = String(semester.DM || '');
      if (!semesterId) throw new Error('eHall current semester has no DM');

      var courses = request('POST',
        'https://ehallapp.nju.edu.cn/jwapp/sys/wdkb/modules/xskcb/cxxszhxqkb.do',
        'XNXQDM=' + encodeURIComponent(semesterId) + '&pageSize=9999&pageNumber=1');
      var exams = request('POST',
        'https://ehallapp.nju.edu.cn/jwapp/sys/studentWdksapApp/WdksapController/cxxsksap.do',
        'requestParamStr=' + encodeURIComponent(JSON.stringify({
          XNXQDM: semesterId,
          '*order': '-KSRQ,-KSSJMS'
        })));

      return {
        semester: semester,
        courses: rows(courses, ['datas', 'cxxszhxqkb', 'rows']),
        exams: rows(exams, ['datas', 'cxxsksap', 'rows'])
      };
    ''');
  }

  static Future<Map<String, dynamic>> _readGraduate(
      WebViewController controller) async {
    return _runApiScript(controller, r'''
      var semesters = request('POST',
        'https://ehallapp.nju.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/kfdxnxqcx.do');
      var semesterRows = rows(semesters, ['datas', 'kfdxnxqcx', 'rows']);
      var cutoff = Date.now() + 14 * 24 * 60 * 60 * 1000;
      var eligible = semesterRows.filter(function (row) {
        return row.KBKFRQ && new Date(row.KBKFRQ).getTime() <= cutoff;
      });
      if (!eligible.length) throw new Error('eHall did not return an available graduate semester');
      eligible.sort(function (a, b) {
        return new Date(a.KBKFRQ).getTime() - new Date(b.KBKFRQ).getTime();
      });
      var semester = eligible[eligible.length - 1];
      var semesterId = String(semester.XNXQDM || '');
      if (!semesterId) throw new Error('eHall graduate semester has no XNXQDM');

      var courses = request('POST',
        'https://ehallapp.nju.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/xspkjgcx.do',
        'XNXQDM=' + encodeURIComponent(semesterId) + '&XH=');
      var tasks = request('POST',
        'https://ehallapp.nju.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/xsjxrwcx.do',
        'XNXQDM=' + encodeURIComponent(semesterId) + '&XH=&pageNumber=1&pageSize=100');

      return {
        semester: semester,
        courses: rows(courses, ['datas', 'xspkjgcx', 'rows']),
        tasks: rows(tasks, ['datas', 'xsjxrwcx', 'rows'])
      };
    ''');
  }

  static Future<Map<String, dynamic>> _runApiScript(
    WebViewController controller,
    String body,
  ) async {
    final script = '''
      (function () {
        function request(method, url, data) {
          var xhr = new XMLHttpRequest();
          xhr.open(method, url, false);
          xhr.setRequestHeader('Accept', 'application/json, text/plain, */*');
          if (method === 'POST') {
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
          }
          xhr.send(data || null);
          if (xhr.status < 200 || xhr.status >= 300) {
            throw new Error(method + ' ' + url + ' failed with HTTP ' + xhr.status);
          }
          return JSON.parse(xhr.responseText);
        }
        function rows(data, path) {
          var current = data;
          for (var i = 0; i < path.length; i++) {
            current = current && current[path[i]];
          }
          return Array.isArray(current) ? current : [];
        }
        try {
          var result = (function () { $body })();
          return encodeURIComponent(JSON.stringify({ok: true, data: result}));
        } catch (error) {
          return encodeURIComponent(JSON.stringify({ok: false, error: String(error)}));
        }
      })();
    ''';
    final raw =
        (await controller.runJavaScriptReturningResult(script)).toString();
    var response = raw;
    if (response.startsWith('"') && response.endsWith('"')) {
      response = response.substring(1, response.length - 1);
    }
    final decoded =
        jsonDecode(Uri.decodeComponent(response.replaceAll('"', '')));
    if (decoded is! Map) {
      throw const FormatException(
          'eHall API script returned a non-object result');
    }
    if (decoded['ok'] != true) {
      throw Exception(
          'eHall JSON request failed: ${decoded['error'] ?? 'unknown error'}');
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw const FormatException('eHall API script returned no data object');
    }
    return Map<String, dynamic>.from(data);
  }

  static Map<String, dynamic> _adaptUndergraduate(Map<String, dynamic> raw) {
    final semester = _map(raw['semester']);
    final examsByCourse = <String, Map<String, dynamic>>{};
    for (final exam in _maps(raw['exams'])) {
      final name = _text(exam['KCM']);
      if (name.isNotEmpty && !examsByCourse.containsKey(name)) {
        examsByCourse[name] = exam;
      }
    }

    final courses = <Map<String, dynamic>>[];
    for (final row in _maps(raw['courses'])) {
      final start = _int(row['KSJC']);
      final end = _int(row['JSJC']);
      final weekday = _int(row['SKXQ']);
      if (start <= 0 || end < start || weekday <= 0) continue;
      final name = _text(row['KCM']);
      final exam = examsByCourse[name];
      courses.add(_courseMap(
        name: name,
        classroom: _text(row['JASMC']),
        classNumber: _text(row['KCDM']),
        teacher: _nonEmpty(row['JSHS'], row['SKJS']),
        testTime: _examTime(exam),
        testLocation: _textOrNull(exam?['JASMC']),
        weeks: _weeksFromBitmap(_text(row['SKZC'])),
        weekday: weekday,
        start: start,
        timeCount: end - start,
        info: _info([
          _label('教学班', row['JXBMC']),
          _label('上课班级', row['SKBJ']),
          _label('校区', row['XXXQDM_DISPLAY']),
        ]),
      ));
    }
    return {
      'name': _nonEmpty(semester['MC'], semester['DM']),
      'courses': courses
    };
  }

  static Map<String, dynamic> _adaptGraduate(Map<String, dynamic> raw) {
    final semester = _map(raw['semester']);
    final campusByCourse = <String, String>{
      for (final task in _maps(raw['tasks']))
        if (_text(task['KCDM']).isNotEmpty)
          _text(task['KCDM']): _text(task['XQDM_DISPLAY']),
    };

    final courses = <Map<String, dynamic>>[];
    for (final row in _maps(raw['courses'])) {
      final start = _periodForStart(_int(row['KSSJ']));
      final end = _periodForEnd(_int(row['JSSJ']));
      final weekday = _int(row['XQ']);
      if (start <= 0 || end < start || weekday <= 0) continue;
      final campus = campusByCourse[_text(row['KCDM'])] ?? '';
      courses.add(_courseMap(
        name: _nonEmpty(row['KCMC'], row['BJMC']),
        classroom: _text(row['JASMC']),
        classNumber: _text(row['KCDM']),
        teacher: _text(row['JSXM']),
        weeks: _weeksFromBitmap(_text(row['ZCBH'])),
        weekday: weekday,
        start: start,
        timeCount: end - start,
        info: _info([
          _label('教学班', row['BJMC']),
          _label('校区', campus),
          _label('选课备注', row['XKBZ']),
        ]),
      ));
    }
    return {
      'name': _nonEmpty(semester['XNXQDM_DISPLAY'], semester['XNXQDM']),
      'courses': courses,
    };
  }

  static Map<String, dynamic> _courseMap({
    required String name,
    required String classroom,
    required String classNumber,
    required String teacher,
    String? testTime,
    String? testLocation,
    required List<int> weeks,
    required int weekday,
    required int start,
    required int timeCount,
    String? info,
  }) =>
      {
        'name': name,
        'classroom': classroom,
        'class_number': classNumber,
        'teacher': teacher,
        'test_time': testTime,
        'test_location': testLocation,
        'link': null,
        'weeks': weeks,
        'week_time': weekday,
        'start_time': start,
        'time_count': timeCount,
        'import_type': 1,
        'info': info,
        'data': null,
      };

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static int _int(dynamic value) => int.tryParse(_text(value)) ?? 0;

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String _nonEmpty(dynamic preferred, dynamic fallback) {
    final first = _text(preferred);
    return first.isNotEmpty ? first : _text(fallback);
  }

  static String? _textOrNull(dynamic value) {
    final text = _text(value);
    return text.isEmpty || text == 'null' ? null : text;
  }

  static List<int> _weeksFromBitmap(String bitmap) => [
        for (var i = 0; i < bitmap.length; i++)
          if (bitmap[i] == '1') i + 1,
      ];

  static String? _examTime(Map<String, dynamic>? exam) {
    if (exam == null) return null;
    final date = _text(exam['KSRQ']);
    final start = _text(exam['KSKSSJ']);
    final end = _text(exam['KSJSSJ']);
    if (date.isEmpty || start.isEmpty || end.isEmpty) return null;
    return '$date $start-$end';
  }

  static String? _label(String label, dynamic value) {
    final text = _textOrNull(value);
    return text == null ? null : '$label：$text';
  }

  static String? _info(Iterable<String?> lines) {
    final values = lines.whereType<String>().toList();
    return values.isEmpty ? null : values.join('\n');
  }

  // Graduate APIs return clock times. This is the existing NJU period grid,
  // expressed here only to adapt the JSON response back to this app's model.
  static const _periodStarts = <int>[
    800,
    900,
    1010,
    1110,
    1400,
    1500,
    1610,
    1710,
    1830,
    1930,
    2030,
    2130,
    2230
  ];
  static const _periodEnds = <int>[
    850,
    950,
    1100,
    1200,
    1450,
    1550,
    1700,
    1800,
    1920,
    2020,
    2120,
    2220,
    2320
  ];

  static int _periodForStart(int value) => _periodStarts.indexOf(value) + 1;

  static int _periodForEnd(int value) => _periodEnds.indexOf(value) + 1;
}
