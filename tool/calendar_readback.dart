// Read-only emulator diagnostic. Run with flutter run -t tool/calendar_readback.dart.
// Never writes calendars or requests permissions; uses previously granted access.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_calendar_ohos/device_calendar_ohos.dart';

void main() => runApp(const MaterialApp(home: CalendarReadback()));

class CalendarReadback extends StatefulWidget {
  const CalendarReadback({Key? key}) : super(key: key);
  @override
  State<CalendarReadback> createState() => _CalendarReadbackState();
}

class _CalendarReadbackState extends State<CalendarReadback> {
  late final Future<String> result = readBack();

  Future<String> readBack() async {
    final plugin = DeviceCalendarOhosPlugin();
    final access = await plugin.hasPermissions();
    if (access.data != true) return '尚未授予测试日历权限';
    final calendars = await plugin.retrieveCalendars();
    if (!calendars.isSuccess) throw StateError('读取日历失败');
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (final calendar in calendars.data!) {
      final events = await plugin.retrieveEvents(calendar.id, RetrieveEventsParams(
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 200)),
      ));
      if (!events.isSuccess) throw StateError('读取日程失败');
      for (final event in events.data!) {
        if (!(event.title ?? '').startsWith('QA-Calendar-')) continue;
        rows.add({'title': event.title, 'location': event.location,
          'start': event.start?.toIso8601String(), 'end': event.end?.toIso8601String(),
          'id': event.eventId});
      }
    }
    rows.sort((a, b) => (a['start'] as String).compareTo(b['start'] as String));
    final data = {'source': 'system calendar API readback', 'count': rows.length,
      'allLocationsCorrect': rows.isNotEmpty && rows.every((r) => r['location'] == 'QA-Room-101'),
      'events': rows};
    debugPrint('[QA_CALENDAR_READBACK] ${jsonEncode(data)}');
    return '系统日历读回（测试诊断）\n\n'
      '实际保存：${rows.length} 条 QA 课程\n'
      '地点全部正确：${data['allLocationsCorrect'] == true ? "通过" : "未通过"}\n\n'
      '${rows.take(3).map((r) => '${r['title']}\n${r['location']}\n${r['start']}\n${r['end']}').join('\n\n')}\n\n'
      '此页只读取系统 API；不创建或修改日程。';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QA · 日历持久化核验')),
    body: FutureBuilder<String>(future: result, builder: (context, snapshot) =>
      SingleChildScrollView(padding: const EdgeInsets.all(24), child: SelectableText(
        snapshot.hasError ? '核验失败：${snapshot.error}' : snapshot.data ?? '正在读回系统日历…',
        style: const TextStyle(fontSize: 19, height: 1.6),
      )),
    ),
  );
}
