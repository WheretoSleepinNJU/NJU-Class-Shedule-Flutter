import '../../AdaptiveUI/adaptive_ui.dart';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/CalendarExporter.dart';
import '../../Utils/IcsExporter.dart';
import 'package:share_extend/share_extend.dart';
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
    final s = S.of(context);
    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(title: Text(s.import_or_export_title)),
      body: SafeArea(
        child: AdaptivePageList(
          children: [
            AdaptiveSection(
              title: Text(s.import_settings_title),
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: Text(s.import_from_qrcode_title),
                  subtitle: Text(s.import_from_qrcode_subtitle),
                  onTap: _importFromQr,
                ),
              ],
            ),
            AdaptiveSection(
              title: Text(s.export_title),
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.qr_code_rounded),
                  title: Text(s.export_classtable_title),
                  subtitle: Text(s.export_classtable_subtitle),
                  onTap: _exportClassTable,
                ),
                AdaptiveListTile(
                  key: const ValueKey('export-ics'),
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(s.export_ics_title),
                  subtitle: Text(s.export_ics_subtitle),
                  enabled: !_exportingCalendar,
                  trailing: _exportingCalendar
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: AdaptiveProgressIndicator(),
                        )
                      : null,
                  onTap: _exportingCalendar
                      ? null
                      : () => _exportToSystemCalendar(context, asFile: true),
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(s.export_to_system_calendar_title),
                  subtitle: Text(s.export_to_system_calendar_subtitle),
                  onTap: () => _exportToSystemCalendar(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportClassTable() async {
    final int index = await ScopedModel.of<MainStateModel>(
      context,
    ).getClassTable();
    final CourseProvider courseProvider = CourseProvider();
    final List allCoursesMap = await courseProvider.getAllCourses(index);
    if (!mounted) return;
    if (allCoursesMap.isEmpty) {
      Toast.showToast(S.of(context).qrcode_empty_table_toast, context);
      return;
    }
    final CourseTableProvider courseTableProvider = CourseTableProvider();
    final CourseTable? courseTable = await courseTableProvider.getCourseTable(
      index,
    );
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
          allCoursesMap.map((e) => Map<String, dynamic>.from(e)),
        ),
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              QRShareView(frames: frames, singleShareText: singleShareText),
        ),
      );
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
      (payload['courses'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    final CourseTableProvider courseTableProvider = CourseTableProvider();
    int index;
    try {
      final CourseTable courseTable = await courseTableProvider.insert(
        CourseTable(
          (tableMap['name'] ?? '').toString(),
          data: (tableMap['data'] ?? '').toString(),
        ),
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
        final courseMap = QrPayloadCodec.payloadCourseToDbMap(
          coursePayload,
          tableId: index,
        );
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

  Future<bool> _exportToSystemCalendar(
    BuildContext ctx, {
    bool asFile = false,
  }) async {
    if (_exportingCalendar) return false;
    setState(() => _exportingCalendar = true);
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
        courses: rows
            .map((row) => Course.fromMap(Map<String, dynamic>.from(row)))
            .toList(),
        classTimes: times,
        now: DateTime.now(),
        currentWeek: currentWeek,
      );
      if (!mounted) return false;
      if (events.isEmpty) {
        Toast.showToast(S.of(ctx).qrcode_empty_table_toast, ctx);
        return false;
      }
      final name = table?.name ?? '南哪课表';
      if (asFile) {
        final file = await IcsExporter.write(
          calendarName: name,
          events: events,
        );
        if (!mounted) return false;
        final size = MediaQuery.sizeOf(context);
        await ShareExtend.share(
          file.path,
          'file',
          subject: name,
          sharePositionOrigin: Rect.fromLTWH(
            size.width / 2,
            size.height / 2,
            1,
            1,
          ),
        );
      } else {
        await exporter.export(name, events);
        if (mounted) {
          Toast.showToast(
            S.of(ctx).export_to_system_calendar_success_toast,
            ctx,
          );
        }
      }
      return true;
    } catch (error) {
      debugPrint('[CALENDAR_EXPORT] $error');
      if (mounted) {
        Toast.showToast(
          asFile
              ? S.of(ctx).export_ics_fail
              : S.of(ctx).export_to_system_calendar_fail_toast,
          ctx,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _exportingCalendar = false);
    }
  }
}
