import 'dart:io';
import '../../generated/i18n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
import '../About/AboutView.dart';
import '../AddCourse/AddCourseView.dart';
import '../MoreSettings/MoreSettingsView.dart';
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
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => AddView()));
                },
              ),
              ListTile(
                title: Text(S.of(context).import_from_NJU_title),
                subtitle: Text(S.of(context).import_from_NJU_subtitle),
                onTap: () async {
                  bool status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => ImportView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              ListTile(
                title: Text(S.of(context).manage_table_title),
                subtitle: Text(S.of(context).manage_table_subtitle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => ManageTableView()));
                },
              ),
              // TODO: Refresh multi times when changing themes.
              ThemeChanger(),
              ListTile(
                title: Text('自定义选项'),
                subtitle: Text('课表样式设置，高级设置与试验功能'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => MoreSettingsView()));
                },
              ),
              WeekChanger(),
              ListTile(
                title: Text(S.of(context).report_title),
                subtitle: Text(S.of(context).report_subtitle),
                onTap: () async {
                  bool status = false;
                  if (Platform.isIOS)
                    status = await _launchURL(Url.QQ_GROUP_APPLE_URL);
                  else if (Platform.isAndroid)
                    status = await _launchURL(Url.QQ_GROUP_ANDROID_URL);
                  if (!status)
                    Toast.showToast(S.of(context).QQ_open_fail_toast, context);
                },
                onLongPress: () async {
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
                    bool status = false;
                    if (Platform.isIOS)
                      status = await _launchURL(Url.ALIPAY_URL_APPLE);
                    else if (Platform.isAndroid)
                      status = await _launchURL(Url.ALIPAY_URL_ANDROID);
                    if (!status)
                      Toast.showToast(
                          S.of(context).alipay_open_fail_toast, context);
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
                        return Text(snapshot.data);
                      }
                    }),
                onTap: () {
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
