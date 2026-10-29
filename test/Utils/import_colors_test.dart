import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/Db/DbHelper.dart';
import 'package:wheretosleepinnju/Resources/Colors.dart';
import 'package:wheretosleepinnju/Utils/OnlineImportService.dart';

class MemoryDatabase implements Database, Transaction {
  final courses = <Map<String, Object?>>[];
  final tables = <Map<String, Object?>>[];
  int updates = 0;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async => action(this);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = table == DbHelper.COURSE_TABLE_NAME ? courses : tables;
    final id =
        rows.fold<int>(
          0,
          (highest, row) =>
              (row['id'] as int? ?? 0) > highest ? row['id'] as int : highest,
        ) +
        1;
    rows.add({...values, 'id': id});
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async => [
    {
      'maxId': courses
          .map((row) => row[columnCourseId])
          .whereType<int>()
          .fold<int?>(
            null,
            (highest, id) => highest == null || id > highest ? id : highest,
          ),
    },
  ];

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final rows = courses.where(
      (row) =>
          where == null ||
          (where == '$columnCourseId IS NULL' && row[columnCourseId] == null),
    );
    return (limit == null ? rows : rows.take(limit))
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final row = courses.where((row) => row[columnId] == whereArgs!.first).first;
    if (row[columnCourseId] != null) return 0;
    row.addAll(values);
    updates++;
    return 1;
  }

  @override
  Batch batch() => MemoryBatch(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryBatch implements Batch {
  MemoryBatch(this.db);
  final MemoryDatabase db;
  final inserts = <MapEntry<String, Map<String, Object?>>>[];

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    inserts.add(MapEntry(table, Map.from(values)));
  }

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    for (final entry in inserts) {
      await db.insert(entry.key, entry.value);
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryDbHelper extends DbHelper {
  MemoryDbHelper(this.db);
  final MemoryDatabase db;
  @override
  Future<Database> open() async => db;
}

Map<String, dynamic> imported(String name, {String section = '', int? id}) => {
  'name': name,
  'class_number': section,
  'teacher': '测试教师',
  'weeks': [1, 2, 3],
  'week_time': 1,
  'start_time': 1,
  'time_count': 1,
  if (id != null) 'course_id': id,
};

List<Course> savedCourses(MemoryDatabase db) =>
    db.courses
        .map((row) => Course.fromMap(Map<String, dynamic>.from(row)))
        .toList();

void main() {
  final palette = List.generate(colorList.length, (i) => i);

  test(
    'online batch import gives distinct courses distinct default colors',
    () async {
      final db = MemoryDatabase();
      await saveOnlineImport(
        {
          'name': '新课表',
          'courses': [imported('高等数学'), imported('大学英语'), imported('程序设计')],
        },
        {},
        dbHelper: MemoryDbHelper(db),
      );
      final courses = savedCourses(db);
      expect(courses.map((c) => c.getColor(palette)).toSet(), hasLength(3));
      expect(courses.map((c) => c.courseId), everyElement(isNotNull));
    },
  );

  test(
    'colliding source IDs cannot collapse different course colors',
    () async {
      final db = MemoryDatabase();
      await saveOnlineImport(
        {
          'name': '新课表',
          'courses': [imported('高等数学', id: 0), imported('大学英语', id: 0)],
        },
        {},
        dbHelper: MemoryDbHelper(db),
      );
      expect(
        savedCourses(db).map((c) => c.getColor(palette)).toSet(),
        hasLength(2),
      );
    },
  );

  test(
    'multiple meetings share a color and keep their original row order',
    () async {
      final db = MemoryDatabase();
      await saveOnlineImport(
        {
          'name': '新课表',
          'courses': [
            imported('高等数学', section: 'M-01'),
            imported('大学英语'),
            {
              ...imported('高等数学', section: 'M-01'),
              'teacher': '研讨教师',
              'week_time': 5,
            },
            imported('高等数学', section: 'M-02'),
          ],
        },
        {'semester_start_monday': '2026-08-31'},
        dbHelper: MemoryDbHelper(db),
      );
      final courses = savedCourses(db);
      expect(courses.map((c) => c.name), ['高等数学', '大学英语', '高等数学', '高等数学']);
      expect(courses[0].courseId, courses[2].courseId);
      expect(courses[0].getColor(palette), courses[2].getColor(palette));
      expect(courses[3].courseId, isNot(courses[0].courseId));
      expect(courses[2].teacher, '研讨教师');
      expect(courses[2].weekTime, 5);
      expect(
        courses.map((c) => c.tableId),
        everyElement(db.tables.single['id']),
      );
    },
  );

  test('new imports allocate IDs beyond all existing timetables', () async {
    final db = MemoryDatabase();
    db.courses.add(
      Course(99, '已有课程', '[1]', 1, 1, 1, 1, id: 1, courseId: 40).toMap(),
    );
    await saveOnlineImport(
      {
        'name': '新课表',
        'courses': [imported('新课程甲', id: 0), imported('新课程乙', id: 0)],
      },
      {},
      dbHelper: MemoryDbHelper(db),
    );
    expect(savedCourses(db).map((c) => c.courseId), [40, 41, 42]);
  });

  test(
    'existing missing IDs recover distinct colors and remain stable on restart',
    () async {
      final db = MemoryDatabase();
      db.courses.addAll([
        Course(
          1,
          '高等数学',
          '[1]',
          1,
          1,
          1,
          1,
          id: 1,
          classNumber: 'M-01',
        ).toMap(),
        Course(1, '大学英语', '[1]', 2, 1, 1, 1, id: 2).toMap(),
        Course(
          1,
          '高等数学',
          '[1]',
          5,
          3,
          1,
          1,
          id: 3,
          classNumber: 'M-01',
        ).toMap(),
      ]);
      final provider = CourseProvider()..dbHelper = MemoryDbHelper(db);
      expect(await provider.repairMissingCourseIds(), 3);
      final first = savedCourses(db);
      expect(first.map((c) => c.getColor(palette)).toSet(), hasLength(2));
      expect(first[0].courseId, first[2].courseId);
      expect(await provider.repairMissingCourseIds(), 0);
      expect(
        savedCourses(db).map((c) => c.courseId),
        first.map((c) => c.courseId),
      );
      expect(db.updates, 3);
    },
  );

  test(
    'backfill retains valid IDs, explicit colors, and timetable boundaries',
    () async {
      final db = MemoryDatabase();
      db.courses.addAll([
        Course(
          1,
          '高等数学',
          '[1]',
          1,
          1,
          1,
          1,
          id: 1,
          courseId: 7,
          classNumber: 'M-01',
        ).toMap(),
        Course(
          1,
          '高等数学',
          '[1]',
          5,
          3,
          1,
          1,
          id: 2,
          classNumber: 'M-01',
          teacher: '研讨教师',
        ).toMap(),
        Course(
          2,
          '高等数学',
          '[1]',
          1,
          1,
          1,
          1,
          id: 3,
          classNumber: 'M-01',
          color: '#123456',
        ).toMap(),
      ]);
      final provider = CourseProvider()..dbHelper = MemoryDbHelper(db);
      expect(await provider.repairMissingCourseIds(), 2);
      final courses = savedCourses(db);
      expect(courses.map((c) => c.courseId), [7, 7, 8]);
      expect(courses[2].color, '#123456');
      expect(courses[2].getColor(palette), '#123456');
      expect(courses[1].teacher, '研讨教师');
    },
  );
}
