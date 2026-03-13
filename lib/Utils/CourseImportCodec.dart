import 'dart:convert';

import '../Models/CourseModel.dart';

class CourseImportCodec {
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
    return <String, dynamic>{
      columnTableId: tableId,
      columnName: (courseMap['name'] ?? '').toString(),
      columnClassroom: (courseMap['classroom'] ?? '').toString(),
      columnClassNumber:
          (courseMap['class_number'] ?? courseMap['classNumber'] ?? '')
              .toString(),
      columnTeacher: (courseMap['teacher'] ?? '').toString(),
      columnTestTime:
          (courseMap['test_time'] ?? courseMap['testTime'] ?? '').toString(),
      columnTestLocation:
          (courseMap['test_location'] ?? courseMap['testLocation'] ?? '')
              .toString(),
      columnLink: (courseMap['link'] ?? '').toString(),
      columnInfo: (courseMap['info'] ?? '').toString(),
      columnWeeks: jsonEncode(_normalizeWeeks(courseMap['weeks'])),
      columnWeekTime:
          _toInt(courseMap['week_time'] ?? courseMap['weekTime'], 0),
      columnStartTime:
          _toInt(courseMap['start_time'] ?? courseMap['startTime'], 0),
      columnTimeCount:
          _toInt(courseMap['time_count'] ?? courseMap['timeCount'], 0),
      columnImportType:
          _toInt(courseMap['import_type'] ?? courseMap['importType'], 1),
      // Align with online import behavior: do not carry explicit color.
      columnColor: null,
      columnCourseId:
          _toNullableInt(courseMap['course_id'] ?? courseMap['courseId']),
    };
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
}
