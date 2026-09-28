import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Utils/IcsUtil.dart';

void main() {
  test('buildCourseScheduleIcs outputs VEVENTs with escaped fields', () {
    final ics = IcsUtil.buildCourseScheduleIcs(
      calendarName: '测试课表',
      courses: <Map<String, dynamic>>[
        <String, dynamic>{
          'name': '高等数学,A',
          'test_location': '仙林;教学楼',
          'info': '老师: 张三\n含换行',
          'weeks': '[1,2]',
          'week_time': 1,
          'start_time': 1,
          'time_count': 1,
        }
      ],
      classTimeList: <Map>[
        <String, String>{'start': '08:00', 'end': '08:50'},
        <String, String>{'start': '09:00', 'end': '09:50'},
      ],
      dayMap: <int, DateTime>{1: DateTime(2026, 2, 23)},
    );

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('X-WR-CALNAME:测试课表'));
    expect(RegExp(r'BEGIN:VEVENT').allMatches(ics).length, 2);
    expect(ics, contains('SUMMARY:高等数学\\,A'));
    expect(ics, contains('LOCATION:仙林\\;教学楼'));
    expect(ics, contains('DESCRIPTION:老师: 张三\\n含换行'));
    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20260302T080000'));
    expect(ics, contains('DTEND;TZID=Asia/Shanghai:20260302T090000'));
    expect(ics, contains('END:VCALENDAR'));
  });
}
