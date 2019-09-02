import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import '../../Resources/Strings.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
import '../About/AboutView.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';

class SettingsView extends StatefulWidget {
  SettingsView() : super();
  final String title = '设置';

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String version = '';

  @override
  void initState() {
    super.initState();
    getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[
            SingleChildScrollView(
                child: Column(
                    children: ListTile.divideTiles(context: context, tiles: [
              ListTile(
                title: Text(Strings.import_from_NJU_title),
                subtitle: Text(Strings.import_from_NJU_subtitle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => ImportView()));
                },
              ),
              ListTile(
                title: Text(Strings.manage_table_title),
                subtitle: Text(Strings.manage_table_subtitle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => ManageTableView()));
                },
              ),
              ScopedModelDescendant<MainStateModel>(
                  builder: (context, child, model) {
                return ListTile(
                  title: Text(Strings.change_theme_title),
//                    subtitle: Text(Strings.donate_subtitle),
                  onTap: () => model.changeTheme(2),
                );
              }),
              ListTile(
                  title: Text(Strings.donate_title),
                  subtitle: Text(Strings.donate_subtitle),
                  onTap: _launchURL),
              ListTile(
                title: Text(Strings.about_title),
                subtitle: Text(version),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => AboutView()));
                },
              )
            ]).toList())),
          ],
        ));
  }

  void getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version + '(Flutter LTS)';
    });
  }

  _launchURL() async {
//    const url = 'intent://platformapi/startapp?saId=10000007&clientVersion=3.7.0.0718&qrcode=https%3A%2F%2Fqr.alipay.com%2FFKX00710CQCHIHK4B9CA31%3F_s%3Dweb-other&_t=1472443966571#Intent;scheme=alipayqr;package=com.eg.android.AlipayGphone;end';
    const url =
        'alipayqr://platformapi/startapp?saId=10000007&clientVersion=3.7.0.0718&qrcode=https://qr.alipay.com/FKX00710CQCHIHK4B9CA31';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}