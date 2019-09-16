import 'dart:io';
import 'dart:math';
import 'package:wheretosleepinnju/Utils/States/ConfigState.dart';

import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Components/Toast.dart';

class MoreSettingsView extends StatefulWidget {
  MoreSettingsView() : super();

  @override
  _MoreSettingsViewState createState() => _MoreSettingsViewState();
}

class _MoreSettingsViewState extends State<MoreSettingsView> {
  @override
  void initState() {
    super.initState();
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
                // using your method of getting an image
                final File image =
                    await ImagePicker.pickImage(source: ImageSource.gallery);

                // delete old picture
                String oldPath = await ScopedModel.of<MainStateModel>(context)
                    .getBgImgPath();
                if (oldPath != null) {
                  File oldImg = File(oldPath);
                  if (oldImg.existsSync()) {
                    oldImg.deleteSync(recursive: true);
                    print('Old image deleted.');
                  }
                }

                // add new picture
                int num = Random().nextInt(1000);
                Directory directory = await getApplicationDocumentsDirectory();
                final String path = directory.path;
                String fileName = '$path/background_$num.jpg';
                await image.copy(fileName);
                await ScopedModel.of<MainStateModel>(context)
                    .setBgImgPath(fileName);
                print('New image added.');
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
                // delete old picture
                String oldPath = await ScopedModel.of<MainStateModel>(context)
                    .getBgImgPath();
                if (oldPath != null) {
                  File oldImg = File(oldPath);
                  if (oldImg.existsSync()) {
                    oldImg.deleteSync(recursive: true);
                    print('Old image deleted.');
                  }
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
                title: Text('隐藏添加按钮'),
                subtitle: Text('隐藏主界面右下角添加按钮'),
                trailing: FutureBuilder<bool>(
                    future: _getAddButton(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (!snapshot.hasData) {
                        return Container(width: 0);
                      } else {
                        return Switch(
                          value: !snapshot.data,
                          onChanged: (bool value) =>
                              ScopedModel.of<MainStateModel>(context)
                                  .setAddButton(!value),
                        );
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
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowWeekend(value),
                      );
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
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowClassTime(value),
                      );
                    }
                  }),
            ),
            ListTile(
              title: Text('显示月份'),
              subtitle: Text('在课表的左上角显示当前月份'),
              trailing: FutureBuilder<bool>(
                  future: _getShowMonth(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowMonth(value),
                      );
                    }
                  }),
            ),
            ListTile(
              title: Text('显示日期'),
              subtitle: Text('显示当前周的日期'),
              trailing: FutureBuilder<bool>(
                  future: _getShowDate(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowDate(value),
                      );
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
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setForceZoom(value),
                      );
                    }
                  }),
            ),
          ]).toList()))
        ])));
  }

  Future<bool> _getShowWeekend() async {
    return await ScopedModel.of<MainStateModel>(context).getShowWeekend();
  }

  Future<bool> _getShowClassTime() async {
    return await ScopedModel.of<MainStateModel>(context).getShowClassTime();
  }

  Future<bool> _getShowMonth() async {
    return await ScopedModel.of<MainStateModel>(context).getShowMonth();
  }

  Future<bool> _getShowDate() async {
    return await ScopedModel.of<MainStateModel>(context).getShowDate();
  }

  Future<bool> _getForceZoom() async {
    return await ScopedModel.of<MainStateModel>(context).getForceZoom();
  }

  Future<bool> _getAddButton() async {
    return await ScopedModel.of<MainStateModel>(context).getAddButton();
  }
}
