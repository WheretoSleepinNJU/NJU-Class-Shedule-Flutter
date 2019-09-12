import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Resources/Url.dart';

class AboutView extends StatefulWidget {
  AboutView() : super();
  final String title = '设置';

  @override
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  final String title = '关于';
  String version = '';

  @override
  void initState() {
    super.initState();
    getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Color(0xffeeeeee),
            appBar: AppBar(
              title: Text(title),
            ),
            body: SingleChildScrollView(
                child: new Column(children: <Widget>[
              new Container(
                child:
                    Image.asset("res/icon.png"),
                padding: const EdgeInsets.all(10.0),
                alignment: Alignment.center,
                width: 150,
              ),
              new Container(
                child: Text('南哪课表'),
              ),
              new Container(
                child: Text(version),
              ),
              generateTitle('GitHub开源'),
              generateContent(Url.OPEN_SOURCE_URL,
                  onTap: () => launch(Url.OPEN_SOURCE_URL)),
              generateTitle('开发者'),
              generateContent(
                  '博客：https://idealclover.top\nEmail：idealclover@163.com',
                  onTap: () => launch(Url.BLOG_URL)),
              generateTitle('所使用到的开源库'),
              generateContent(
                'shared_preferences: ^0.5.3+4\npackage_info: ^0.4.0+6\nflutter_bugly: ^0.2.6\nurl_launcher: ^5.1.2\nscoped_model: ^1.0.1\nfluttertoast: ^3.1.3\nsqflite: ^1.1.6\nintl: ^0.16.0',
              ),
              generateTitle(
                  '感谢小百合工作室\n感谢 @ns @lgt 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n感谢各位提供反馈的 NJUers\n谨以此 APP 敬往事\n谢谢 祝幸福'),
            ])))
//    )
        ;
  }

  void getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version + '(Flutter LTS)';
    });
  }

  Widget generateTitle(String text) {
    return new Container(
      padding: const EdgeInsets.all(15.0),
      child: Text(text),
      alignment: Alignment.centerLeft,
    );
  }

  Widget generateContent(String text, {onTap}) {
    return new InkWell(
      child: Container(
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(10.0),
        color: Colors.white,
        child: Text(text),
        alignment: Alignment.centerLeft,
      ),
      onTap: onTap,
    );
  }
}
