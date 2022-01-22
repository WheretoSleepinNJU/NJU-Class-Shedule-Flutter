import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:package_info/package_info.dart';
import '../generated/l10n.dart';
import '../Utils/States/MainState.dart';
import '../Components/Dialog.dart';
import '../Components/Toast.dart';
import '../Resources/Url.dart';

class UpdateUtil {
  checkUpdate(BuildContext context, bool isForce) async {
    int lastCheckUpdateTime =
        await ScopedModel.of<MainStateModel>(context).getLastCheckUpdateTime();
    int coolDownTime =
        await ScopedModel.of<MainStateModel>(context).getCoolDownTime();

    DateTime now = new DateTime.now();
    DateTime last =
        new DateTime.fromMillisecondsSinceEpoch(lastCheckUpdateTime);
    var difference = now.difference(last);
//    print(difference.inSeconds);
//    print(now.millisecondsSinceEpoch);
    ScopedModel.of<MainStateModel>(context)
        .setLastCheckUpdateTime(now.millisecondsSinceEpoch);
    if (!isForce && difference.inSeconds < coolDownTime) return;

    Dio dio = new Dio();
    String url;
    if (Platform.isIOS)
      url = Url.UPDATE_ROOT + '/ios.json';
    else if (Platform.isAndroid)
      url = Url.UPDATE_ROOT + '/android.json';
    else
      return;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Response response = await dio.get(url);
    if (response.statusCode == HttpStatus.ok) {
      if (response.data['coolDownTime'] != null)
        ScopedModel.of<MainStateModel>(context).setCoolDownTime(coolDownTime);
      if (response.data['version'] > int.parse(packageInfo.buildNumber)) {
        await showUpdateDialog(response.data, context);
      } else if (isForce) {
        Toast.showToast(S.of(context).already_newest_version_toast, context);
      }
    }
  }

  showUpdateDialog(Map info, BuildContext context) async {
    UmengCommonSdk.onEvent("update_dialog", {"action": "show"});
    List<Widget> widgets;
    if (info['isForce']) {
      widgets = <Widget>[
        FlatButton(
            child: Text(info['confirm_text']),
            textColor: Theme.of(context).primaryColor,
            onPressed: () async {
              UmengCommonSdk.onEvent(
                  "update_dialog", {"action": "forceAccept"});
              if (info['url'] != '') await launch(info['url']);
            }),
      ];
    } else {
      widgets = <Widget>[
        FlatButton(
          child: Text(info['cancel_text']),
          textColor: Colors.grey,
          onPressed: () {
            UmengCommonSdk.onEvent(
                "update_dialog", {"action": "cancel"});
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
            child: Text(info['confirm_text']),
            textColor: Theme.of(context).primaryColor,
            onPressed: () async {
              UmengCommonSdk.onEvent(
                  "update_dialog", {"action": "accept"});
              if (info['url'] != '') await launch(info['url']);
            }),
      ];
    }
    await showDialog(
        context: context,
        barrierDismissible: !info['isForce'],
        builder: (context) => mDialog(
              info['title'],
              Text(info['content']),
              widgets,
            ));
  }
}
