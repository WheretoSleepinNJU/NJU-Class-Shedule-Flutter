import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Models/CourseTableModel.dart';
import 'package:wheretosleepinnju/Utils/InitUtil.dart';

class FakeCourseTableProvider extends CourseTableProvider {
  FakeCourseTableProvider(this.tables, {this.pendingInsert});

  final List<Map<String, dynamic>> tables;
  final Completer<CourseTable>? pendingInsert;
  int insertCount = 0;

  @override
  Future<List> getAllCourseTable() async => List.of(tables);

  @override
  Future<CourseTable> insert(CourseTable table) async {
    insertCount++;
    return pendingInsert!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch waits for insertion and selects the returned table ID',
      () async {
    SharedPreferences.setMockInitialValues({});
    final insert = Completer<CourseTable>();
    final provider = FakeCourseTableProvider([], pendingInsert: insert);
    var initialized = false;
    final initialization = InitUtil.checkDataBase(provider: provider)
        .then((_) => initialized = true);
    await Future<void>.delayed(Duration.zero);
    expect(provider.insertCount, 1);
    expect(initialized, isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('tableId'), isNull);
    insert.complete(CourseTable('默认课表')..id = 7);
    await initialization;
    expect(preferences.getInt('tableId'), 7);
  });

  for (final staleId in [0, 99]) {
    test('repairs stale selection $staleId without creating a duplicate table',
        () async {
      SharedPreferences.setMockInitialValues({'tableId': staleId});
      final provider = FakeCourseTableProvider([
        {columnId: 7, columnName: '已有课表'},
      ]);
      await InitUtil.checkDataBase(provider: provider);
      expect((await SharedPreferences.getInstance()).getInt('tableId'), 7);
      expect(provider.insertCount, 0);
    });
  }

  test('preserves a valid selected table', () async {
    SharedPreferences.setMockInitialValues({'tableId': 9});
    final provider = FakeCourseTableProvider([
      {columnId: 7, columnName: '课表一'},
      {columnId: 9, columnName: '课表二'},
    ]);
    await InitUtil.checkDataBase(provider: provider);
    expect((await SharedPreferences.getInstance()).getInt('tableId'), 9);
    expect(provider.insertCount, 0);
  });
}
