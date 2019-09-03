import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:scoped_model/scoped_model.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
import '../About/AboutView.dart';
import '../../Utils/States/MainState.dart';
import '../../Resources/Strings.dart';
import '../../Resources/Themes.dart';
import '../../Resources/Url.dart';

class SettingsView extends StatefulWidget {
  SettingsView() : super();
  final String title = '设置';

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String version = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
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
                return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                            themeDataList.length,
                            (int i) => new Container(
                                width: 30,
                                height: 30,
                                margin: EdgeInsets.only(
                                    left: 15, top: 10, bottom: 10),
                                decoration: new BoxDecoration(
                                  color: themeDataList[i].primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: InkResponse(
                                  onTap: () => model.changeTheme(i),
                                )))));
              }),
              ListTile(
                  title: Text(Strings.report_title),
                  subtitle: Text(Strings.report_subtitle),
                  onTap: () async {
                    bool status = await _launchURL(Url.QQ_GROUP_URL);
                    if (!status)
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text("打开失败，可能是未安装 TIM/QQ"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                  }),
              ListTile(
                  title: Text(Strings.donate_title),
                  subtitle: Text(Strings.donate_subtitle),
                  onTap: () async {
                    bool status = await _launchURL(Url.ALIPAY_URL);
                    if (!status)
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text("打开失败，可能是未安装支付宝"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                  }),
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

  Future<bool> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
      return true;
    } else {
      return false;
    }
  }
}
