import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Utils/CalendarExporter.dart';
import 'package:wheretosleepinnju/Utils/IcsExporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CalendarExporter(); // Plugin initializes the timezone database, as in ShareView.
  final events = CalendarExporter.buildEvents(
    courses: [
      Course(
        1,
        '算法,进阶;\\专题\n中文😀',
        '[1,3,3]',
        7,
        1,
        1,
        0,
        classroom: '仙林101',
        info: '备注\r\n第二行',
      ),
      Course(1, '算法,进阶;\\专题\n中文😀', '[2]', 2, 2, 0, 0, classroom: '鼓楼202'),
      Course(1, '时间待定', '[1]', 0, 0, 0, 0),
    ],
    classTimes: [
      {'start': '08:00', 'end': '08:50'},
      {'start': '09:00', 'end': '09:50'},
    ],
    now: DateTime(2026, 10, 25),
    currentWeek: 1,
  );
  String export() => IcsExporter.encode(
    calendarName: '课表;甲',
    events: events,
    generatedAt: DateTime.utc(2026, 10, 25),
  );
  String unfold(String value) => value.replaceAll('\r\n ', '');
  test(
    'UTC, Sunday, non-consecutive weeks and separate meetings retain dates',
    () {
      final text = unfold(export());
      expect(text, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
      expect(text, endsWith('END:VCALENDAR\r\n'));
      expect('BEGIN:VEVENT'.allMatches(text), hasLength(3));
      expect(
        text,
        contains('DTSTART:20261025T000000Z\r\nDTEND:20261025T015000Z'),
      );
      expect(text, contains('DTSTART:20261108T000000Z'));
      expect(text, contains('DTSTART:20261027T010000Z'));
      expect(text, contains('LOCATION:仙林101'));
      expect(text, isNot(contains('时间待定')));
    },
  );
  test(
    'TEXT escapes punctuation, backslash and newlines without injecting fields',
    () {
      final text = unfold(export());
      expect(text, contains(r'SUMMARY:算法\,进阶\;\\专题\n中文😀'));
      expect(text, contains(r'DESCRIPTION:备注\n第二行'));
      expect(text, contains(r'X-WR-CALNAME:课表\;甲'));
    },
  );
  test('every physical line is valid UTF-8 and no longer than 75 octets', () {
    final text = export();
    for (final line in text.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      expect(utf8.decode(utf8.encode(line)), line);
    }
    expect(text.replaceAll('\r\n', ''), isNot(contains('\n')));
    expect(unfold(text), contains('中文😀'));
  });
  test('UIDs are unique and stable across repeated exports', () {
    final uids =
        RegExp(
          r'^UID:(.+)$',
          multiLine: true,
        ).allMatches(unfold(export())).map((m) => m[1]).toList();
    expect(uids, hasLength(3));
    expect(uids.toSet(), hasLength(3));
    expect(export(), export());
  });
  test('empty or invalid events fail before writing a file', () async {
    final folder = await Directory.systemTemp.createTemp('ics-test');
    try {
      await expectLater(
        IcsExporter.write(calendarName: 'empty', events: [], directory: folder),
        throwsStateError,
      );
      expect(await folder.list().toList(), isEmpty);
    } finally {
      await folder.delete(recursive: true);
    }
  });
  test('writes UTF-8 .ics with sanitized local filename', () async {
    final folder = await Directory.systemTemp.createTemp('ics-test');
    try {
      final file = await IcsExporter.write(
        calendarName: '../课表/😀',
        events: events,
        directory: folder,
      );
      expect(file.parent.path, folder.path);
      expect(file.path, endsWith('.ics'));
      expect(await file.readAsString(), contains('BEGIN:VCALENDAR'));
      expect(await folder.list().toList(), hasLength(1));
    } finally {
      await folder.delete(recursive: true);
    }
  });
}
