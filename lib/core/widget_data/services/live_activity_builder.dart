import '../models/live_activity_data.dart';
import '../models/widget_course.dart';
import '../models/widget_schedule_data.dart';

/// Expand scheduled occurrences using the real semester weeks and school timetable.
/// The native receiver owns display windows and cancellation after persistence.
List<LiveActivityData> buildCourseLiveActivities(WidgetScheduleData data,
    {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final date =
      DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
  final monday =
      DateTime(date.year, date.month, date.day - data.currentWeekDay + 1);
  final courses = data.semesterCourses ??
      <WidgetCourse>[
        ...data.weekSchedule.values.expand((day) => day),
        ...data.todayCourses,
        ...data.tomorrowCourses,
      ];
  final result = <String, LiveActivityData>{};
  DateTime? at(DateTime day, String value) {
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.length != 2 || parts.any((part) => part == null)) {
      return null;
    }
    final hour = parts[0]!, minute = parts[1]!;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  for (final course in courses) {
    if (course.weekDay < 1 || course.weekDay > 7 || course.periodCount < 1) {
      continue;
    }
    final range = data.timeTemplate
        .getPeriodRange(course.startPeriod, course.periodCount);
    if (range == null) {
      continue;
    }
    for (final week in course.weeks.toSet()) {
      final day = DateTime(monday.year, monday.month,
          monday.day + (week - data.currentWeek) * 7 + course.weekDay - 1);
      final start = at(day, range.startTime), end = at(day, range.endTime);
      if (start == null ||
          end == null ||
          !end.isAfter(start) ||
          !start.isAfter(clock)) {
        continue;
      }
      final activity = LiveActivityData.fromCourse(
        course: course,
        trigger: LiveActivityTrigger.system,
        customStartTime: start,
        customEndTime: end,
        schoolName: data.schoolName,
        schoolId: data.schoolId,
        createdAt: clock,
      );
      result[activity.activityId] = activity;
    }
  }
  return result.values.toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
}
