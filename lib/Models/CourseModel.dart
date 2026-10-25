import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../Resources/Colors.dart';
import './Db/DbHelper.dart';
import 'CourseGroup.dart';

const String tableName = DbHelper.COURSE_TABLE_NAME;
const String columnId = DbHelper.COURSE_COLUMN_ID;
const String columnName = DbHelper.COURSE_COLUMN_NAME;
const String columnTableId = DbHelper.COURSE_COLUMN_COURSETABLEID;
const String columnClassroom = DbHelper.COURSE_COLUMN_CLASS_ROOM;
const String columnClassNumber = DbHelper.COURSE_COLUMN_CLASS_NUMBER;
const String columnTeacher = DbHelper.COURSE_COLUMN_TEACHER;
const String columnTestTime = DbHelper.COURSE_COLUMN_TEST_TIME;
const String columnTestLocation = DbHelper.COURSE_COLUMN_TEST_LOCATION;
const String columnLink = DbHelper.COURSE_COLUMN_INFO_LINK;
const String columnInfo = DbHelper.COURSE_COLUMN_INFO;
const String columnWeeks = DbHelper.COURSE_COLUMN_WEEKS;
const String columnWeekTime = DbHelper.COURSE_COLUMN_WEEK_TIME;
const String columnStartTime = DbHelper.COURSE_COLUMN_START_TIME;
const String columnTimeCount = DbHelper.COURSE_COLUMN_TIME_COUNT;
const String columnImportType = DbHelper.COURSE_COLUMN_IMPORT_TYPE;
const String columnColor = DbHelper.COURSE_COLUMN_COLOR;
const String columnCourseId = DbHelper.COURSE_COLUMN_COURSE_ID;

class Course {
  int? id;
  String? name;
  int? tableId;

  String? classroom;
  String? classNumber;
  String? teacher;
  String? testTime;
  String? testLocation;
  String? link;
  String? info;

  String? weeks; //哪些周会上这个课
  int? weekTime; //星期几
  int? startTime;
  int? timeCount;
  int? importType;
  String? color;
  int? courseId;

  List<int> get weekNumbers {
    try {
      final values = jsonDecode(weeks ?? '[]');
      if (values is! List) return [];
      return values
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .where((week) => week > 0)
          .toSet()
          .toList()
        ..sort();
    } on FormatException {
      return [];
    }
  }

  Course(this.tableId, this.name, this.weeks, this.weekTime, this.startTime,
      this.timeCount, this.importType,
      {this.id,
      this.classroom,
      this.classNumber,
      this.teacher,
      this.testTime,
      this.testLocation,
      this.link,
      this.color,
      this.courseId,
      this.info});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnId: id,
      columnName: name,
      columnTableId: tableId,
      columnWeeks: weeks,
      columnWeekTime: weekTime,
      columnStartTime: startTime,
      columnTimeCount: timeCount,
      columnImportType: importType,
      columnColor: color,
      columnClassroom: classroom,
      columnClassNumber: classNumber,
      columnTeacher: teacher,
      columnTestTime: testTime,
      columnTestLocation: testLocation,
      columnLink: link,
      columnCourseId: courseId,
      columnInfo: info,
    };
    return map;
  }

  Course.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    tableId = map[columnTableId];

    classroom = map[columnClassroom];
    classNumber = map[columnClassNumber];
    teacher = map[columnTeacher];
    testTime = map[columnTestTime];
    testLocation = map[columnTestLocation];
    link = map[columnLink];
    info = map[columnInfo];

    weeks = map[columnWeeks].toString();
    weekTime = map[columnWeekTime];
    startTime = map[columnStartTime];
    timeCount = map[columnTimeCount];
    importType = map[columnImportType];
    color = map[columnColor];
    courseId = map[columnCourseId];
  }

  String? getColor(List colorPool) {
    final rawColor = color?.trim();
    if (rawColor != null && rawColor.isNotEmpty) {
      final normalized = rawColor.startsWith('#') ? rawColor.substring(1) : rawColor;
      final isValidHex = RegExp(r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(normalized);
      if (isValidHex) {
        return rawColor.startsWith('#') ? rawColor : '#$rawColor';
      }
    }
    if (courseId == null || colorPool.isEmpty) {
      return colorList.first;
    }
    return colorList[colorPool[courseId! % colorPool.length] as int];
  }
}

class CourseProvider {
  Database? db;
  DbHelper dbHelper = DbHelper();

  Future open() async {
    db = await dbHelper.open();
  }

  Future close() async => db!.close();

  Future<Course> insert(Course course) async {
    await open();
    course.courseId ??= await getCourseId(course);
//    print(course.toMap());
    course.id = await db!.insert(tableName, course.toMap());
//    await close();
    return course;
  }

