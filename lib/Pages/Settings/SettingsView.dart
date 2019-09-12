import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:scoped_model/scoped_model.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';
import '../About/AboutView.dart';
import '../Add/Add.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Components/Toast.dart';
import '../../Resources/Strings.dart';
import '../../Resources/Config.dart';
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
  int nowWeek = 1;

//  int changedWeek = 1;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getVersion();
  }

  @override
  Widget build(BuildContext context) {
    getWeek(context);
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            SingleChildScrollView(
                child: Column(
                    children: ListTile.divideTiles(context: context, tiles: [
              ListTile(
                title: Text(Strings.import_manually_title),
                subtitle: Text(Strings.import_manually_subtitle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => AddView()));
                },
              ),
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
                title: Text(Strings.shuffle_color_pool_title),
                subtitle: Text(Strings.shuffle_color_pool_subtitle),
                onTap: () {
                  ColorPool.shuffleColorPool();
                  Toast.showToast(Strings.shuffle_color_pool_success_toast, context);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(Strings.change_week_title),
                subtitle:
                    Text(Strings.change_week_subtitle + nowWeek.toString()),
                onTap: () async {
                  await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      int changedWeek = nowWeek - 1;
                      return AlertDialog(
                        title: Text(Strings.change_week_title),
                        content: Container(
                            height: 32,
                            child: CupertinoPicker(
                                scrollController:
                                    new FixedExtentScrollController(
                                  initialItem: nowWeek - 1,
                                ),
                                itemExtent: 32.0,
                                backgroundColor: Colors.white,
                                onSelectedItemChanged: (int index) {
                                  changedWeek = index;
                                },
                                children: new List<Widget>.generate(
                                    Config.MAX_WEEKS, (int index) {
                                  return new Center(
                                    child: new Text(
                                      '第' + '${index + 1}' + '周',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  );
                                }))),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(Strings.cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                              child: Text(Strings.ok),
                              onPressed: () async {
                                await changeWeek(changedWeek);
                              }),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                title: Text(Strings.report_title),
                subtitle: Text(Strings.report_subtitle),
                onTap: () async {
                  bool status = false;
                  if (Platform.isIOS)
                    status = await _launchURL(Url.QQ_GROUP_APPLE_URL);
                  else if (Platform.isAndroid)
                    status = await _launchURL(Url.QQ_GROUP_ANDROID_URL);
                  if (!status)
                    Toast.showToast("打开失败，可能是未安装 TIM/QQ", context);
                },
                onLongPress: () async {
                  if (Platform.isIOS)
                    await Clipboard.setData(new ClipboardData(text: Config.IOS_GROUP));
                  else if (Platform.isAndroid)
                    await Clipboard.setData(new ClipboardData(text: Config.ANDROID_GROUP));
                  Toast.showToast("已复制群号到剪贴板", context);
                },
              ),
              ListTile(
                  title: Text(Strings.donate_title),
                  subtitle: Text(Strings.donate_subtitle),
                  onTap: () async {
                    bool status = false;
                    if (Platform.isIOS)
                      status = await _launchURL(Url.ALIPAY_URL_APPLE);
                    else if (Platform.isAndroid)
                      status = await _launchURL(Url.ALIPAY_URL_ANDROID);
                    if (!status) Toast.showToast("打开失败，可能是未安装支付宝", context);
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
        )));
  }

  void getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version + '(Flutter LTS)';
    });
  }

  void getWeek(BuildContext context) async {
    int tmp = await MainStateModel.of(context).getWeek();
    setState(() {
      nowWeek = tmp;
    });
  }

  void changeWeek(int changedWeek) async {
    if (changedWeek == nowWeek - 1) {
      Toast.showToast("当前周未修改 >v<", context);
      Navigator.of(context).pop();
    } else {
      await WeekUtil.setNowWeek(changedWeek + 1);
      Toast.showToast("修改当前周成功 >v<", context);
      Navigator.of(context).pop();
    }
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
