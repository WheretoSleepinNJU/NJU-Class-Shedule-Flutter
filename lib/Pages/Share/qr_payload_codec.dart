import 'dart:convert';
import 'package:archive/archive.dart';
import '../../Utils/CourseImportCodec.dart';

const String kNcsQrScheme = 'ncs';
const String kNcsQrHost = 'qr';
const String kNcsQrVersion = 'v2';
const Set<String> kNcsQrSupportedVersions = <String>{'v1', 'v2'};
const String kNcsQrAlgGzip = 'gz';
const String kNcsQrType = 'ncs_qr_schedule';
const int kNcsQrPayloadMaxChars = 20000;
const int kNcsQrMaxDecompressedBytes = 256 * 1024;

enum QrFrameKind { single, multi }

class ParsedQrFrame {
  final QrFrameKind kind;
  final String payload;
  final int? index;
  final int? total;
  final String? groupId;

  const ParsedQrFrame.single(this.payload)
      : kind = QrFrameKind.single,
        index = null,
        total = null,
        groupId = null;

  const ParsedQrFrame.multi({
    required this.index,
    required this.total,
    required this.groupId,
    required this.payload,
  }) : kind = QrFrameKind.multi;
}

class EncodedPayloadBundle {
  final String encodedPayload;
  final int jsonBytes;
  final int compressedBytes;
  final int base64Chars;

  const EncodedPayloadBundle({
    required this.encodedPayload,
    required this.jsonBytes,
    required this.compressedBytes,
    required this.base64Chars,
  });
}

class QrPayloadCodec {
  static const int defaultPartMaxLength = 1400;

  static Map<String, dynamic> buildSchedulePayload({
    required String tableName,
    required String tableData,
    required List<Map<String, dynamic>> courseRows,
  }) {
    final courses = courseRows.map(dbCourseToPayloadMap).toList();
    final dataForChecksum = <String, dynamic>{
      'table': <String, dynamic>{'name': tableName, 'data': tableData},
      'courses': courses,
    };
    final checksum = crc32HexOfString(jsonEncode(dataForChecksum));
    return <String, dynamic>{
      't': kNcsQrType,
      'v': 2,
      'alg': kNcsQrAlgGzip,
      'meta': <String, dynamic>{
        'app': 'wheretosleepinnju',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'source': 'local_sqlite',
        'checksum': checksum,
      },
      ...dataForChecksum,
    };
  }

  static String encodePayload(Map<String, dynamic> payload) {
    return encodePayloadWithStats(payload).encodedPayload;
  }

  static EncodedPayloadBundle encodePayloadWithStats(
      Map<String, dynamic> payload) {
    final rawBytes = utf8.encode(jsonEncode(payload));
    final compressed = GZipEncoder().encode(rawBytes);
    if (compressed == null) {
      throw const FormatException('gzip_encode_failed');
    }
    final encoded = base64UrlEncode(compressed);
    return EncodedPayloadBundle(
      encodedPayload: encoded,
      jsonBytes: rawBytes.length,
      compressedBytes: compressed.length,
      base64Chars: encoded.length,
    );
  }

  static Map<String, dynamic> decodeEncodedPayload(String encodedPayload) {
    if (encodedPayload.length > kNcsQrPayloadMaxChars) {
      throw const FormatException('payload_too_large');
    }
    late final List<int> compressed;
    try {
      compressed = base64Url.decode(encodedPayload);
    } catch (_) {
      throw const FormatException('base64_decode_failed');
    }
    late final List<int> decoded;
    try {
      decoded = GZipDecoder().decodeBytes(compressed);
    } catch (_) {
      throw const FormatException('gzip_decode_failed');
    }
    if (decoded.length > kNcsQrMaxDecompressedBytes) {
      throw const FormatException('decompressed_payload_too_large');
    }
    final obj = jsonDecode(utf8.decode(decoded));
    if (obj is! Map<String, dynamic>) {
      throw const FormatException('invalid_payload_shape');
    }
    _validateDecodedPayload(obj);
    return obj;
  }

