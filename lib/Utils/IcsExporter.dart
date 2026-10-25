import 'dart:convert';
import 'dart:io';

import 'package:device_calendar_ohos/device_calendar_ohos.dart';
import 'package:path_provider/path_provider.dart';

/// RFC 5545: UTC dates, TEXT escaping, CRLF and UTF-8-safe 75-octet folding.
class IcsExporter {
  static String _text(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

  static String _date(DateTime date) {
    final utc = date.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}'
        '${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _fold(String line) {
    final result = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (bytes + size > 75) {
        result.write('\r\n ');
        bytes = 1;
      }
      result.write(char);
      bytes += size;
    }
    return result.toString();
  }

  static String encode({
    required String calendarName,
    required List<Event> events,
    DateTime? generatedAt,
  }) {
    if (events.isEmpty) throw StateError('No scheduled courses to export');
    final stamp = _date(generatedAt ?? DateTime.now());
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//idealclover//NJU Schedule//ZH-CN',
      'CALSCALE:GREGORIAN',
      'X-WR-CALNAME:${_text(calendarName)}',
    ];
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (event.start == null ||
          event.end == null ||
          !event.end!.isAfter(event.start!)) {
        throw const FormatException('Invalid event time');
      }
      // Stable per-occurrence identity, including non-consecutive weeks and
      // multiple meetings; repeated exports keep the same identifiers.
      final identity = base64Url
          .encode(
            utf8.encode(
              jsonEncode([
                calendarName,
                event.title,
                event.start!.toUtc().toIso8601String(),
                event.end!.toUtc().toIso8601String(),
                event.location,
                i,
              ]),
            ),
          )
          .replaceAll('=', '');
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:$identity@nju-schedule.idealclover',
        'DTSTAMP:$stamp',
        'DTSTART:${_date(event.start!)}',
        'DTEND:${_date(event.end!)}',
        'SUMMARY:${_text(event.title ?? '')}',
        if (event.location?.isNotEmpty == true)
          'LOCATION:${_text(event.location!)}',
        if (event.description?.isNotEmpty == true)
          'DESCRIPTION:${_text(event.description!)}',
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static Future<File> write({
    required String calendarName,
    required List<Event> events,
    Directory? directory,
  }) async {
    // Build and validate before creating a file; never hand out partial exports.
    final content = encode(calendarName: calendarName, events: events);
    final folder = directory ?? await getTemporaryDirectory();
    await folder.create(recursive: true);
    var name =
        calendarName.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    if (name.isEmpty) name = '南哪课表';
    name = String.fromCharCodes(name.runes.take(60));
    final file = File('${folder.path}/$name.ics');
    await file.writeAsString(content, encoding: utf8, flush: true);
    return file;
  }
}
