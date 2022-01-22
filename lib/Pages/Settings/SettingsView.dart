import 'dart:io';
import '../../generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:share_extend/share_extend.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
import '../Import/ImportFromJWView.dart';
import '../Import/ImportFromCerView.dart';
import '../Import/ImportFromXKView.dart';
import '../AllCourse/AllCourseView.dart';
import '../Lecture/LecturesView.dart';
import '../About/AboutView.dart';
import '../AddCourse/AddCourseView.dart';
import 'MoreSettingsView.dart';
import '../Share/ShareView.dart';
import '../../Components/Toast.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';

import 'Widgets/WeekChanger.dart';
import 'Widgets/ThemeChanger.dart';

class SettingsView extends StatefulWidget {
  SettingsView() : super();

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
  }

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
                      builder: (BuildContext context) => AddView()));
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
                          builder: (BuildContext context) => ImportView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              //TODO: 全校课程
              ListTile(
                title: Text(S.of(context).all_course_title),
                subtitle: Text(S.of(context).all_course_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent(
                      "class_import", {"type": "all", "action": "show"});
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => AllCourseView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              ListTile(
                title: Text(S.of(context).view_lecture_title),
                subtitle: Text(S.of(context).view_lecture_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent(
                      "class_import", {"type": "lecture", "action": "show"});
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => LectureView()));
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
                      builder: (BuildContext context) => ShareView()));
                },
              ),
              ListTile(
                title: Text(S.of(context).manage_table_title),
                subtitle: Text(S.of(context).manage_table_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("schedule_manage", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => ManageTableView()));
                },
              ),
              // TODO: Refresh multi times when changing themes.
              ThemeChanger(),
              ListTile(
                title: Text(S.of(context).more_settings_title),
                subtitle: Text(S.of(context).more_settings_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("more_setting", {"action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => MoreSettingsView()));
                },
              ),
              WeekChanger(),
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
                  if (Platform.isIOS)
                    status = await _launchURL(Url.QQ_GROUP_APPLE_URL);
                  else if (Platform.isAndroid)
                    status = await _launchURL(Url.QQ_GROUP_ANDROID_URL);
                  if (!status)
                    Toast.showToast(S.of(context).QQ_open_fail_toast, context);
                },
                onLongPress: () async {
                  UmengCommonSdk.onEvent("group_add", {"action": "copy"});
                  if (Platform.isIOS)
                    await Clipboard.setData(
                        new ClipboardData(text: Config.IOS_GROUP));
                  else if (Platform.isAndroid)
                    await Clipboard.setData(
                        new ClipboardData(text: Config.ANDROID_GROUP));
                  Toast.showToast(S.of(context).QQ_copy_success_toast, context);
                },
              ),
              ListTile(
                  title: Text(S.of(context).donate_title),
                  subtitle: Text(S.of(context).donate_subtitle),
                  onTap: () async {
                    UmengCommonSdk.onEvent("donate_click", {"action": "show"});
                    bool status = false;
                    if (Platform.isIOS)
                      status = await _launchURL(Url.URL_APPLE);
                    else if (Platform.isAndroid)
                      status = await _launchURL(Url.URL_ANDROID);
                    if (!status)
                      Toast.showToast(
                          S.of(context).pay_open_fail_toast, context);
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
                  UmengCommonSdk.onEvent("about_click", { "action": "show"});
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => AboutView()));
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
}
