import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/CalendarExporter.dart';
import '../../Utils/States/MainState.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';

import 'QRShareView.dart';
import 'QRScanView.dart';
import 'qr_payload_codec.dart';

class ShareView extends StatefulWidget {
  const ShareView({Key? key}) : super(key: key);

  @override
  _ShareViewState createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).import_or_export_title),
        ),
        body: SafeArea(child: SingleChildScrollView(
            child: Column(children: <Widget>[
          SingleChildScrollView(
              child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
            ListTile(
              title: Text(S.of(context).export_classtable_title),
              subtitle: Text(S.of(context).export_classtable_subtitle),
              onTap: _exportClassTable,
            ),
            ListTile(
              title: Text(S.of(context).import_from_qrcode_title),
              subtitle: Text(S.of(context).import_from_qrcode_subtitle),
              onTap: _importFromQr,
            ),
            ListTile(
              title: Text(S.of(context).export_to_system_calendar_title),
              subtitle: Text(S.of(context).export_to_system_calendar_subtitle),
              onTap: () async {
                _exportToSystemCalendar(context);
              },
            ),
          ]).toList()))
        ]))));
  }

  Future<void> _exportClassTable() async {
    final int index =
        await ScopedModel.of<MainStateModel>(context).getClassTable();
    final CourseProvider courseProvider = CourseProvider();
    final List allCoursesMap = await courseProvider.getAllCourses(index);
    if (!mounted) return;
    if (allCoursesMap.isEmpty) {
      Toast.showToast(S.of(context).qrcode_empty_table_toast, context);
      return;
    }
    final CourseTableProvider courseTableProvider = CourseTableProvider();
    final CourseTable? courseTable =
        await courseTableProvider.getCourseTable(index);
    if (!mounted) return;
    if (courseTable == null) {
      Toast.showToast(S.of(context).qrcode_name_error_toast, context);
      return;
    }

    try {
      final payload = QrPayloadCodec.buildSchedulePayload(
        tableName: courseTable.name ?? '',
        tableData: courseTable.data ?? '',
        courseRows: List<Map<String, dynamic>>.from(
            allCoursesMap.map((e) => Map<String, dynamic>.from(e))),
      );
      final bundle = QrPayloadCodec.encodePayloadWithStats(payload);
      final encoded = bundle.encodedPayload;
      final frames = QrPayloadCodec.buildFramesFromEncodedPayload(encoded);
      final singleShareText =
          '$kNcsQrScheme://$kNcsQrHost/$kNcsQrVersion/s/$encoded';
      debugPrint(
        '[QR_EXPORT] courses=${allCoursesMap.length} jsonBytes=${bundle.jsonBytes} '
        'compressedBytes=${bundle.compressedBytes} base64Chars=${bundle.base64Chars} '
        'frames=${frames.length} partLimit=${QrPayloadCodec.defaultPartMaxLength}',
      );
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) =>
              QRShareView(frames: frames, singleShareText: singleShareText)));
    } catch (_) {
      Toast.showToast(S.of(context).qrcode_read_error_toast, context);
    }
  }

  Future<void> _importFromQr() async {
    final Map<String, dynamic>? payload = await Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) => const QRScanView()),
    );
    if (payload == null) {
      return;
    }

    Toast.showToast(S.of(context).importing_toast, context);

    final tableMap = Map<String, dynamic>.from(payload['table'] as Map);
    final courses = List<Map<String, dynamic>>.from(
      (payload['courses'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );

    final CourseTableProvider courseTableProvider = CourseTableProvider();
    int index;
    try {
      final CourseTable courseTable = await courseTableProvider.insert(
        CourseTable((tableMap['name'] ?? '').toString(),
            data: (tableMap['data'] ?? '').toString()),
      );
      index = courseTable.id!;
    } catch (_) {
      Toast.showToast(S.of(context).qrcode_name_error_toast, context);
      return;
    }

    final CourseProvider courseProvider = CourseProvider();
    await ScopedModel.of<MainStateModel>(context).changeclassTable(index);

    try {
      for (final coursePayload in courses) {
        final courseMap =
            QrPayloadCodec.payloadCourseToDbMap(coursePayload, tableId: index);
        final course = Course.fromMap(courseMap);
        await courseProvider.insert(course);
      }
    } catch (_) {
      Toast.showToast(S.of(context).qrcode_read_error_toast, context);
      return;
    }

    Toast.showToast(S.of(context).import_success_toast, context);
    UmengCommonSdk.onEvent("qr_import", {"action": "success"});
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  bool _exportingCalendar = false;

  Future<bool> _exportToSystemCalendar(BuildContext ctx) async {
    if (_exportingCalendar) return false;
    _exportingCalendar = true;
    try {
      final exporter = CalendarExporter();
      final model = MainStateModel.of(context);
      final tableId = await model.getClassTable();
      final currentWeek = await model.getWeek();
      final rows = await CourseProvider().getAllCourses(tableId);
      final tables = CourseTableProvider();
      final table = await tables.getCourseTable(tableId);
      final times = await tables.getClassTimeList(tableId);
      final events = CalendarExporter.buildEvents(
        courses: rows.map((row) => Course.fromMap(
            Map<String, dynamic>.from(row))).toList(),
        classTimes: times,
        now: DateTime.now(),
        currentWeek: currentWeek,
      );
      if (!mounted) return false;
      if (events.isEmpty) {
        Toast.showToast(S.of(ctx).qrcode_empty_table_toast, ctx);
        return false;
      }
      await exporter.export(table?.name ?? '南哪课表', events);
      if (mounted) {
        Toast.showToast(S.of(ctx).export_to_system_calendar_success_toast, ctx);
      }
      return true;
    } catch (error) {
      debugPrint('[CALENDAR_EXPORT] $error');
      if (mounted) {
        Toast.showToast(S.of(ctx).export_to_system_calendar_fail_toast, ctx);
      }
      return false;
    } finally {
      _exportingCalendar = false;
    }
  }
}
