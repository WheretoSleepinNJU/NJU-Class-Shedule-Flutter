import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static final int DATABASE_VERSION = 2;
  static final String DATABASE_NAME = "course.db";

  static final String TEXT_TYPE = " TEXT";
  static final String INTEGER_TYPE = " INTEGER";

  static final String COMMA_SEP = ",";

  static final String COURSE_TABLE_NAME = "Course";
  static final String COURSE_COLUMN_ID = 'id';
  static final String COURSE_COLUMN_NAME = 'name';
  static final String COURSE_COLUMN_COURSETABLEID = 'tableid';
  static final String COURSE_COLUMN_CLASS_ROOM = "classroom";
  static final String COURSE_COLUMN_CLASS_NUMBER = "class_number";
  static final String COURSE_COLUMN_TEACHER = "teacher";
  static final String COURSE_COLUMN_TEST_TIME = "test_time";
  static final String COURSE_COLUMN_TEST_LOCATION = "test_location";
  static final String COURSE_COLUMN_INFO_LINK = "link";

  static final String COURSE_COLUMN_WEEKS = "weeks";
  static final String COURSE_COLUMN_WEEK_TIME = "week_time";
  static final String COURSE_COLUMN_START_TIME = "start_time";
  static final String COURSE_COLUMN_TIME_COUNT = "time_count";
  static final String COURSE_COLUMN_IMPORT_TYPE = "import_type";
  static final String COURSE_COLUMN_COLOR = "color";
  static final String COURSE_COLUMN_COURSE_ID = "course_id";

  static final String COURSETABLE_TABLE_NAME = "CourseTable";
  static final String COURSETABLE_COLUMN_ID = 'id';
  static final String COURSETABLE_COLUMN_NAME = 'name';

  static final String SQL_CREATE_COURSES =
      "CREATE TABLE " + COURSE_TABLE_NAME + " (" +
          COURSE_COLUMN_ID + INTEGER_TYPE + " PRIMARY KEY AUTOINCREMENT" + COMMA_SEP +
          COURSE_COLUMN_COURSETABLEID + INTEGER_TYPE + COMMA_SEP +

          //TODO: REMOVE THIS LINE
//          COURSE_COLUMN_NAME + TEXT_TYPE +
          COURSE_COLUMN_NAME + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_CLASS_ROOM + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_CLASS_NUMBER + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_TEACHER + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_TEST_TIME + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_TEST_LOCATION + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_INFO_LINK + TEXT_TYPE + COMMA_SEP +

          COURSE_COLUMN_WEEKS + TEXT_TYPE + COMMA_SEP +

          COURSE_COLUMN_WEEK_TIME + INTEGER_TYPE + COMMA_SEP +
          COURSE_COLUMN_START_TIME + INTEGER_TYPE + COMMA_SEP +
          COURSE_COLUMN_TIME_COUNT + INTEGER_TYPE + COMMA_SEP +

          COURSE_COLUMN_IMPORT_TYPE + INTEGER_TYPE + COMMA_SEP +
          COURSE_COLUMN_COLOR + TEXT_TYPE + COMMA_SEP +
          COURSE_COLUMN_COURSE_ID + INTEGER_TYPE +
//
//          COLUMN_NAME_WEEK + INTEGER_TYPE + COMMA_SEP +
//          COLUMN_NAME_START_WEEK + INTEGER_TYPE + COMMA_SEP +
//          COLUMN_NAME_END_WEEK + INTEGER_TYPE + COMMA_SEP +
//          COLUMN_NAME_WEEK_TYPE + INTEGER_TYPE + COMMA_SEP +
//
//          COLUMN_NAME_SOURCE + TEXT_TYPE +
          " )";

//  static final String SQL_CREATE_NODE =
//      "CREATE TABLE " + CoursesPsc.NodeEntry.TABLE_NAME + " (" +
//          CoursesPsc.NodeEntry.COLUMN_NAME_COURSE_ID + INTEGER_TYPE + COMMA_SEP +
//          CoursesPsc.NodeEntry.COLUMN_NAME_NODE_NUM + INTEGER_TYPE +
//          " )";

  static final String SQL_CREATE_COURSETABLE =
      "CREATE TABLE " + COURSETABLE_TABLE_NAME + " (" +
          COURSETABLE_COLUMN_ID + INTEGER_TYPE + " PRIMARY KEY AUTOINCREMENT" + COMMA_SEP +
          COURSETABLE_COLUMN_NAME + TEXT_TYPE +
          " )";

  Future<Database> open() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, DATABASE_NAME);
    Database db = await openDatabase(path, version: DATABASE_VERSION,
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          try{
            await db.query(COURSETABLE_TABLE_NAME);
          } catch(e){
            await db.execute(SQL_CREATE_COURSETABLE);
            await db.execute(SQL_CREATE_COURSES);
          }
          print('From Upgrade');
        },
        onCreate: (Database db, int version) async {
          await db.execute(SQL_CREATE_COURSETABLE);
          await db.execute(SQL_CREATE_COURSES);
          print('From OnCreate');
        });
    return db;
  }
}
