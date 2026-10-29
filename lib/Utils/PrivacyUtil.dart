import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Models/CourseModel.dart';
import '../generated/l10n.dart';
import '../Components/Dialog.dart';
import '../Components/TransBgTextButton.dart';
import '../Resources/Url.dart';

class PrivacyUtil {
  PrivacyUtil({this.loadPolicy, this.countCourses});

  final Future<dynamic> Function()? loadPolicy;
  final Future<int> Function()? countCourses;
  int requiredVersion = 0;
  bool shouldOfferImport = false;

  Future<bool> checkPrivacy(BuildContext context, bool isForce) async {
    requiredVersion = 0;
    shouldOfferImport = false;
    try {
      final String url =
          Platform.operatingSystem == 'ohos'
              ? Url.UPDATE_ROOT + '/privacy_ohos.json'
              : Url.UPDATE_ROOT + '/privacy.json';
      final dynamic data;
      if (loadPolicy != null) {
        data = await loadPolicy!();
      } else {
        final response = await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        ).get(url);
        if (response.statusCode != HttpStatus.ok) return false;
        data = response.data;
      }
      if (data is! Map || data['version'] is! int || data['version'] <= 0) {
        return false;
      }
      SharedPreferences sp = await SharedPreferences.getInstance();
      int privacyVersion = sp.getInt("privacyVersion") ?? 0;
      int targetVersion = data['version'];
      requiredVersion = targetVersion;
      if (!context.mounted) return false;
      if (isForce || targetVersion > privacyVersion) {
        return await showPrivacyDialog(data, targetVersion, isForce, context);
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> showPrivacyDialog(
    Map info,
    int version,
    bool isForce,
    BuildContext context,
  ) async {
    List<Widget> widgets;
    int courseNum =
        await (countCourses?.call() ?? CourseProvider().getCourseNum());
    bool firstInstall = (courseNum == 0);
    if (!context.mounted) return false;
    bool savingConsent = false;

    Future<void> accept() async {
      if (savingConsent) return;
      savingConsent = true;
      final sp = await SharedPreferences.getInstance();
      final previousVersion = sp.getInt('privacyVersion') ?? 0;
      final saved = await sp.setInt('privacyVersion', version);
      shouldOfferImport = saved && previousVersion == 0 && firstInstall;
      if (context.mounted) Navigator.of(context).pop(saved);
    }

    widgets =
        isForce
            ? <Widget>[
              TransBgTextButton(
                color:
                    Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                child: Text(S.of(context).ok),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ]
            : <Widget>[
              TransBgTextButton(
                color: Colors.grey,
                child: Text(info['cancel_text']),
                onPressed: () {
                  Navigator.of(context).pop(false);
                  SystemChannels.platform.invokeMethod<void>(
                    'SystemNavigator.pop',
                    true,
                  );
                },
              ),
              firstInstall
                  ? TransBgTextButton(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                    child: Text(info['confirm_text_first_install']),
                    onPressed: accept,
                  )
                  : TransBgTextButton(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                    child: Text(info['confirm_text_for_upgrade']),
                    onPressed: accept,
                  ),
            ];
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => PopScope(
                canPop: false,
                child: MDialog(
                  info['title'],
                  SingleChildScrollView(child: Html(data: info['content'])),
                  // SingleChildScrollView(child: Text(info['content'])),
                  overrideActions: widgets,
                ),
              ),
        ) ??
        false;
  }
}
