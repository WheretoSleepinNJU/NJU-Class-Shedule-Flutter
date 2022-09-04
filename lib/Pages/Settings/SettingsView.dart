import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../../generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:share_extend/share_extend.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart';
import 'package:scoped_model/scoped_model.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
// import '../AllCourse/AllCourseView.dart';
import '../Lecture/LecturesView.dart';
import '../About/AboutView.dart';
import '../AddCourse/AddCourseView.dart';
import 'MoreSettingsView.dart';
import '../Share/ShareView.dart';
import '../../Components/Toast.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseModel.dart';


import 'Widgets/WeekChanger.dart';
import 'Widgets/ThemeChanger.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
  }

  Map<int,DateTime> timeMap={
    1 :DateTime(2022,1,1,8,0),
    2 :DateTime(2022,1,1,9,0),
    3 :DateTime(2022,1,1,10,10),
    4 :DateTime(2022,1,1,11,10),
    5 :DateTime(2022,1,1,14,0),
    6 :DateTime(2022,1,1,15,0),
    7 :DateTime(2022,1,1,16,10),
    8 :DateTime(2022,1,1,17,10),
    9 :DateTime(2022,1,1,18,30),
    10:DateTime(2022,1,1,19,30),
    11:DateTime(2022,1,1,20,30),
    12:DateTime(2022,1,1,21,30),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).settings_title),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            SingleChildScrollView(
                child: Column(
                    children: ListTile.divideTiles(context: context, tiles: [
              ListTile(
                title: Text(S.of(context).import_manually_title),
                subtitle: Text(S.of(context).import_manually_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent(
                      "class_import", {"type": "manual", "action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const AddView()));
                },
              ),
              ListTile(
                title: Text(S.of(context).import_title),
                subtitle: Text(S.of(context).import_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent(
                      "class_import", {"type": "auto", "action": "show"});
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const ImportView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              //TODO: 全校课程
              // ListTile(
              //   title: Text(S.of(context).all_course_title),
              //   subtitle: Text(S.of(context).all_course_subtitle),
              //   onTap: () async {
              //     UmengCommonSdk.onEvent(
              //         "class_import", {"type": "all", "action": "show"});
              //     bool? status = await Navigator.of(context).push(
              //         MaterialPageRoute(
              //             builder: (BuildContext context) => const AllCourseView()));
              //     if (status == true) Navigator.of(context).pop(status);
              //   },
              // ),
              ListTile(
                title: Text(S.of(context).view_lecture_title),
                subtitle: Text(S.of(context).view_lecture_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent(
                      "class_import", {"type": "lecture", "action": "show"});
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const LectureView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              // ListTile(
              //   title: Text(S.of(context).import_from_NJU_title),
              //   subtitle: Text(S.of(context).import_from_NJU_subtitle),
              //   onTap: () async {
              //     bool status = await Navigator.of(context).push(
              //         MaterialPageRoute(
              //             builder: (BuildContext context) => ImportView()));
              //     if (status == true) Navigator.of(context).pop(status);
              //   },
              // ),
              // ListTile(
              //   title: Text(S.of(context).import_from_NJU_cer_title),
              //   subtitle: Text(S.of(context).import_from_NJU_cer_subtitle),
              //   onTap: () async {
              //     bool status = await Navigator.of(context).push(
              //         MaterialPageRoute(
              //             builder: (BuildContext context) =>
              //                 ImportFromWebView()));
              //     if (status == true) Navigator.of(context).pop(status);
              //   },
              // ),
              // ListTile(
              //   title: Text(S.of(context).import_from_NJU_xk_title),
              //   subtitle: Text(S.of(context).import_from_NJU_xk_subtitle),
              //   onTap: () async {
              //     bool? status = await Navigator.of(context).push(
              //         MaterialPageRoute(
              //             builder: (BuildContext context) =>
              //                 ImportFromXKView()));
              //     if (status == true) Navigator.of(context).pop(status);
              //   },
              // ),
              // ---
              ListTile(
                title: Text(S.of(context).import_or_export_title),
                subtitle: Text(S.of(context).import_or_export_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("qr_import", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const ShareView()));
                },
              ),
              ListTile(
                title: Text(S.of(context).manage_table_title),
                subtitle: Text(S.of(context).manage_table_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("schedule_manage", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const ManageTableView()));
                },
              ),
              ListTile(
                title: Text(S.of(context).export_to_system_calendar),
                subtitle: Text(S.of(context).make_sure_week_num_correct),
                onTap: () async{
                  exportToSystemCalendar(context);
                },
              ),
              // TODO: Refresh multi times when changing themes.
              const ThemeChanger(),
              ListTile(
                title: Text(S.of(context).more_settings_title),
                subtitle: Text(S.of(context).more_settings_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("more_setting", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const MoreSettingsView()));
                },
              ),
              const WeekChanger(),
              ListTile(
                title: Text(S.of(context).share_title),
                subtitle: Text(S.of(context).share_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("app_share", {"action": "show"});
                  ShareExtend.share(S.of(context).share_content, "text");
                },
              ),
              ListTile(
                title: Text(S.of(context).report_title),
                subtitle: Text(S.of(context).report_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent("group_add", {"action": "show"});
                  bool status = false;
                  if (Platform.isIOS) {
                    status = await _launchURL(Url.QQ_GROUP_APPLE_URL);
                  } else if (Platform.isAndroid) {
                    status = await _launchURL(Url.QQ_GROUP_ANDROID_URL);
                  }
                  if (!status) {
                    Toast.showToast(S.of(context).QQ_open_fail_toast, context);
                  }
                },
                onLongPress: () async {
                  UmengCommonSdk.onEvent("group_add", {"action": "copy"});
                  if (Platform.isIOS) {
                    await Clipboard.setData(
                        const ClipboardData(text: Config.IOS_GROUP));
                  } else if (Platform.isAndroid) {
                    await Clipboard.setData(
                        const ClipboardData(text: Config.ANDROID_GROUP));
                  }
                  Toast.showToast(S.of(context).QQ_copy_success_toast, context);
                },
              ),
              ListTile(
                  title: Text(S.of(context).donate_title),
                  subtitle: Text(S.of(context).donate_subtitle),
                  onTap: () async {
                    UmengCommonSdk.onEvent("donate_click", {"action": "show"});
                    bool status = false;
                    if (Platform.isIOS) {
                      status = await _launchURL(Url.URL_APPLE);
                    } else if (Platform.isAndroid) {
                      status = await _launchURL(Url.URL_ANDROID);
                    }
                    if (!status) {
                      Toast.showToast(
                          S.of(context).pay_open_fail_toast, context);
                    }
                  }),
              ListTile(
                title: Text(S.of(context).about_title),
                subtitle: FutureBuilder<String>(
                    future: _getVersion(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      } else {
                        return Text(snapshot.data!);
                      }
                    }),
                onTap: () {
                  UmengCommonSdk.onEvent("about_click", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const AboutView()));
                },
              )
            ]).toList())),
          ],
        )));
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version + S.of(context).flutter_lts;
  }

  Future<bool> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
      return true;
    } else {
      return false;
    }
  }
  Future<bool> exportToSystemCalendar(BuildContext ctx) async {
    int tableId=await MainStateModel.of(context).getClassTable();
    CourseProvider cp=CourseProvider();
    List courses=await cp.getAllCourses(tableId);

    Map<int,DateTime> dayMap=await getDayMap();
    Duration courseLength=Duration(minutes: 50);
    DeviceCalendarPlugin dc=DeviceCalendarPlugin();
    const String CALENDAR_NAME="南哪课表";
    for (Map<String, dynamic> courseMap in courses) {
        Course course=Course.fromMap(courseMap);
        for(int week_num in json.decode(course.weeks!)){
          DateTime day=dayMap[course.weekTime]!.add(Duration(days: 7)*week_num);
          DateTime startTime=timeMap[course.startTime]!;
          DateTime endTime=timeMap[course.startTime!+course.timeCount!+1]!;

          String timezone='Asia/Shanghai';
          Location loc=timeZoneDatabase.get(timezone);

          TZDateTime start=TZDateTime(loc,day.year,day.month,day.day,startTime.hour,startTime.minute);
          TZDateTime end=TZDateTime(loc,day.year,day.month,day.day,endTime.hour,endTime.minute);

          UnmodifiableListView calendars=(await dc.retrieveCalendars()).data!;
          String? targetCalendarId;
          bool found=false;
          for(Calendar c in calendars){
            if(c.name==CALENDAR_NAME){
              targetCalendarId=c.id!;
              found=true;
              break;
            }
          }
          if(found==false){
            targetCalendarId=(await dc.createCalendar(CALENDAR_NAME)).data!;
          }
          String? result=(await dc.createOrUpdateEvent(Event(
            targetCalendarId!,
            title: course.name,
            start: start,
            end: end,
            location: course.testLocation,
            description: course.info,
          )))?.data;
        }
      }
    return true;
  }
  Future<Map<int,DateTime>> getDayMap() async{
    //获取开学第一周的周一到周日的日期
    //时间是调用此函数时的时间，没有意义，不应被使用
    Map<int,DateTime> dayMap={};
    DateTime now=DateTime.now();
    int weekNum=await ScopedModel.of<MainStateModel>(context).getWeek();
    Duration backaweek=Duration(days: -7);
    Duration backaday=Duration(days: -1);
    DateTime firstDay=now.add(backaweek*weekNum+backaday*now.weekday);
    for(int i=0;i<7;i++){
      Duration delta=Duration(days: i);
      DateTime target=firstDay.add(delta);
      dayMap[target.weekday]=target;
    }
    return dayMap;
  }
}




