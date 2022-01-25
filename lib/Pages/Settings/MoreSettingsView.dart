import 'dart:io';
import 'dart:math';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Components/Toast.dart';
import './Widgets/NumChanger.dart';

class MoreSettingsView extends StatefulWidget {
  const MoreSettingsView({Key? key}) : super(key: key);

  @override
  _MoreSettingsViewState createState() => _MoreSettingsViewState();
}

class _MoreSettingsViewState extends State<MoreSettingsView> {
  bool showCustomClassHeight = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    bool forceZoom = await _getForceZoom();
    setState(() {
      showCustomClassHeight = !forceZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).more_settings_title),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          SingleChildScrollView(
              child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
            ListTile(
              title: Text(S.of(context).shuffle_color_pool_title),
              subtitle: Text(S.of(context).shuffle_color_pool_subtitle),
              onTap: () {
                ColorPool.shuffleColorPool();
                UmengCommonSdk.onEvent("more_setting", {"type": 1});
                Toast.showToast(
                    S.of(context).shuffle_color_pool_success_toast, context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(S.of(context).add_backgound_picture_title),
              subtitle: Text(S.of(context).add_backgound_picture_subtitle),
              onTap: () async {
                UmengCommonSdk.onEvent("more_setting", {"type": 2});
                // using your method of getting an image
                final XFile? image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);

                if (image == null) return;

                // delete old picture
                String oldPath = await ScopedModel.of<MainStateModel>(context)
                    .getBgImgPath();
                File oldImg = File(oldPath);
                if (oldImg.existsSync()) {
                  oldImg.deleteSync(recursive: true);
                  // print('Old image deleted.');
                }

                // add new picture
                int num = Random().nextInt(1000);
                Directory directory = await getApplicationDocumentsDirectory();
                final String path = directory.path;
                String fileName = '$path/background_$num.jpg';
                await image.saveTo(fileName);
                await ScopedModel.of<MainStateModel>(context)
                    .setBgImgPath(fileName);
                // print('New image added.');
                Toast.showToast(
                    S.of(context).add_backgound_picture_success_toast, context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(S.of(context).delete_backgound_picture_title),
              subtitle: Text(S.of(context).delete_backgound_picture_subtitle),
              onTap: () async {
                UmengCommonSdk.onEvent("more_setting", {"type": 3});
                // delete old picture
                String oldPath = await ScopedModel.of<MainStateModel>(context)
                    .getBgImgPath();
                File oldImg = File(oldPath);
                if (oldImg.existsSync()) {
                  oldImg.deleteSync(recursive: true);
                  // print('Old image deleted.');
                }
                await ScopedModel.of<MainStateModel>(context).removeBgImgPath();
                Toast.showToast(
                    S.of(context).delete_backgound_picture_success_toast,
                    context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
                title: Text(S.of(context).white_title_mode_title),
                subtitle: Text(S.of(context).white_title_mode_subtitle),
                trailing: FutureBuilder<bool>(
                    future: _getWhiteMode(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (!snapshot.hasData) {
                        return Container(width: 0);
                      } else {
                        return Switch(
                            activeColor: Theme.of(context).primaryColor,
                            value: snapshot.data!,
                            onChanged: (bool value) {
                              UmengCommonSdk.onEvent(
                                  "more_setting", {"type": 4,
                                "result": value.toString()});
                              ScopedModel.of<MainStateModel>(context)
                                  .setWhiteMode(value);
                            });
                      }
                    })),
            ListTile(
                title: Text(S.of(context).hide_add_button_title),
                subtitle: Text(S.of(context).hide_add_button_subtitle),
                trailing: FutureBuilder<bool>(
                    future: _getAddButton(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (!snapshot.hasData) {
                        return Container(width: 0);
                      } else {
                        return Switch(
                            activeColor: Theme.of(context).primaryColor,
                            value: !snapshot.data!,
                            onChanged: (bool value) {
                              UmengCommonSdk.onEvent(
                                  "more_setting", {"type": 5, "result": value.toString()});
                              ScopedModel.of<MainStateModel>(context)
                                  .setAddButton(!value);
                            });
                      }
                    })),
            ListTile(
              title: Text(S.of(context).if_show_weekend_title),
              subtitle: Text(S.of(context).if_show_weekend_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowWeekend(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 6, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowWeekend(value);
                          });
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).if_show_classtime_title),
              subtitle: Text(S.of(context).if_show_classtime_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowClassTime(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 7, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowClassTime(value);
                          });
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).if_show_freeclass_title),
              subtitle: Text(S.of(context).if_show_freeclass_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowFreeClass(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 8, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowFreeClass(value);
                          });
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).show_month_title),
              subtitle: Text(S.of(context).show_month_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowMonth(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 9, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowMonth(value);
                          });
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).show_date_title),
              subtitle: Text(S.of(context).show_date_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowDate(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 10, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowDate(value);
                          });
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).force_zoom_title),
              subtitle: Text(S.of(context).force_zoom_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getForceZoom(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                          activeColor: Theme.of(context).primaryColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            ScopedModel.of<MainStateModel>(context)
                                .setForceZoom(value);
                            UmengCommonSdk.onEvent(
                                "more_setting", {"type": 11, "result": value.toString()});
                            setState(() {
                              showCustomClassHeight = !value;
                            });
                          });
                    }
                  }),
            ),
            showCustomClassHeight
                ? ListTile(
                    title: Text(S.of(context).class_height_title),
                    subtitle: Text(S.of(context).class_height_subtitle),
                    trailing: FutureBuilder<int>(
                        future: _getClassHeight(),
                        builder: (BuildContext context,
                            AsyncSnapshot<int> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SizedBox(
                                width: 102,
                                child: NumberChangerWidget(
                                  width: 40,
                                  iconWidth: 30,
                                  numText: snapshot.data.toString(),
                                  addValueChanged: (num) {
                                    _setClassHeight(num);
                                  },
                                  removeValueChanged: (num) {
                                    _setClassHeight(num);
                                  },
                                  updateValueChanged: (num) {
                                    _setClassHeight(num);
                                  },
                                ));
                          }
                        }),
                  )
                : Container(width: 0),
          ]).toList()))
        ])));
  }

  Future<bool> _getShowWeekend() async {
    return await ScopedModel.of<MainStateModel>(context).getShowWeekend();
  }

  Future<bool> _getShowClassTime() async {
    return await ScopedModel.of<MainStateModel>(context).getShowClassTime();
  }

  Future<bool> _getShowFreeClass() async {
    return await ScopedModel.of<MainStateModel>(context).getShowFreeClass();
  }

  Future<bool> _getShowMonth() async {
    return await ScopedModel.of<MainStateModel>(context).getShowMonth();
  }

  Future<bool> _getShowDate() async {
    return await ScopedModel.of<MainStateModel>(context).getShowDate();
  }

  Future<int> _getClassHeight() async {
    return await ScopedModel.of<MainStateModel>(context).getClassHeight();
  }

  _setClassHeight(int classHeight) async {
    ScopedModel.of<MainStateModel>(context).setClassHeight(classHeight);
  }

  Future<bool> _getForceZoom() async {
    return await ScopedModel.of<MainStateModel>(context).getForceZoom();
  }

  Future<bool> _getAddButton() async {
    return await ScopedModel.of<MainStateModel>(context).getAddButton();
  }

  Future<bool> _getWhiteMode() async {
    return await ScopedModel.of<MainStateModel>(context).getWhiteMode();
  }
}
