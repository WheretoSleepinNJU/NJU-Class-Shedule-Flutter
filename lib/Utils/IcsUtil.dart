class IcsUtil {
  static String buildCourseScheduleIcs({
    required String calendarName,
    required List<Map<String, dynamic>> courses,
    required List<Map> classTimeList,
    required Map<int, DateTime> dayMap,
    String timezone = 'Asia/Shanghai',
  }) {
    final nowUtc = DateTime.now().toUtc();
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//WheretoSleepinNJU//Class Schedule//CN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:${_escapeText(calendarName)}')
      ..writeln('X-WR-TIMEZONE:$timezone');

    int eventIndex = 0;
    for (final courseMap in courses) {
      final int? weekTime = courseMap['week_time'] as int?;
      final int? startTime = courseMap['start_time'] as int?;
      final int? timeCount = courseMap['time_count'] as int?;
      final dynamic weeksRaw = courseMap['weeks'];
      if (weekTime == null ||
          startTime == null ||
          timeCount == null ||
          weekTime == 0 ||
          weeksRaw == null) {
        continue;
      }

      final List<int> weeks = _parseWeeks(weeksRaw.toString());
      if (weeks.isEmpty || !dayMap.containsKey(weekTime)) {
        continue;
      }

      final int startIndex = startTime - 1;
      final int endIndex = startIndex + timeCount;
      if (startIndex < 0 ||
          endIndex < 0 ||
          startIndex >= classTimeList.length ||
          endIndex >= classTimeList.length) {
        continue;
      }

      final List<String> startParts =
          classTimeList[startIndex]['start'].toString().split(':');
      final List<String> endParts =
          classTimeList[endIndex]['end'].toString().split(':');
      if (startParts.length != 2 || endParts.length != 2) {
        continue;
      }

      final int? startHour = int.tryParse(startParts[0]);
      final int? startMinute = int.tryParse(startParts[1]);
      final int? endHour = int.tryParse(endParts[0]);
      final int? endMinute = int.tryParse(endParts[1]);
      if (startHour == null ||
          startMinute == null ||
          endHour == null ||
          endMinute == null) {
        continue;
      }

      final String title = _escapeText((courseMap['name'] ?? '课程').toString());
      final String location =
          _escapeText((courseMap['test_location'] ?? '').toString());
      final String description = _escapeText((courseMap['info'] ?? '').toString());

      for (final int weekNum in weeks) {
        final DateTime day = dayMap[weekTime]!.add(Duration(days: 7) * weekNum);
        final DateTime start =
            DateTime(day.year, day.month, day.day, startHour, startMinute);
        final DateTime end = DateTime(day.year, day.month, day.day, endHour, endMinute);
        final uidSeed = '$eventIndex-$title-$weekNum-${start.millisecondsSinceEpoch}';
        buffer
          ..writeln('BEGIN:VEVENT')
          ..writeln('UID:${uidSeed.hashCode}@wheretosleepinnju')
          ..writeln('DTSTAMP:${_formatUtcDateTime(nowUtc)}')
          ..writeln('SUMMARY:$title')
          ..writeln('DTSTART;TZID=$timezone:${_formatLocalDateTime(start)}')
          ..writeln('DTEND;TZID=$timezone:${_formatLocalDateTime(end)}');
        if (location.isNotEmpty) {
          buffer.writeln('LOCATION:$location');
        }
        if (description.isNotEmpty) {
          buffer.writeln('DESCRIPTION:$description');
        }
        buffer.writeln('END:VEVENT');
        eventIndex++;
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static List<int> _parseWeeks(String weeksRaw) {
    final matches = RegExp(r'\d+').allMatches(weeksRaw);
    return matches
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList();
  }

  static String _escapeText(String text) {
    return text
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n');
  }

  static String _formatLocalDateTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${pad(dt.month)}${pad(dt.day)}T${pad(dt.hour)}${pad(dt.minute)}00';
  }

  static String _formatUtcDateTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${pad(dt.month)}${pad(dt.day)}T${pad(dt.hour)}${pad(dt.minute)}${pad(dt.second)}Z';
  }
}
