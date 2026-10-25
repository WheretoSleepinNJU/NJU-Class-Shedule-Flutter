import 'dart:convert';
import '../Models/Db/DbHelper.dart';
import 'CourseImportCodec.dart';

/// Accept both existing encodeURIComponent scripts and raw JSON results.
Map<String, dynamic> decodeOnlineImportResult(Object result) {
  dynamic value = result;
  for (var i = 0; i < 6 && value is String; i++) {
    final text = value.trim();
    try {
      value = jsonDecode(text);
    } on FormatException {
      final decoded = Uri.decodeComponent(text);
      if (decoded == text) rethrow;
      value = decoded;
    }
  }
  if (value is! Map ||
      value['name'] is! String ||
      (value['name'] as String).trim().isEmpty) {
    throw const FormatException('Expected a timetable with name and courses');
  }
  dynamic courses = value['courses'];
  for (var i = 0; i < 3 && courses is String; i++) {
    courses = jsonDecode(courses);
  }
  if (courses is! List || courses.any((c) => c is! Map)) {
    throw const FormatException('courses must be an array of course objects');
  }
  return {...Map<String, dynamic>.from(value), 'courses': courses};
}

Future<int> saveOnlineImport(Map<String, dynamic> data, Map config) async {
  // Normalize every row before creating anything, then commit as one operation.
  final rows =
      (data['courses'] as List)
          .map(
            (row) => CourseImportCodec.onlineCourseToDbMap(
              Map<String, dynamic>.from(row),
              tableId: 0,
            ),
          )
          .toList();
  final metadata = <String, dynamic>{
    if (config['class_time_list'] != null)
      'class_time_list': config['class_time_list'],
    if (config['semester_start_monday'] != null)
      'semester_start_monday': config['semester_start_monday'],
  };
  final db = await DbHelper().open();
  return db.transaction((txn) async {
    final id = await txn.insert(DbHelper.COURSETABLE_TABLE_NAME, {
      'name': data['name'].trim(),
      'data': metadata.isEmpty ? '' : jsonEncode(metadata),
    });
    final batch = txn.batch();
    for (final row in rows) {
      batch.insert(DbHelper.COURSE_TABLE_NAME, {...row, 'tableid': id});
    }
    await batch.commit(noResult: true);
    return id;
  });
}
