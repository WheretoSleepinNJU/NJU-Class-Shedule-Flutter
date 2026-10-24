import 'dart:convert';

import 'package:device_calendar_ohos/device_calendar_ohos.dart';

import '../Models/CourseModel.dart';

/// Builds every occurrence before writing, so invalid times cannot silently
/// produce a partially exported timetable with a success message.
class CalendarExporter {
  CalendarExporter({DeviceCalendarOhosPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarOhosPlugin();

  final DeviceCalendarOhosPlugin _plugin;

  static List<Event> buildEvents({
    required List<Course> courses,
    required List<Map> classTimes,
    required DateTime now,
    required int currentWeek,
  }) {
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1 + 7 * (currentWeek - 1)));
    final location = timeZoneDatabase.get('Asia/Shanghai');
    final events = <Event>[];
    for (final course in courses) {
      if (course.weekTime == 0) continue; // Courses without an assigned time.
      final day = course.weekTime;
      final first = (course.startTime ?? 0) - 1;
      final last = first + (course.timeCount ?? -1);
      if (day == null ||
          day < 1 ||
          day > 7 ||
          first < 0 ||
          last < first ||
          last >= classTimes.length) {
        throw const FormatException('Invalid course period');
      }
      final weeks = (jsonDecode(course.weeks ?? '[]') as List).cast<int>();
      for (final week in weeks.toSet()) {
        final date = monday.add(Duration(days: 7 * (week - 1) + day - 1));
        TZDateTime at(String value) {
          final parts = value.split(':').map(int.parse).toList();
          if (parts.length != 2 ||
              parts[0] < 0 ||
              parts[0] > 23 ||
              parts[1] < 0 ||
              parts[1] > 59) {
            throw const FormatException('Invalid class time');
          }
          return TZDateTime(
              location, date.year, date.month, date.day, parts[0], parts[1]);
        }

        final start = at(classTimes[first]['start'] as String);
        final end = at(classTimes[last]['end'] as String);
        if (!end.isAfter(start)) {
          throw const FormatException('Invalid course duration');
        }
        events.add(Event(null,
            title: course.name,
            start: start,
            end: end,
            location: course.classroom,
            description: course.info));
      }
    }
    return events;
  }

  /// Throws on denied permissions or any failed native write. The caller must
  /// only show success after this future completes.
  Future<void> export(String calendarName, List<Event> events) async {
    if (events.isEmpty) throw StateError('No scheduled courses to export');
    var permission = await _plugin.hasPermissions();
    if (!permission.isSuccess || permission.data != true) {
      permission = await _plugin.requestPermissions();
    }
    if (!permission.isSuccess || permission.data != true) {
      throw StateError('Calendar permission denied');
    }
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess) throw StateError('Cannot read calendars');
    String? calendarId;
    for (final calendar in calendars.data!) {
      if (calendar.name == calendarName &&
          calendar.isReadOnly != true &&
          calendar.id?.isNotEmpty == true) {
        calendarId = calendar.id;
        break;
      }
    }
    if (calendarId == null) {
      final created = await _plugin.createCalendar(calendarName,
          localAccountName: calendarName);
      if (!created.isSuccess) throw StateError('Cannot create calendar');
      calendarId = created.data;
    }
    for (final event in events) {
      event.calendarId = calendarId;
      final result = await _plugin.createOrUpdateEvent(event);
      if (result?.isSuccess != true) throw StateError('Cannot save event');
    }
  }
}
