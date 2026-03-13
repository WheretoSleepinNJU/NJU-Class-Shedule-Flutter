import 'dart:collection';
import 'dart:convert';

import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
// import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar_ohos/device_calendar_ohos.dart';
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
        body: SingleChildScrollView(
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
        ])));
  }

  Future<void> _exportClassTable() async {
    final int index =
        await ScopedModel.of<MainStateModel>(context).getClassTable();
    final CourseProvider courseProvider = CourseProvider();
    final List allCoursesMap = await courseProvider.getAllCourses(index);
    final CourseTableProvider courseTableProvider = CourseTableProvider();
    final CourseTable? courseTable =
        await courseTableProvider.getCourseTable(index);
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

  Future<bool> _exportToSystemCalendar(BuildContext ctx) async {
    // DeviceCalendarPlugin dc = DeviceCalendarPlugin();
    DeviceCalendarOhosPlugin dc = DeviceCalendarOhosPlugin();


    var permissionsGranted = await dc.hasPermissions();

    if (permissionsGranted.data == null || permissionsGranted.data == false) {
      permissionsGranted = await dc.requestPermissions();
      if (!permissionsGranted.isSuccess ||
          permissionsGranted.data == null ||
          permissionsGranted.data == false) {
        Toast.showToast(S.of(ctx).export_to_system_calendar_fail_toast, ctx);
        return false;
      }
    }

    int tableId = await MainStateModel.of(context).getClassTable();
    CourseProvider cp = CourseProvider();
    List courses = await cp.getAllCourses(tableId);

    CourseTableProvider courseTableProvider = CourseTableProvider();
    CourseTable? courseTable =
        await courseTableProvider.getCourseTable(tableId);
    String calendarName = courseTable?.name ?? "南哪课表";

    List<Map> classTimeList =
        await courseTableProvider.getClassTimeList(tableId);

    Map<int, DateTime> dayMap = await _getDayMap();

    String? targetCalendarId;
    try {
      UnmodifiableListView calendars = (await dc.retrieveCalendars()).data!;
      for (Calendar c in calendars) {
        if (c.name == calendarName) {
          targetCalendarId = c.id!;
          break;
        }
      }
      targetCalendarId ??= (await dc.createCalendar(calendarName)).data;
    } catch (e) {
      Toast.showToast(
          S.of(context).export_to_system_calendar_fail_toast, context);
      return false;
    }

    if (targetCalendarId == null) {
      Toast.showToast(
          S.of(context).export_to_system_calendar_fail_toast, context);
      return false;
    }

    try {
      for (Map<String, dynamic> courseMap in courses) {
        Course course = Course.fromMap(courseMap);
        if (course.weekTime == 0) {
          continue;
        }
        for (int week_num in json.decode(course.weeks!)) {
          DateTime day =
              dayMap[course.weekTime]!.add(Duration(days: 7) * week_num);

          int startIndex = course.startTime! - 1;
          int endIndex = startIndex + course.timeCount!;
          if (startIndex < 0 ||
              startIndex >= classTimeList.length ||
              endIndex < 0 ||
              endIndex >= classTimeList.length) {
            continue;
          }

          String startTimeStr = classTimeList[startIndex]["start"];
          String endTimeStr = classTimeList[endIndex]["end"];

          List<String> startParts = startTimeStr.split(":");
          List<String> endParts = endTimeStr.split(":");

          int startHour = int.parse(startParts[0]);
          int startMinute = int.parse(startParts[1]);
          int endHour = int.parse(endParts[0]);
          int endMinute = int.parse(endParts[1]);

          String timezone = 'Asia/Shanghai';
          Location loc = timeZoneDatabase.get(timezone);

          TZDateTime start = TZDateTime(
              loc, day.year, day.month, day.day, startHour, startMinute);
          TZDateTime end =
              TZDateTime(loc, day.year, day.month, day.day, endHour, endMinute);

          await dc.createOrUpdateEvent(Event(
            targetCalendarId,
            title: course.name,
            start: start,
            end: end,
            location: course.testLocation,
            description: course.info,
          ));
        }
      }
      Toast.showToast(
          S.of(context).export_to_system_calendar_success_toast, context);
    } catch (e) {
      Toast.showToast(
          S.of(context).export_to_system_calendar_fail_toast, context);
    }
    return true;
  }

  Future<Map<int, DateTime>> _getDayMap() async {
    Map<int, DateTime> dayMap = {};
    DateTime now = DateTime.now();
    int weekNum = await ScopedModel.of<MainStateModel>(context).getWeek();
    Duration backaweek = const Duration(days: -7);
    Duration backaday = const Duration(days: -1);
    DateTime firstDay = now.add(backaweek * weekNum + backaday * now.weekday);
    for (int i = 0; i < 7; i++) {
      Duration delta = Duration(days: i);
      DateTime target = firstDay.add(delta);
      dayMap[target.weekday] = target;
    }
    return dayMap;
  }
}
