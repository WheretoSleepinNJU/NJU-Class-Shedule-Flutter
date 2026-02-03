import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../Resources/Constant.dart';
import './CourseModel.dart';
import './Db/DbHelper.dart';

const String tableName = DbHelper.COURSETABLE_TABLE_NAME;
const String columnId = DbHelper.COURSETABLE_COLUMN_ID;
const String columnName = DbHelper.COURSETABLE_COLUMN_NAME;
const String columnData = DbHelper.COURSETABLE_COLUMN_DATA;

class CourseTable {
  int? id;
  String? name;
  String? data;

//  CourseTable(id, name){
//    this.id = id;
//    this.name = name;
//  };
  CourseTable(this.name, {this.data = ''});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnData: data,
    };
    if (id != null) {
      map[columnId] = id;
      map[columnData] = data;
    }
    return map;
  }

  CourseTable.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    data = map[columnData];
  }
}

class CourseTableProvider {
  Database? db;
  DbHelper dbHelper = DbHelper();

  Future open() async {
    db = await dbHelper.open();
  }

  Future close() async => db!.close();

  Future<CourseTable> insert(CourseTable courseTable) async {
    await open();
    courseTable.id = await db!.insert(tableName, courseTable.toMap());
//    await close();
    return courseTable;
  }

  Future<CourseTable?> getCourseTable(int id) async {
    await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName,
        columns: [columnId, columnName],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return CourseTable.fromMap(maps.first);
    }
//    await close();
    return null;
  }

  Future<List> getAllCourseTable() async {
    await open();
    List<Map> rst = await db!.query(tableName, columns: [columnId, columnName]);
//    await close();
    return rst.toList();
  }

  Future<List<Map>> getClassTimeList(int id) async {
    await open();
    List<Map> defaultClassTimeList = Constant.CLASS_TIME_LIST;

    List<Map<String, dynamic>> maps = await db!.query(tableName,
        columns: [columnId, columnName, columnData],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isEmpty || maps[0]["data"] == null) {
      return defaultClassTimeList;
    }
    // print(maps);
    try {
      Map rst = json.decode(maps[0]["data"]);
      if (rst["class_time_list"] == null) {
        return defaultClassTimeList;
      }
      // print(rst["class_time_list"]);
      return List<Map>.from(rst["class_time_list"]);
    } catch (e) {
      // print(e);
      return defaultClassTimeList;
    }
  }

  Future<String> getSemesterStartMonday(int id) async {
    await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName,
        columns: [columnId, columnName, columnData],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isEmpty || maps[0]["data"] == null || maps[0]["data"] == "") {
      return "";
    }
    try {
      Map rst = json.decode(maps[0]["data"]);
      if (rst["semester_start_monday"] == null) {
        return "";
      }
      return rst["semester_start_monday"];
    } catch (e) {
      // print(e);
      return "";
    }
  }

  Future<int> delete(int id) async {
    await open();
    CourseProvider courseProvider = CourseProvider();
    await courseProvider.deleteByTable(id);
    int rst =
        await db!.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
//    await close();
    return rst;
  }

  Future<int> update(CourseTable courseTable) async {
    await open();
    int rst = await db!.update(tableName, courseTable.toMap(),
        where: '$columnId = ?', whereArgs: [courseTable.id]);
//    await close();
    return rst;
  }
}
