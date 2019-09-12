import 'dart:io';
import '../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'CourseTable/CourseTableView.dart';

class MainView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      Future.delayed(Duration.zero, () {
        FlutterBugly.checkUpgrade().then((UpgradeInfo info) {
          if (info != null && info.id != null) {
            print(info.title);
            showUpdateDialog(info, context);
          }
        });
      });
    }
    return CourseTableView();
  }

  void showUpdateDialog(UpgradeInfo info, BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(info.title),
              content: Text(info.newFeature),
              actions: <Widget>[
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
