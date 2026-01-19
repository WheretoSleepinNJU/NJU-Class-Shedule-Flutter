import 'dart:io';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/UpdateUtil.dart';
import '../../Utils/PrivacyUtil.dart';
import '../../Resources/Url.dart';
import 'Widgets/RainDropWidget.dart';

class AboutView extends StatefulWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Theme.of(context).hoverColor,
        appBar: AppBar(
          title: Text(S.of(context).about_title),
        ),
        body: Stack(children: [
          RainDropWidget(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height),
          SingleChildScrollView(
              child: Column(children: <Widget>[
            Container(
              child: Image.asset("res/icon.png"),
              padding: const EdgeInsets.all(10.0),
              alignment: Alignment.center,
              width: 150,
            ),
            Text(S.of(context).app_name),
            FutureBuilder<String>(
                future: _getVersion(),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  } else {
                    return Text(snapshot.data!);
                  }
                }),
            TextButton(
              child: Text(S.of(context).check_update_button),
              onPressed: () {
                UpdateUtil updateUtil = UpdateUtil();
                updateUtil.checkUpdate(context, true);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                  backgroundColor: Colors.transparent),
              child: Text(S.of(context).check_privacy_button),
              onPressed: () {
                PrivacyUtil privacyUtil = PrivacyUtil();
                privacyUtil.checkPrivacy(context, true);
              },
            ),
            _generateTitle(S.of(context).github_open_source),
            _generateContent(Url.OPEN_SOURCE_URL,
                onTap: () => launch(Url.OPEN_SOURCE_URL)),
            // 针对华为鸿蒙，获取彩蛋来确定是否要展示开发者
            Platform.operatingSystem == 'ohos'
                ? FutureBuilder(
                    future: _showDeveloperOhos(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (snapshot.hasData && snapshot.data!) {
                        return _generateTitle(S.of(context).developer);
                      }
                      return Container();
                    })
                : _generateTitle(S.of(context).developer),
            _generateContent(S.of(context).introduction,
                onTap: () => launch(Url.BLOG_URL)),
            _generateTitle(S.of(context).open_source_library_title),
            _generateContent(S.of(context).open_source_library_content),
            _generateTitle(S.of(context).easter_egg_title),
            FutureBuilder<String>(
                future: _getEasterEggContent(S.of(context).easter_egg),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (!snapshot.hasData) {
                    return _generateContent(S.of(context).easter_egg);
                  } else {
                    return _generateContent(snapshot.data!);
                  }
                }),
          ]))
        ]));
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version + S.of(context).flutter_lts;
  }

  Widget _generateTitle(String text) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Text(text),
      alignment: Alignment.centerLeft,
    );
  }

  Widget _generateContent(String text, {onTap}) {
    return InkWell(
      child: Container(
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(10.0),
        color: Theme.of(context).secondaryHeaderColor,
        child: Text(text),
        alignment: Alignment.centerLeft,
      ),
      onTap: onTap,
    );
  }

  static Future<bool> _showDeveloperOhos() async {
    String url = Url.UPDATE_ROOT + '/easterEgg.json';
    try {
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        bool showDeveloper = response.data['showDeveloperOhos'] ?? false;
        return showDeveloper;
      }
    } catch (e) {
      // 忽略网络错误，使用兜底文案
    }
    return false;
  }

  static Future<String> _getEasterEggContent(fallbackContent) async {
    String url = Url.UPDATE_ROOT + '/easterEgg.json';
    try {
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        String content = response.data['content'] ?? fallbackContent;
        if (content.trim().isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      // 忽略网络错误，使用兜底文案
    }
    return fallbackContent;
  }
}
