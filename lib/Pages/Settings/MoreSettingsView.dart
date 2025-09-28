import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:collection';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:device_calendar/device_calendar.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Components/Toast.dart';
import './Widgets/NumChanger.dart';
import '../../Models/CourseModel.dart';

class MoreSettingsView extends StatefulWidget {
  const MoreSettingsView({Key? key}) : super(key: key);

  @override
  _MoreSettingsViewState createState() => _MoreSettingsViewState();
}

class _MoreSettingsViewState extends State<MoreSettingsView> {
  bool showCustomClassHeight = false;
  bool showWhiteTitleMode = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    bool forceZoom = await _getForceZoom();
    bool hasPic = await _getHasImgPath();
    setState(() {
      showCustomClassHeight = !forceZoom;
      showWhiteTitleMode = hasPic;
    });
  }

  Map<int, DateTime> timeMap = {
    1: DateTime(2022, 1, 1, 8, 0),
    2: DateTime(2022, 1, 1, 9, 0),
    3: DateTime(2022, 1, 1, 10, 10),
    4: DateTime(2022, 1, 1, 11, 10),
    5: DateTime(2022, 1, 1, 14, 0),
    6: DateTime(2022, 1, 1, 15, 0),
    7: DateTime(2022, 1, 1, 16, 10),
    8: DateTime(2022, 1, 1, 17, 10),
    9: DateTime(2022, 1, 1, 18, 30),
    10: DateTime(2022, 1, 1, 19, 30),
    11: DateTime(2022, 1, 1, 20, 30),
    12: DateTime(2022, 1, 1, 21, 30),
  };

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
                title: Text(S.of(context).change_theme_mode_title),
                subtitle: Text(S.of(context).change_theme_mode_subtitle),
                trailing: FutureBuilder<int>(
                    future: _getThemeIndex(),
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (!snapshot.hasData) {
                        return Container(width: 0);
                      } else {
                        // return DropdownButton(items: items, onChanged: onChanged)
                        return DropdownButton<int>(
                            value: snapshot.data,
                            items: [
                              DropdownMenuItem(
                                  child: Row(children: const [
                                    Icon(Icons.settings),
                                    Text('跟随系统')
                                  ]),
                                  value: 0),
                              DropdownMenuItem(
                                  child: Row(children: const [
                                    Icon(Icons.wb_sunny),
                                    Text('浅色模式')
                                  ]),
                                  value: 1),
                              DropdownMenuItem(
                                  child: Row(children: const [
                                    Icon(Icons.shield_moon),
                                    Text('深色模式')
                                  ]),
                                  value: 2)
                            ],
                            onChanged: (value) {
                              UmengCommonSdk.onEvent("more_setting",
                                  {"type": 12, "result": value.toString()});
                              ScopedModel.of<MainStateModel>(context)
                                  .changeThemeMode(value ?? 0);
                              setState(() {});
                            });
                      }
                    })),
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
                if (await oldImg.exists()) {
                  await oldImg.delete(recursive: true);
                  // print('Old image deleted.');
                }
                await ScopedModel.of<MainStateModel>(context).removeBgImgPath();
                Toast.showToast(
                    S.of(context).delete_backgound_picture_success_toast,
                    context);
                // String thePath = await ScopedModel.of<MainStateModel>(context)
                //     .getBgImgPath();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(S.of(context).export_to_system_calendar_title),
              subtitle: Text(S.of(context).export_to_system_calendar_subtitle),
              onTap: () async {
                exportToSystemCalendar(context);
              },
            ),
            showWhiteTitleMode
                ? ListTile(
                    title: Text(S.of(context).white_title_mode_title),
                    subtitle: Text(S.of(context).white_title_mode_subtitle),
                    trailing: FutureBuilder<bool>(
                        future: _getWhiteMode(),
                        builder: (BuildContext context,
                            AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return Switch(
                                activeColor: Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                                value: snapshot.data!,
                                onChanged: (bool value) {
                                  UmengCommonSdk.onEvent("more_setting",
                                      {"type": 4, "result": value.toString()});
                                  ScopedModel.of<MainStateModel>(context)
                                      .setWhiteMode(value);
                                  setState(() {});
                                });
                          }
                        }))
                : Container(width: 0),
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
                            activeColor:
                                Theme.of(context).appBarTheme.backgroundColor,
                            value: !snapshot.data!,
                            onChanged: (bool value) {
                              UmengCommonSdk.onEvent("more_setting",
                                  {"type": 5, "result": value.toString()});
                              ScopedModel.of<MainStateModel>(context)
                                  .setAddButton(!value);
                              setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 6, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowWeekend(value);
                            setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 7, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowClassTime(value);
                            setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 8, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowFreeClass(value);
                            setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 9, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowMonth(value);
                            setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 10, "result": value.toString()});
                            ScopedModel.of<MainStateModel>(context)
                                .setShowDate(value);
                            setState(() {});
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
                          activeColor:
                              Theme.of(context).appBarTheme.backgroundColor,
                          value: snapshot.data!,
                          onChanged: (bool value) {
                            ScopedModel.of<MainStateModel>(context)
                                .setForceZoom(value);
                            UmengCommonSdk.onEvent("more_setting",
                                {"type": 11, "result": value.toString()});
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

  Future<int> _getThemeIndex() async {
    return await ScopedModel.of<MainStateModel>(context).getThemeMode();
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

  Future<bool> _getHasImgPath() async {
    String imgPath =
        await ScopedModel.of<MainStateModel>(context).getBgImgPath();
    return imgPath != "";
  }

  Future<bool> _getWhiteMode() async {
    bool whiteMode =
        await ScopedModel.of<MainStateModel>(context).getWhiteMode();
    return whiteMode;
  }

  Future<bool> exportToSystemCalendar(BuildContext ctx) async {
    int tableId = await MainStateModel.of(context).getClassTable();
    CourseProvider cp = CourseProvider();
    List courses = await cp.getAllCourses(tableId);

    Map<int, DateTime> dayMap = await getDayMap();
    Duration courseLength = Duration(minutes: 50);
    DeviceCalendarPlugin dc = DeviceCalendarPlugin();
    const String CALENDAR_NAME = "南哪课表";
    for (Map<String, dynamic> courseMap in courses) {
      Course course = Course.fromMap(courseMap);
      if (course.weekTime == 0) {
        continue;
      }
      for (int week_num in json.decode(course.weeks!)) {
        DateTime day =
            dayMap[course.weekTime]!.add(Duration(days: 7) * week_num);
        DateTime startTime = timeMap[course.startTime]!;
        DateTime endTime = timeMap[course.startTime! + course.timeCount! + 1]!;

        String timezone = 'Asia/Shanghai';
        Location loc = timeZoneDatabase.get(timezone);

        TZDateTime start = TZDateTime(loc, day.year, day.month, day.day,
            startTime.hour, startTime.minute);
        TZDateTime end = TZDateTime(
            loc, day.year, day.month, day.day, endTime.hour, endTime.minute);

        try {
          UnmodifiableListView calendars = (await dc.retrieveCalendars()).data!;
          String? targetCalendarId;
          bool found = false;
          for (Calendar c in calendars) {
            if (c.name == CALENDAR_NAME) {
              targetCalendarId = c.id!;
              found = true;
              break;
            }
          }
          if (found == false) {
            targetCalendarId = (await dc.createCalendar(CALENDAR_NAME)).data!;
          }
          String? result = (await dc.createOrUpdateEvent(Event(
            targetCalendarId!,
            title: course.name,
            start: start,
            end: end,
            location: course.testLocation,
            description: course.info,
          )))
              ?.data;
        } catch (e) {
          Toast.showToast(
              S.of(context).export_to_system_calendar_fail_toast, context);
        }
      }
    }
    return true;
  }

  Future<Map<int, DateTime>> getDayMap() async {
    //获取开学第一周的周一到周日的日期
    //时间是调用此函数时的时间，没有意义，不应被使用
    Map<int, DateTime> dayMap = {};
    DateTime now = DateTime.now();
    int weekNum = await ScopedModel.of<MainStateModel>(context).getWeek();
    Duration backaweek = Duration(days: -7);
    Duration backaday = Duration(days: -1);
    DateTime firstDay = now.add(backaweek * weekNum + backaday * now.weekday);
    for (int i = 0; i < 7; i++) {
      Duration delta = Duration(days: i);
      DateTime target = firstDay.add(delta);
      dayMap[target.weekday] = target;
    }
    return dayMap;
  }
}
