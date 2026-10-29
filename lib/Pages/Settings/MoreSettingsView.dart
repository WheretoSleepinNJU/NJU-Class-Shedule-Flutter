import '../../AdaptiveUI/adaptive_ui.dart';
import 'Widgets/PlatformSettings.dart';
import 'package:wheretosleepinnju/Pages/Settings/Widgets/ThemeChanger.dart';

import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
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
    if (!mounted) return;
    setState(() {
      showCustomClassHeight = !forceZoom;
    });

    final model = ScopedModel.of<MainStateModel>(
      context,
      rebuildOnChange: false,
    );
    model.getMaterial3ColorForLight().then((_) => model.refresh());
    model.getMaterial3ColorForDark().then((_) => model.refresh());
  }

  Future<void> _resetCourseColors() async {
    await ColorPool.shuffleColorPool();
    if (!mounted) return;
    ScopedModel.of<MainStateModel>(context, rebuildOnChange: false).refresh();
    UmengCommonSdk.onEvent("more_setting", {"type": 1});
    Toast.showToast(S.of(context).shuffle_color_pool_success_toast, context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: S.of(context).more_settings_title,
      body: SettingsListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SettingsSurface(child: AdaptiveAppearanceSwitch()),
          const SizedBox(height: 16),
          SettingsSurface(
            child: Column(
              children: [
                SettingsTile(
                  title: Text(S.of(context).change_theme_mode_title),
                  subtitle: Text(S.of(context).change_theme_mode_subtitle),
                  trailing: FutureBuilder<int>(
                    future: _getThemeIndex(),
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsDropdown<int>(
                              value: snapshot.data,
                              items: const [
                                SettingsOption(
                                  child: Row(
                                    children: [
                                      Icon(Icons.settings),
                                      Text('跟随系统'),
                                    ],
                                  ),
                                  value: 0,
                                ),
                                SettingsOption(
                                  child: Row(
                                    children: [
                                      Icon(Icons.wb_sunny),
                                      Text('浅色模式'),
                                    ],
                                  ),
                                  value: 1,
                                ),
                                SettingsOption(
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_moon),
                                      Text('深色模式'),
                                    ],
                                  ),
                                  value: 2,
                                ),
                              ],
                              onChanged: (value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 12,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).changeThemeMode(value ?? 0);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).shuffle_color_pool_title),
                  subtitle: Text(S.of(context).shuffle_color_pool_subtitle),
                  onTap: _resetCourseColors,
                ),
                // TODO: Refresh multi times when changing themes.
                const ThemeChanger(),
                SettingsTile(
                  title: Text(S.of(context).use_material3_scheme_light_title),
                  subtitle: Text(
                    S.of(context).use_material3_scheme_light_subtitle,
                  ),
                  trailing: SettingsSwitch(
                    value: ScopedModel.of<MainStateModel>(
                      context,
                    ).material3ColorForLight,
                    onChanged: (v) {
                      UmengCommonSdk.onEvent("more_setting", {
                        "type": 20,
                        "result": v.toString(),
                      });
                      ScopedModel.of<MainStateModel>(
                        context,
                      ).changeMaterial3Color(light: v);
                      setState(() {});
                    },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).use_material3_scheme_dark_title),
                  subtitle: Text(
                    S.of(context).use_material3_scheme_dark_subtitle,
                  ),
                  trailing: SettingsSwitch(
                    value: ScopedModel.of<MainStateModel>(
                      context,
                    ).material3ColorForDark,
                    onChanged: (v) {
                      UmengCommonSdk.onEvent("more_setting", {
                        "type": 21,
                        "result": v.toString(),
                      });
                      ScopedModel.of<MainStateModel>(
                        context,
                      ).changeMaterial3Color(dark: v);
                      setState(() {});
                    },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).if_show_weekend_title),
                  subtitle: Text(S.of(context).if_show_weekend_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getShowWeekend(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 6,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowWeekend(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).if_show_classtime_title),
                  subtitle: Text(S.of(context).if_show_classtime_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getShowClassTime(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 7,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowClassTime(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).if_show_freeclass_title),
                  subtitle: Text(S.of(context).if_show_freeclass_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getShowFreeClass(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 8,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowFreeClass(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(
                    S.of(context).if_show_non_current_week_courses_title,
                  ),
                  subtitle: Text(
                    S.of(context).if_show_non_current_week_courses_subtitle,
                  ),
                  trailing: FutureBuilder<bool>(
                    future: _getShowNonCurrentWeekCourses(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 22,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowNonCurrentWeekCourses(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).show_month_title),
                  subtitle: Text(S.of(context).show_month_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getShowMonth(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 9,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowMonth(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).show_date_title),
                  subtitle: Text(S.of(context).show_date_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getShowDate(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 10,
                                  "result": value.toString(),
                                });
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setShowDate(value);
                                setState(() {});
                              },
                            );
                          }
                        },
                  ),
                ),
                SettingsTile(
                  title: Text(S.of(context).force_zoom_title),
                  subtitle: Text(S.of(context).force_zoom_subtitle),
                  trailing: FutureBuilder<bool>(
                    future: _getForceZoom(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(width: 0);
                          } else {
                            return SettingsSwitch(
                              value: snapshot.data!,
                              onChanged: (bool value) {
                                ScopedModel.of<MainStateModel>(
                                  context,
                                ).setForceZoom(value);
                                UmengCommonSdk.onEvent("more_setting", {
                                  "type": 11,
                                  "result": value.toString(),
                                });
                                setState(() {
                                  showCustomClassHeight = !value;
                                });
                              },
                            );
                          }
                        },
                  ),
                ),
                showCustomClassHeight
                    ? SettingsTile(
                        title: Text(S.of(context).class_height_title),
                        subtitle: Text(S.of(context).class_height_subtitle),
                        trailing: FutureBuilder<int>(
                          future: _getClassHeight(),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<int> snapshot,
                              ) {
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
                                    ),
                                  );
                                }
                              },
                        ),
                      )
                    : Container(width: 0),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<bool> _getShowNonCurrentWeekCourses() async {
    return await ScopedModel.of<MainStateModel>(
      context,
    ).getShowNonCurrentWeekCourses();
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
}