  static bool isNcsQrPayload(String raw) {
    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return false;
    }
    if (uri.scheme != kNcsQrScheme || uri.host != kNcsQrHost) {
      return false;
    }
    final segments = uri.pathSegments;
    return segments.isNotEmpty && kNcsQrSupportedVersions.contains(segments[0]);
  }

  static ParsedQrFrame? parseFrame(String raw) {
    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return null;
    }

    if (uri.scheme != kNcsQrScheme || uri.host != kNcsQrHost) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length < 3 || !kNcsQrSupportedVersions.contains(segments[0])) {
      return null;
    }

    if (segments[1] == 's' && segments.length == 3) {
      return ParsedQrFrame.single(segments[2]);
    }

    if (segments[1] == 'm' && segments.length == 6) {
      final idx = int.tryParse(segments[2]);
      final total = int.tryParse(segments[3]);
      final groupId = segments[4];
      final payloadPart = segments[5];
      if (idx == null ||
          total == null ||
          groupId.isEmpty ||
          payloadPart.isEmpty) {
        return null;
      }
      return ParsedQrFrame.multi(
        index: idx,
        total: total,
        groupId: groupId,
        payload: payloadPart,
      );
    }

    return null;
  }

  static List<String> buildFramesFromEncodedPayload(
    String encodedPayload, {
    int maxPartLength = defaultPartMaxLength,
    String? groupId,
  }) {
    if (encodedPayload.length <= maxPartLength) {
      return <String>[
        '$kNcsQrScheme://$kNcsQrHost/$kNcsQrVersion/s/$encodedPayload'
      ];
    }

    final gid = groupId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final parts = <String>[];
    for (int i = 0; i < encodedPayload.length; i += maxPartLength) {
      final end = (i + maxPartLength < encodedPayload.length)
          ? i + maxPartLength
          : encodedPayload.length;
      parts.add(encodedPayload.substring(i, end));
    }

    final total = parts.length;
    return List<String>.generate(total, (int i) {
      final idx = i + 1;
      return '$kNcsQrScheme://$kNcsQrHost/$kNcsQrVersion/m/$idx/$total/$gid/${parts[i]}';
    });
  }

  static String? mergeEncodedPayloadParts(
    Map<int, String> parts,
    int total,
  ) {
    if (parts.length != total) {
      return null;
    }
    final buffer = StringBuffer();
    for (int i = 1; i <= total; i++) {
      final part = parts[i];
      if (part == null) {
        return null;
      }
      buffer.write(part);
    }
    return buffer.toString();
  }

  static String crc32Hex(List<int> bytes) {
    final crc = _crc32(bytes);
    return crc.toRadixString(16).padLeft(8, '0');
  }

  static String crc32HexOfString(String value) {
    return crc32Hex(utf8.encode(value));
  }

  static Map<String, dynamic> dbCourseToPayloadMap(Map<String, dynamic> row) {
    return CourseImportCodec.dbCourseToOnlineCourseMap(row);
  }

  static Map<String, dynamic> payloadCourseToDbMap(
    Map<String, dynamic> courseMap, {
    required int tableId,
  }) {
    return CourseImportCodec.onlineCourseToDbMap(courseMap, tableId: tableId);
  }

  static void _validateDecodedPayload(Map<String, dynamic> payload) {
    if (payload['t'] != kNcsQrType) {
      throw const FormatException('unsupported_payload_type');
    }
    if (payload['v'] != 1 && payload['v'] != 2) {
      throw const FormatException('unsupported_payload_version');
    }
    if (payload['alg'] != kNcsQrAlgGzip) {
      throw const FormatException('unsupported_payload_algorithm');
    }
    final table = payload['table'];
    final courses = payload['courses'];
    final meta = payload['meta'];
    if (table is! Map || courses is! List || meta is! Map) {
      throw const FormatException('invalid_payload_fields');
    }
    if ((table['name'] ?? '').toString().isEmpty) {
      throw const FormatException('missing_table_name');
    }
    final expected = crc32HexOfString(jsonEncode(<String, dynamic>{
      'table': <String, dynamic>{
        'name': (table['name'] ?? '').toString(),
        'data': (table['data'] ?? '').toString(),
      },
      'courses': List<Map<String, dynamic>>.from(
        courses.map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    }));
    if ((meta['checksum'] ?? '').toString() != expected) {
      throw const FormatException('checksum_mismatch');
    }
  }

  static int _crc32(List<int> bytes) {
    int crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      final index = (crc ^ byte) & 0xFF;
      crc = (_crc32Table[index] ^ (crc >> 8)) & 0xFFFFFFFF;
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

final List<int> _crc32Table = List<int>.generate(256, (int i) {
  int c = i;
  for (int j = 0; j < 8; j++) {
    if ((c & 1) != 0) {
      c = 0xEDB88320 ^ (c >> 1);
    } else {
      c = c >> 1;
    }
  }
  return c & 0xFFFFFFFF;
});
