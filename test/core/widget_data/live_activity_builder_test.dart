import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/core/widget_data/models/class_period.dart';
import 'package:wheretosleepinnju/core/widget_data/models/school_time_template.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_course.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_schedule_data.dart';
import 'package:wheretosleepinnju/core/widget_data/services/live_activity_builder.dart';

void main() {
  final course = WidgetCourse(
    id: 'math',
    name: '数学',
    startPeriod: 1,
    periodCount: 2,
    weekDay: 1,
    schoolId: 'legacy-table-name',
    weeks: [1, 2],
  );
  WidgetScheduleData data({List<WidgetCourse>? courses}) => WidgetScheduleData(
        timestamp: DateTime(2026, 10, 19, 7),
        schoolId: 'nju',
        schoolName: '南京大学',
        timeTemplate: SchoolTimeTemplate(
            schoolId: 'nju',
            schoolName: '南京大学',
            schoolNameEn: 'NJU',
            periods: [
              ClassPeriod(startTime: '08:00', endTime: '08:50'),
              ClassPeriod(startTime: '09:00', endTime: '09:50'),
            ]),
        currentWeek: 1,
        currentWeekDay: 1,
        semesterName: '2026',
        todayCourses: [course],
        tomorrowCourses: [],
        weekSchedule: {
          1: [course]
        },
        semesterCourses: courses ?? [course],
        weekCourseCount: 1,
        hasCoursesToday: true,
        hasCoursesTomorrow: false,
        totalCourses: 1,
      );

  test('expands real occurrence dates and multi-period end time', () {
    final activities =
        buildCourseLiveActivities(data(), now: DateTime(2026, 10, 19, 7));
    expect(activities.map((a) => a.startTime),
        [DateTime(2026, 10, 19, 8), DateTime(2026, 10, 26, 8)]);
    expect(activities.first.endTime, DateTime(2026, 10, 19, 9, 50));
    expect(activities.first.schoolId, 'nju');
  });
  test('repeated sends keep native-compatible occurrence identity', () {
    final first =
        buildCourseLiveActivities(data(), now: DateTime(2026, 10, 19, 7));
    final again =
        buildCourseLiveActivities(data(), now: DateTime(2026, 10, 19, 7, 1));
    expect(first.first.activityId, again.first.activityId);
    expect(first.first.activityId,
        'nju:math:${DateTime(2026, 10, 19, 8).millisecondsSinceEpoch}');
  });
  test('course start ends the reminder while next week remains scheduled', () {
    final activities =
        buildCourseLiveActivities(data(), now: DateTime(2026, 10, 19, 8));
    expect(activities.length, 1);
    expect(activities.single.startTime, DateTime(2026, 10, 26, 8));
  });
  test('empty weeks never generate recurring reminders', () {
    final unscheduled = WidgetCourse(
        id: 'empty',
        name: '未安排',
        startPeriod: 1,
        periodCount: 1,
        weekDay: 1,
        schoolId: 'nju',
        weeks: []);
    expect(
        buildCourseLiveActivities(data(courses: [unscheduled]),
            now: DateTime(2026, 10, 19, 7)),
        isEmpty);
  });
  test('invalid timetable rows do not produce fake fifty-minute classes', () {
    final invalid = WidgetCourse(
        id: 'invalid',
        name: '错误节次',
        startPeriod: 99,
        periodCount: 1,
        weekDay: 1,
        schoolId: 'nju',
        weeks: [1]);
    expect(
        buildCourseLiveActivities(data(courses: [invalid]),
            now: DateTime(2026, 10, 19, 7)),
        isEmpty);
  });
  test('duplicate semester rows generate one activity per occurrence', () {
    expect(
        buildCourseLiveActivities(data(courses: [course, course]),
                now: DateTime(2026, 10, 19, 7))
            .length,
        2);
  });
}