  Future<Course?> getCourse(int id) async {
    await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName,
        where: '$columnId = ?',
        whereArgs: [id]);
//    await close();
    if (maps.isNotEmpty) {
      return Course.fromMap(maps.first);
    }
    return null;
  }

  Future<List> getAllCourses(int tableId) async {
    await open();
    List<Map> rst = await db!.query(tableName,
//        columns: [columnId, columnName],
        where: '$columnTableId = ?',
        whereArgs: [tableId]);
//    await close();
    return rst.toList();
  }

  Future<int> getCourseNum() async {
    await open();
    List<Map> rst = await db!.query(tableName);
    return rst.length;
  }

  Future<int> delete(int id) async {
    await open();
    int rst =
        await db!.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
//    await close();
    return rst;
  }

  Future<int> deleteByTable(int id) async {
    await open();
    int rst = await db!
        .delete(tableName, where: '$columnTableId = ?', whereArgs: [id]);
//    await close();
    return rst;
  }

  Future<int> update(Course course) async {
    await open();
    int rst = await db!.update(tableName, course.toMap(),
        where: '$columnId = ?', whereArgs: [course.id]);
//    await close();
    return rst;
  }

  Future<List<Course>> getMeetings(Course course) async {
    final rows = await getAllCourses(course.tableId!);
    return rows
        .map((row) => Course.fromMap(Map<String, dynamic>.from(row)))
        .where((item) => CourseGroup.sameCourse(course, item))
        .toList();
  }

  /// Commit all meetings together, including additions and removed meetings.
  Future<bool> saveMeetingGroup(
    List<Course> originals,
    List<Course> meetings,
  ) async {
    if (meetings.isEmpty || meetings.first.tableId == null) return false;
    final tableId = meetings.first.tableId!;
    final ids = originals.map((c) => c.id).toSet();
    final updatedIds = meetings
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toList();
    if (ids.contains(null) ||
        ids.length != originals.length ||
        updatedIds.toSet().length != updatedIds.length ||
        updatedIds.any((id) => !ids.contains(id)) ||
        meetings.any((c) => c.tableId != tableId) ||
        originals.any((c) => c.tableId != tableId)) {
      return false;
    }
    await open();
    return db!.transaction((txn) async {
      if (originals.isNotEmpty && !await _groupUnchanged(txn, originals)) {
        return false;
      }
      var courseId = originals.isEmpty ? null : originals.first.courseId;
      if (courseId == null) {
        final rows = await txn.rawQuery(
          'SELECT MAX($columnCourseId) AS maxId FROM $tableName',
        );
        courseId = ((rows.first['maxId'] as num?)?.toInt() ?? -1) + 1;
      }
      for (final meeting in meetings) {
        final data = meeting.toMap()..[columnCourseId] = courseId;
        if (meeting.id == null) {
          data.remove(columnId);
          await txn.insert(tableName, data);
        } else if (await txn.update(
              tableName,
              data,
              where: '$columnId = ? AND $columnTableId = ?',
              whereArgs: [meeting.id, tableId],
            ) !=
            1) {
          throw StateError('Course meeting disappeared while saving');
        }
      }
      for (final id in ids.difference(updatedIds.toSet())) {
        if (await txn.delete(
              tableName,
              where: '$columnId = ? AND $columnTableId = ?',
              whereArgs: [id, tableId],
            ) !=
            1) {
          throw StateError('Course meeting disappeared while removing');
        }
      }
      return true;
    });
  }

  Future<bool> _groupUnchanged(Transaction txn, List<Course> originals) async {
    final current = await txn.query(
      tableName,
      where: '$columnTableId = ?',
      whereArgs: [originals.first.tableId],
    );
    final group = current
        .where(
          (r) => CourseGroup.sameCourse(originals.first, Course.fromMap(r)),
        )
        .toList();
    // Never replace or delete a course changed while its editor was open.
    return group.length == originals.length &&
        originals.every((original) {
          final row = group
              .where((r) => r[columnId] == original.id)
              .firstOrNull;
          return row != null &&
              original.toMap().entries.every((e) => row[e.key] == e.value);
        });
  }

  Future<bool> deleteMeetingGroup(List<Course> originals) async {
    if (originals.isEmpty ||
        originals.first.tableId == null ||
        originals.any(
          (c) => c.id == null || c.tableId != originals.first.tableId,
        ) ||
        originals.map((c) => c.id).toSet().length != originals.length) {
      return false;
    }
    await open();
    return db!.transaction((txn) async {
      if (!await _groupUnchanged(txn, originals)) return false;
      for (final original in originals) {
        final count = await txn.delete(
          tableName,
          where: '$columnId = ? AND $columnTableId = ?',
          whereArgs: [original.id, original.tableId],
        );
        if (count != 1) {
          throw StateError('Course meeting disappeared while deleting');
        }
      }
      return true;
    });
  }

  Future<bool> checkHasClassByName(int tableId, String name) async {
    await open();
    List<Map> rst = await db!.query(tableName,
        where: '$columnTableId = ? and $columnName = ?',
        whereArgs: [tableId, name]);
    return rst.isNotEmpty;
  }

  //获取课程 courseid，如果存在已有课程则为已有课程，否则指定新id
  Future<int> getCourseId(Course course) async {
    List<Map> rst = await db!.query(tableName,
        where: '$columnName = ? and $columnTableId = ?',
        whereArgs: [course.name, course.tableId]);
    if (rst.isNotEmpty) return rst[0][columnCourseId];
    var maxId =
        await db!.rawQuery('SELECT MAX($columnCourseId) FROM $tableName');
    List maxIdList = maxId.toList();
//    print(maxIdList);
    if (maxIdList.isEmpty || maxIdList[0]['MAX($columnCourseId)'] == null) {
      return 0;
    } else {
      return maxIdList[0]['MAX($columnCourseId)'] + 1;
    }
  }
}
