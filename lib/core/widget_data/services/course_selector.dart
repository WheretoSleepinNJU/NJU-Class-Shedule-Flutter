import 'dart:convert';
import '../../../Models/CourseModel.dart';

/// Select from the source timetable, before UI overlap groups mix active and
/// hidden courses. Empty weeks mean no scheduled occurrence.
List<Course> selectWidgetCourses(List<Course> courses, int week, {int? day}) {
  final selected = courses.where((course) {
    final weekday = course.weekTime ?? 0;
    if (weekday < 1 || weekday > 7 || (day != null && weekday != day)) {
      return false;
    }
    final weeks = jsonDecode(course.weeks ?? '[]') as List;
    return weeks.contains(week);
  }).toList();
  selected.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
  return selected;
}

int widgetWeekAt(DateTime now, int storedWeek, String? storedMonday) {
  final anchor = DateTime.tryParse(storedMonday ?? '');
  if (anchor == null) return storedWeek;
  final date = DateTime.utc(now.year, now.month, now.day);
  final monday = date.subtract(Duration(days: now.weekday - 1));
  final source = DateTime.utc(anchor.year, anchor.month, anchor.day);
  return storedWeek + monday.difference(source).inDays ~/ 7;
}
