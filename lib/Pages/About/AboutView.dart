import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

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
//              centerTitle: false,
              title: Text(title),
            ),
            body: SingleChildScrollView(
                child: new Column(children: <Widget>[
              new Container(
                child: new Image.network(
                  'https://raw.githubusercontent.com/idealclover/NJU-Class-Shedule-Android/master/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                ),
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
              generateContent(
                  'https://github.com/idealclover/NJU-Class-Shedule-Android'),
              generateTitle('开发者'),
              generateContent(
                  '博客：https://idealclover.top\nEmail：idealclover@163.com'),
                  generateTitle('感谢小百合工作室\n感谢 @ns @lgt 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n感谢各位提供反馈的NJUers\n谨以此APP送给子枨 谢谢'),
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

  Widget generateContent(String text) {
    return new Container(
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(10.0),
      color: Colors.white,
      child: Text(text),
      alignment: Alignment.centerLeft,
    );
  }
}
