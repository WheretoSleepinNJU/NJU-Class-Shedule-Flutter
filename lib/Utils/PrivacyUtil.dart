import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Models/CourseModel.dart';
import '../generated/l10n.dart';
import '../Components/Dialog.dart';
import '../Resources/Url.dart';

class PrivacyUtil {
  Future<bool> checkPrivacy(BuildContext context, bool isForce) async {
    try {
      Dio dio = new Dio();
      String url = Url.UPDATE_ROOT + '/privacy.json';
      Response response = await dio.get(url);
      if (response.statusCode != HttpStatus.ok) return false;
      SharedPreferences sp = await SharedPreferences.getInstance();
      int privacyVersion = sp.getInt("privacyVersion") ?? 0;
      int targetVersion = response.data['version'] ?? 0;
      if (isForce || targetVersion > privacyVersion) {
        return await showPrivacyDialog(response.data, targetVersion, isForce, context);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> showPrivacyDialog(
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
                  Navigator.of(context).pop(false);
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
                      Navigator.of(context).pop(true);
                    })
                : TextButton(
                    child: Text(info['confirm_text_for_upgrade'],
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      await sp.setInt("privacyVersion", version);
                      Navigator.of(context).pop(false);
                    }),
          ];
    return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => mDialog(
              info['title'],
              SingleChildScrollView(child: Html(data: info['content'])),
              widgets,
            ));
  }
}
