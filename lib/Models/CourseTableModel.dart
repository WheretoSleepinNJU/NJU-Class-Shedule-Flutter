import 'package:sqflite/sqflite.dart';
import './CourseModel.dart';
import './Db/DbHelper.dart';

final String tableName = DbHelper.COURSETABLE_TABLE_NAME;
final String columnId = DbHelper.COURSETABLE_COLUMN_ID;
final String columnName = DbHelper.COURSETABLE_COLUMN_NAME;

class CourseTable {
  int? id;
  String? name;

//  CourseTable(id, name){
//    this.id = id;
//    this.name = name;
//  };
  CourseTable(this.name);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  CourseTable.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
  }
}


class CourseTableProvider {
  Database? db;
  DbHelper dbHelper = new DbHelper();

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
    if (maps.length > 0) {
      return CourseTable.fromMap(maps.first);
    }
//    await close();
    return null;
  }

  Future<List> getAllCourseTable() async {
    await open();
    List<Map> rst = await db!.query(tableName,
        columns: [columnId, columnName]);
//    await close();
    return rst.toList();
  }

  Future<int> delete(int id) async {
    await open();
    CourseProvider courseProvider = new CourseProvider();
    await courseProvider.deleteByTable(id);
    int rst = await db!.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
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