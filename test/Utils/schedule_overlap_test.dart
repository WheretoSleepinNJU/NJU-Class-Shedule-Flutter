import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Models/ScheduleModel.dart';

void main() {
  Course course(String name, String weeks) => Course(1,name,weeks,6,1,0,0);

  test('single-period current course leads mixed-week overlap without duplicate cards', () {
    final current=course('current','[1]');
    final schedule=ScheduleModel([current,course('other A','[2]'),course('other B','[2]')],1)..init();
    expect(schedule.multiCourses.single.first,same(current));
    expect(schedule.multiCourses.single.length,3);
    expect(schedule.activeCourses,isEmpty);
    expect(schedule.hideCourses,isEmpty);
  });
  test('third current overlapping course is rendered only in its group', () {
    final schedule=ScheduleModel([course('A','[1]'),course('B','[1]'),course('C','[1]')],1)..init();
    expect(schedule.multiCourses.single.length,3);
    expect(schedule.activeCourses,isEmpty);
  });
  test('reinitializing the same schedule does not duplicate courses', () {
    final schedule=ScheduleModel([course('A','[1]'),course('B','[2]')],1)..init();
    schedule.init();
    expect(schedule.multiCourses.single.length,2);
    expect(schedule.hideCourses,isEmpty);
  });
}
