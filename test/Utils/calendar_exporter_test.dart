import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_calendar_ohos/device_calendar_ohos.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Utils/CalendarExporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.builttoroam.com/device_calendar');
  final calls = <MethodCall>[];
  late CalendarExporter exporter;
  final times = [
    {'start': '08:00', 'end': '08:50'},
    {'start': '09:00', 'end': '09:50'}
  ];
  List<Event> events({int day = 7}) => CalendarExporter.buildEvents(courses: [
        Course(1, 'QA Calendar', '[1,3]', day, 1, 1, 0,
            classroom: '仙林教101', testLocation: '考试教室')
      ], classTimes: times, now: DateTime(2026, 10, 23), currentWeek: 1);
  setUp(() {
    exporter = CalendarExporter();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'hasPermissions':
          return true;
        case 'retrieveCalendars':
          return jsonEncode([
            {'id': 'readonly', 'name': 'QA', 'isReadOnly': true}
          ]);
        case 'createCalendar':
          return 'calendar';
        case 'createOrUpdateEvent':
          return 'event';
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  test('classroom, nonconsecutive weeks, Sunday and full period duration', () {
    final result = events();
    expect(result.map((e) => e.location), everyElement('仙林教101'));
    expect(
        result.first.start!.toIso8601String(), '2026-10-25T08:00:00.000+0800');
    expect(result.first.end!.hour, 9);
    expect(result.first.end!.minute, 50);
    expect(result.last.start!.day, 8);
    expect(result.last.start!.month, 11);
    expect(events(day: 1).first.start!.day, 19);
  });
  test('invalid periods fail instead of silently skipping courses', () {
    expect(
        () => CalendarExporter.buildEvents(
            courses: [Course(1, 'Bad period', '[1]', 1, 5, 0, 0)],
            classTimes: times,
            now: DateTime(2026, 10, 23),
            currentWeek: 1),
        throwsFormatException);
  });
  test('read-only calendar is skipped and every native event is checked',
      () async {
    await exporter.export('QA', events());
    expect(calls.where((c) => c.method == 'createCalendar'), hasLength(1));
    final writes = calls.where((c) => c.method == 'createOrUpdateEvent');
    expect(writes, hasLength(2));
    expect(writes.first.arguments['eventLocation'], '仙林教101');
  });
  test('native write error must not report success', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'hasPermissions') return true;
      if (call.method == 'retrieveCalendars') {
        return jsonEncode([
          {'id': 'calendar', 'name': 'QA', 'isReadOnly': false}
        ]);
      }
      throw PlatformException(code: '500', message: 'Write failed');
    });
    await expectLater(exporter.export('QA', events()), throwsStateError);
  });
  test('permission denial and empty schedule never write a calendar', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return false;
    });
    await expectLater(exporter.export('QA', events()), throwsStateError);
    expect(
        calls.map((c) => c.method), ['hasPermissions', 'requestPermissions']);
    calls.clear();
    await expectLater(exporter.export('QA', []), throwsStateError);
    expect(calls, isEmpty);
  });
}
