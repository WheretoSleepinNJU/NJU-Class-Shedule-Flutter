import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Models/CourseModel.dart';
import '../Pages/Import/ImportView.dart';
import '../generated/l10n.dart';
import '../Components/Dialog.dart';
import '../Resources/Url.dart';

class PrivacyUtil {
  checkPrivacy(BuildContext context, bool isForce) async {
    Dio dio = new Dio();
    String url = Url.UPDATE_ROOT + '/privacy.json';
    Response response = await dio.get(url);
    if (response.statusCode != HttpStatus.ok) return;
    SharedPreferences sp = await SharedPreferences.getInstance();
    int privacyVersion = sp.getInt("privacyVersion") ?? 0;
    int targetVersion = response.data['version'] ?? 0;
    if (isForce || targetVersion > privacyVersion) {
      showPrivacyDialog(response.data, targetVersion, isForce, context);
    }
  }

  void showPrivacyDialog(
      Map info, int version, bool isForce, BuildContext context) async {
    List<Widget> widgets;
    CourseProvider courseProvider = new CourseProvider();
    int courseNum = await courseProvider.getCourseNum();
    bool firstInstall = (courseNum == 0);
    widgets = isForce
        ? <Widget>[
            TextButton(
                child: Text(S.of(context).ok,
                    style: TextStyle(color: Theme.of(context).primaryColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ]
        : <Widget>[
            TextButton(
                child: Text(info['cancel_text'],
                    style: TextStyle(color: Colors.grey)),
                onPressed: () => SystemChannels.platform
                    .invokeMethod<void>('SystemNavigator.pop', true)),
            firstInstall
                ? TextButton(
                    child: Text(info['confirm_text_first_install'],
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      await sp.setInt("privacyVersion", version);
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => ImportView()));
                    })
                : TextButton(
                    child: Text(info['confirm_text_for_upgrade'],
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      await sp.setInt("privacyVersion", version);
                      Navigator.of(context).pop();
                    }),
          ];
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => mDialog(
              info['title'],
              SingleChildScrollView(child: Html(data: info['content'])),
              widgets,
            ));
  }
}
