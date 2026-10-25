import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/core/widget_data/services/course_selector.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_course.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_schedule_data.dart';
import 'package:wheretosleepinnju/core/widget_data/models/school_time_template.dart';
import 'package:wheretosleepinnju/core/widget_data/exporters/unified_exporter.dart';

void main() {
  test('hidden-only overlapping courses never enter the widget', () {
    final courses = [
      Course(1, 'Next week A', '[2]', 1, 1, 0, 0),
      Course(1, 'Next week B', '[2]', 1, 1, 0, 0),
      Course(1, 'This week', '[1]', 2, 1, 0, 0),
      Course(1, 'Empty weeks', '[]', 2, 1, 0, 0),
    ];
    expect(selectWidgetCourses(courses, 1).map((c) => c.name), ['This week']);
    expect(selectWidgetCourses(courses, 1, day: 1), isEmpty);
    expect(selectWidgetCourses(courses, 2, day: 1), hasLength(2));
  });
  test('stored week advances at Monday, including backward date changes', () {
    expect(widgetWeekAt(DateTime(2026, 10, 25, 23, 59), 1, '2026-10-19'), 1);
    expect(widgetWeekAt(DateTime(2026, 10, 26), 1, '2026-10-19'), 2);
    expect(widgetWeekAt(DateTime(2026, 11, 2), 1, '2026-10-19'), 3);
    expect(widgetWeekAt(DateTime(2026, 10, 18), 1, '2026-10-19'), 0);
  });
  test('Sunday additions use this week while Monday preview uses the next', () {
    final sunday = DateTime(2026, 10, 25, 14);
    final week = widgetWeekAt(sunday, 6, '2026-10-19');
    final courses = [
      Course(1, 'Sunday added', '[6]', 7, 1, 0, 0),
      Course(1, 'Other Sunday', '[7]', 7, 1, 0, 0),
      Course(1, 'Next Monday', '[7]', 1, 1, 0, 0),
    ];
    expect(
      selectWidgetCourses(
        courses,
        week,
        day: sunday.weekday,
      ).map((c) => c.name),
      ['Sunday added'],
    );
    expect(selectWidgetCourses(courses, week + 1, day: 1).map((c) => c.name), [
      'Next Monday',
    ]);
  });
  test('large payload keeps Friday, all rows, semester data and settings', () {
    final courses = List.generate(
      30,
      (i) => WidgetCourse(
        id: '$i',
        name: 'Course $i',
        startPeriod: 1,
        periodCount: 1,
        weekDay: 5,
        schoolId: 'qa',
        weeks: [1, 2],
        notes: 'x' * 2000,
      ),
    );
    final data = WidgetScheduleData(
      timestamp: DateTime(2026, 10, 23),
      schoolId: 'qa',
      schoolName: 'QA',
      timeTemplate: SchoolTimeTemplate.nanjingUniversity,
      currentWeek: 1,
      currentWeekDay: 5,
      semesterName: 'QA',
      todayCourses: courses,
      tomorrowCourses: [],
      weekSchedule: {5: courses},
      semesterCourses: courses,
      weekCourseCount: 30,
      hasCoursesToday: true,
      hasCoursesTomorrow: false,
      totalCourses: 30,
      approachingMinutes: 30,
      tomorrowPreviewHour: 22,
    );
    final exported = UnifiedDataExporter.exportWidgetData(data);
    final encoded = jsonEncode(exported);
    expect(encoded.length, greaterThan(50 * 1024));
    final roundTrip = WidgetScheduleData.fromJson(data.toJson());
    expect(roundTrip.semesterCourses, hasLength(30));
    final payload = exported['data'] as Map<String, dynamic>;
    expect(payload['todayCourses'], hasLength(30));
    expect(payload['weekSchedule']['5'], hasLength(30));
    expect(payload['semesterCourses'], hasLength(30));
    expect(payload['tomorrowPreviewHour'], 22);
  });
}
