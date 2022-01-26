import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Models/CourseModel.dart';
import '../generated/l10n.dart';
import '../Components/Dialog.dart';
import '../Components/TransBgTextButton.dart';
import '../Resources/Url.dart';

class PrivacyUtil {
  Future<bool> checkPrivacy(BuildContext context, bool isForce) async {
    try {
      Dio dio = Dio();
      String url = Url.UPDATE_ROOT + '/privacy.json';
      Response response = await dio.get(url);
      if (response.statusCode != HttpStatus.ok) return false;
      SharedPreferences sp = await SharedPreferences.getInstance();
      int privacyVersion = sp.getInt("privacyVersion") ?? 0;
      int targetVersion = response.data['version'] ?? 0;
      if (isForce || targetVersion > privacyVersion) {
        return await showPrivacyDialog(
            response.data, targetVersion, isForce, context);
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
    CourseProvider courseProvider = CourseProvider();
    int courseNum = await courseProvider.getCourseNum();
    bool firstInstall = (courseNum == 0);
    UmengCommonSdk.onEvent("privacy_dialog", {"action": "show"});
    widgets = isForce
        ? <Widget>[
            TransBgTextButton(
                color: Theme.of(context).primaryColor,
                child: Text(S.of(context).ok),
                onPressed: () {
                  UmengCommonSdk.onEvent(
                      "privacy_dialog", {"action": "forceAccept"});
                  Navigator.of(context).pop(false);
                })
          ]
        : <Widget>[
            TransBgTextButton(
                color: Colors.grey,
                child: Text(info['cancel_text']),
                onPressed: () {
                  UmengCommonSdk.onEvent(
                      "privacy_dialog", {"action": "cancel"});
                  SystemChannels.platform
                      .invokeMethod<void>('SystemNavigator.pop', true);
                }),
            firstInstall
                ? TransBgTextButton(
                    color: Theme.of(context).primaryColor,
                    child: Text(info['confirm_text_first_install']),
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      await sp.setInt("privacyVersion", version);
                      UmengCommonSdk.onEvent(
                          "privacy_dialog", {"action": "accept"});
                      Navigator.of(context).pop(true);
                    })
                : TransBgTextButton(
                    color: Theme.of(context).primaryColor,
                    child: Text(info['confirm_text_for_upgrade']),
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      await sp.setInt("privacyVersion", version);
                      UmengCommonSdk.onEvent(
                          "privacy_dialog", {"action": "acceptUpgrade"});
                      Navigator.of(context).pop(false);
                    }),
          ];
    return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MDialog(
              info['title'],
              SingleChildScrollView(child: Html(data: info['content'])),
              overrideActions: widgets,
            ));
  }
}
