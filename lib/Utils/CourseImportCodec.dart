import 'dart:convert';

import '../Models/CourseModel.dart';

class CourseImportCodec {
  static String normalizeCourseTableName(
    dynamic rawName, {
    String fallback = '自动导入',
  }) {
    final text = (rawName ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static List<Map<String, dynamic>> normalizeOnlineCourses(dynamic rawCourses) {
    final List<dynamic> decodedCourses = _decodeCourseList(rawCourses);
    final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
    final Set<String> fingerprints = <String>{};

    for (final dynamic item in decodedCourses) {
      if (item is! Map) {
        continue;
      }
      final course = _normalizeOnlineCourseMap(Map<String, dynamic>.from(item));
      if (course == null) {
        continue;
      }
      final fingerprint = _fingerprint(course);
      if (!fingerprints.add(fingerprint)) {
        continue;
      }
      normalized.add(course);
    }
    return normalized;
  }

  static Map<String, dynamic> dbCourseToOnlineCourseMap(
      Map<String, dynamic> row) {
    return <String, dynamic>{
      'name': row[columnName] ?? '',
      'classroom': row[columnClassroom] ?? '',
      'class_number': row[columnClassNumber] ?? '',
      'teacher': row[columnTeacher] ?? '',
      'test_time': row[columnTestTime] ?? '',
      'test_location': row[columnTestLocation] ?? '',
      'link': row[columnLink] ?? '',
      'info': row[columnInfo] ?? '',
      'weeks': _normalizeWeeks(row[columnWeeks]),
      'week_time': _toInt(row[columnWeekTime], 0),
      'start_time': _toInt(row[columnStartTime], 0),
      'time_count': _toInt(row[columnTimeCount], 0),
      'import_type': _toInt(row[columnImportType], 1),
      'course_id': _toNullableInt(row[columnCourseId]),
    };
  }

  static Map<String, dynamic> onlineCourseToDbMap(
    Map<String, dynamic> courseMap, {
    required int tableId,
  }) {
    final normalizedCourse = _normalizeOnlineCourseMap(courseMap) ?? courseMap;
    return <String, dynamic>{
      columnTableId: tableId,
      columnName: (normalizedCourse['name'] ?? '').toString(),
      columnClassroom: (normalizedCourse['classroom'] ?? '').toString(),
      columnClassNumber: (normalizedCourse['class_number'] ??
              normalizedCourse['classNumber'] ??
              '')
          .toString(),
      columnTeacher: (normalizedCourse['teacher'] ?? '').toString(),
      columnTestTime:
          (normalizedCourse['test_time'] ?? normalizedCourse['testTime'] ?? '')
              .toString(),
      columnTestLocation: (normalizedCourse['test_location'] ??
              normalizedCourse['testLocation'] ??
              '')
          .toString(),
      columnLink: (normalizedCourse['link'] ?? '').toString(),
      columnInfo: (normalizedCourse['info'] ?? '').toString(),
      columnWeeks: jsonEncode(_normalizeWeeks(
          normalizedCourse['weeks'] ?? normalizedCourse['week'])),
      columnWeekTime: _toInt(
          normalizedCourse['week_time'] ?? normalizedCourse['weekTime'], 0),
      columnStartTime: _toInt(
          normalizedCourse['start_time'] ?? normalizedCourse['startTime'], 0),
      columnTimeCount: _toInt(
          normalizedCourse['time_count'] ?? normalizedCourse['timeCount'], 0),
      columnImportType: _toInt(
          normalizedCourse['import_type'] ?? normalizedCourse['importType'], 1),
      // Align with online import behavior: do not carry explicit color.
      columnColor: null,
      columnCourseId: _toNullableInt(
          normalizedCourse['course_id'] ?? normalizedCourse['courseId']),
    };
  }

  static List<dynamic> _decodeCourseList(dynamic rawCourses) {
    dynamic current = rawCourses;
    for (int i = 0; i < 4; i++) {
      if (current is List) {
        return List<dynamic>.from(current);
      }
      if (current is! String) {
        break;
      }
      final text = current.trim();
      if (text.isEmpty) {
        return <dynamic>[];
      }
      try {
        current = jsonDecode(text);
      } catch (_) {
        return <dynamic>[];
      }
    }
    if (current is List) {
      return List<dynamic>.from(current);
    }
    return <dynamic>[];
  }

  static Map<String, dynamic>? _normalizeOnlineCourseMap(
    Map<String, dynamic> courseMap,
  ) {
    final name = (courseMap['name'] ?? '').toString().trim();
    final classroom = (courseMap['classroom'] ?? courseMap['position'] ?? '')
        .toString()
        .trim();
    final classNumber =
        (courseMap['class_number'] ?? courseMap['classNumber'] ?? '')
            .toString()
            .trim();
    final teacher = (courseMap['teacher'] ?? '').toString().trim();
    final testTime = (courseMap['test_time'] ?? courseMap['testTime'] ?? '')
        .toString()
        .trim();
    final testLocation =
        (courseMap['test_location'] ?? courseMap['testLocation'] ?? '')
            .toString()
            .trim();
    final info = (courseMap['info'] ?? '').toString().trim();
    final link = courseMap['link'];
    final weeks = _normalizeWeeks(courseMap['weeks'] ?? courseMap['week']);
    final sections = _normalizeWeeks(courseMap['sections']);
    final weekTime = _toInt(
      courseMap['week_time'] ??
          courseMap['weekTime'] ??
          courseMap['day'] ??
          courseMap['weekday'],
      0,
    );
    final explicitStart =
        _toInt(courseMap['start_time'] ?? courseMap['startTime'], -1);
    final explicitTimeCount =
        _toInt(courseMap['time_count'] ?? courseMap['timeCount'], -1);
    final computedStart =
        explicitStart > 0 ? explicitStart : _reduceOrDefault(sections, true);
    final computedEnd =
        _reduceOrDefault(sections, false, fallback: computedStart);
    final timeCount = explicitTimeCount >= 0
        ? explicitTimeCount
        : _safeSectionSpan(computedStart, computedEnd);

    if (name.isEmpty || weekTime <= 0 || computedStart <= 0 || timeCount < 0) {
      return null;
    }

    return <String, dynamic>{
      'name': name,
      'classroom': classroom,
      'class_number': classNumber,
      'teacher': teacher,
      'test_time': testTime,
      'test_location': testLocation,
      'link': link,
      'info': info,
      'weeks': weeks,
      'week_time': weekTime,
      'start_time': computedStart,
      'time_count': timeCount,
      'import_type':
          _toInt(courseMap['import_type'] ?? courseMap['importType'], 1),
      'course_id':
          _toNullableInt(courseMap['course_id'] ?? courseMap['courseId']),
      'data': courseMap['data'],
    };
  }

  static String _fingerprint(Map<String, dynamic> course) {
    return <Object?>[
      course['name'],
      course['class_number'],
      course['teacher'],
      course['classroom'],
      course['week_time'],
      course['start_time'],
      course['time_count'],
      jsonEncode(course['weeks']),
    ].join('|');
  }

  static List<int> _normalizeWeeks(dynamic weeksRaw) {
    if (weeksRaw is List) {
      return weeksRaw.map((e) => _toInt(e, -1)).where((e) => e > 0).toList();
    }
    final text = (weeksRaw ?? '').toString().trim();
    if (text.isEmpty) {
      return <int>[];
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((e) => _toInt(e, -1)).where((e) => e > 0).toList();
      }
    } catch (_) {}
    final matches = RegExp(r'\d+').allMatches(text);
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '') ?? -1)
        .where((e) => e > 0)
        .toList();
  }

  static int _toInt(dynamic v, int fallback) {
    if (v is int) {
      return v;
    }
    return int.tryParse((v ?? '').toString()) ?? fallback;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static int _reduceOrDefault(
    List<int> values,
    bool takeMin, {
    int fallback = 0,
  }) {
    if (values.isEmpty) {
      return fallback;
    }
    return values
        .reduce((int a, int b) => takeMin ? (a < b ? a : b) : (a > b ? a : b));
  }

  static int _safeSectionSpan(int start, int end) {
    if (start <= 0 || end <= 0) {
      return 0;
    }
    return end >= start ? end - start : 0;
  }
}
