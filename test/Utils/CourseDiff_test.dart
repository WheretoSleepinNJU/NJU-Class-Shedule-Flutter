import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Utils/CourseDiff.dart';

Course _course({
  required String name,
  String? classNumber,
  String? teacher,
  String? classroom,
  String? info,
  int weekTime = 1,
  int startTime = 1,
  int timeCount = 1,
  String weeks = '[1,2,3]',
}) {
  return Course(1, name, weeks, weekTime, startTime, timeCount, 1,
      classNumber: classNumber, teacher: teacher, classroom: classroom, info: info);
}

void main() {
  test('courseGroupKey prefers classNumber, falls back to name+teacher', () {
    final withNumber = _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三');
    final withoutNumber = _course(name: '高等数学', classNumber: '', teacher: '张三');

    expect(courseGroupKey(withNumber), 'no:MATH101');
    expect(courseGroupKey(withoutNumber), 'nt:高等数学|张三');
  });

  test('classroom change on same weekday is detected as changedSlots', () {
    final oldList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', classroom: '仙Ⅰ-101'),
    ];
    final newList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', classroom: '仙Ⅰ-202'),
    ];

    final diff = diffCourseLists(oldList, newList);

    expect(diff.addedCourses, isEmpty);
    expect(diff.removedCourses, isEmpty);
    expect(diff.changedSlots.length, 1);
    expect(diff.changedSlots.first.changedFields['classroom']?.key, '仙Ⅰ-101');
    expect(diff.changedSlots.first.changedFields['classroom']?.value, '仙Ⅰ-202');
  });

  test('no changes yields empty diff', () {
    final list = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', classroom: '仙Ⅰ-101'),
    ];
    final diff = diffCourseLists(list, List.of(list));
    expect(diff.isEmpty, isTrue);
  });

  test('whole course group added/removed', () {
    final oldList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三'),
    ];
    final newList = [
      _course(name: '大学物理', classNumber: 'PHYS101', teacher: '李四'),
    ];

    final diff = diffCourseLists(oldList, newList);

    expect(diff.removedCourses.containsKey('no:MATH101'), isTrue);
    expect(diff.addedCourses.containsKey('no:PHYS101'), isTrue);
    expect(diff.changedSlots, isEmpty);
  });

  test('new time slot added within same course group', () {
    final oldList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 1),
    ];
    final newList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 1),
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 3),
    ];

    final diff = diffCourseLists(oldList, newList);

    expect(diff.addedCourses, isEmpty);
    expect(diff.removedCourses, isEmpty);
    expect(diff.addedSlots.length, 1);
    expect(diff.addedSlots.first.weekTime, 3);
    expect(diff.removedSlots, isEmpty);
  });

  test('time slot removed within same course group', () {
    final oldList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 1),
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 3),
    ];
    final newList = [
      _course(name: '高等数学', classNumber: 'MATH101', teacher: '张三', weekTime: 1),
    ];

    final diff = diffCourseLists(oldList, newList);

    expect(diff.removedSlots.length, 1);
    expect(diff.removedSlots.first.weekTime, 3);
  });
}
