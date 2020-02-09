import 'dart:io';
import '../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:package_info/package_info.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'CourseTable/CourseTableView.dart';
import '../Components/Dialog.dart';
//import '../Resources/Url.dart';

class MainView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    checkFirstTime(context);
    if (Platform.isAndroid) {
      Future.delayed(Duration.zero, () {
        FlutterBugly.checkUpgrade().then((UpgradeInfo info) {
          if (info != null && info.id != null) {
//            print(info.title);
            showUpdateDialog(info, context);
          }
        });
      });
    }
    return CourseTableView();
  }

//  void checkFirstTime(BuildContext context) async {
//    PackageInfo packageInfo = await PackageInfo.fromPlatform();
//    SharedPreferences sp = await SharedPreferences.getInstance();
//    String storedVersion = sp.getString('version');
//    if(storedVersion == null || storedVersion != packageInfo.version)
//      showDonateDialog(context);
//    sp.setString("version", packageInfo.version);
//  }

  void showUpdateDialog(UpgradeInfo info, BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) => mDialog(
              info.title,
              Text(info.newFeature),
              <Widget>[
                FlatButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                    child: Text(S.of(context).ok),
                    onPressed: () async {
                      await launch(info.apkUrl);
                    }),
              ],
            ));
  }
}
