import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/Share/qr_payload_codec.dart';

void main() {
  Map<String, dynamic> samplePayload() {
    return QrPayloadCodec.buildSchedulePayload(
      tableName: '测试课表',
      tableData: '{"semester_start_monday":"2026-02-23"}',
      courseRows: <Map<String, dynamic>>[
        <String, dynamic>{
          'name': '离散数学',
          'classroom': '仙II-201',
          'class_number': 'A01',
          'teacher': '张三',
          'test_time': '',
          'test_location': '',
          'link': '',
          'info': '',
          'weeks': '[1,2,3,4]',
          'week_time': 1,
          'start_time': 1,
          'time_count': 2,
          'import_type': 1,
          'course_id': 123,
        }
      ],
    );
  }

  test('single frame encode/decode works', () {
    final payload = samplePayload();
    final encoded = QrPayloadCodec.encodePayload(payload);
    final frames = QrPayloadCodec.buildFramesFromEncodedPayload(encoded, maxPartLength: 4096);

    expect(frames.length, 1);

    final parsed = QrPayloadCodec.parseFrame(frames.first);
    expect(parsed, isNotNull);
    expect(parsed!.kind, QrFrameKind.single);

    final decoded = QrPayloadCodec.decodeEncodedPayload(parsed.payload);
    expect(decoded['t'], kNcsQrType);
    expect(decoded['v'], 2);
    expect(decoded['alg'], kNcsQrAlgGzip);
  });

  test('multi frame split/merge works', () {
    final payload = samplePayload();
    final encoded = QrPayloadCodec.encodePayload(payload);
    final frames = QrPayloadCodec.buildFramesFromEncodedPayload(encoded, maxPartLength: 24);

    expect(frames.length, greaterThan(1));

    final parts = <int, String>{};
    int? total;
    for (final frame in frames) {
      final parsed = QrPayloadCodec.parseFrame(frame)!;
      expect(parsed.kind, QrFrameKind.multi);
      total ??= parsed.total;
      parts[parsed.index!] = parsed.payload;
    }

    final merged = QrPayloadCodec.mergeEncodedPayloadParts(parts, total!);
    expect(merged, isNotNull);

    final decoded = QrPayloadCodec.decodeEncodedPayload(merged!);
    expect((decoded['courses'] as List).length, 1);
  });

  test('checksum mismatch is rejected', () {
    final payload = samplePayload();
    final encoded = QrPayloadCodec.encodePayload(payload);
    final decoded = QrPayloadCodec.decodeEncodedPayload(encoded);

    final courses = (decoded['courses'] as List).cast<Map<String, dynamic>>();
    courses.first['name'] = '被篡改课程';

    final tamperedEncoded = QrPayloadCodec.encodePayload(decoded);
    expect(() => QrPayloadCodec.decodeEncodedPayload(tamperedEncoded), throwsFormatException);
  });

  test('invalid encoded payload is rejected', () {
    expect(() => QrPayloadCodec.decodeEncodedPayload(base64UrlEncode(utf8.encode('{"a":1}'))),
        throwsA(isA<FormatException>()));
  });

  test('v1 frame remains parseable', () {
    const raw = 'ncs://qr/v1/s/abc123';
    final parsed = QrPayloadCodec.parseFrame(raw);
    expect(parsed, isNotNull);
    expect(parsed!.kind, QrFrameKind.single);
    expect(parsed.payload, 'abc123');
  });
}
