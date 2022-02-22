import 'package:sqflite/sqflite.dart';
import '../Resources/Colors.dart';
import './Db/DbHelper.dart';

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

  String? weeks;
  int? weekTime;
  int? startTime;
  int? timeCount;
  int? importType;
  String? color;
  int? courseId;

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
    if (color != null) return color;
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
        columns: [columnId, columnName],
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
