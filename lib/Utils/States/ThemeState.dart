// import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/ThemeUtil.dart';
import '../../Resources/Constant.dart';

mixin ThemeStateModel on Model {
  Future<void> initThemeState() async {
    final sp = await SharedPreferences.getInstance();

    _themeIndex = sp.getInt("themeIndex") ?? 0;
    _themeModeIndex = sp.getInt("themeModeIndex") ?? 0;
    _themeCustomColor = sp.getString("themeCustomColor") ?? '';

    _material3ColorForLight = sp.getBool("themeMaterial3ColorForLight") ?? false;
    _material3ColorForDark = sp.getBool("themeMaterial3ColorForDark") ?? true;

    ThemeRuntimeConfig.material3Light = _material3ColorForLight;
    ThemeRuntimeConfig.material3Dark = _material3ColorForDark;

    notifyListeners();
  }

  int? _themeIndex;

  get themeIndex => _themeIndex;

  void changeTheme(int themeIndex) async {
    _themeIndex = themeIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("themeIndex", themeIndex);
  }

  Future<int> getTheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _themeIndex = sp.getInt("themeIndex") ?? 0;
    return themeIndex;
  }

  int? _themeModeIndex;

  get themeMode => (_themeModeIndex == null)
      ? null
      : Constant.themeModeList[_themeModeIndex!];

  get themeModeIndex => _themeModeIndex;

  void changeThemeMode(int themeModeIndex) async {
    _themeModeIndex = themeModeIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("themeModeIndex", themeModeIndex);
  }

  Future<int> getThemeMode() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _themeModeIndex = sp.getInt("themeModeIndex") ?? 0;
    return themeModeIndex;
  }

  String? _themeCustomColor;

  get themeCustomColor => _themeCustomColor;

  void changeCustomTheme(String themeCustomColor) async {
    _themeCustomColor = themeCustomColor;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("themeCustomColor", themeCustomColor);
  }

  Future<String> getCustomTheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _themeCustomColor = sp.getString("themeCustomColor") ?? '';
    return themeCustomColor;
  }

  bool _material3ColorForLight = false;
  bool _material3ColorForDark = true;

  bool get material3ColorForLight => _material3ColorForLight;
  bool get material3ColorForDark => _material3ColorForDark;

  void changeMaterial3Color({ bool? light, bool? dark }) async {
    if (light != null) _material3ColorForLight = light;
    if (dark != null) _material3ColorForDark = dark;

    ThemeRuntimeConfig.material3Light = _material3ColorForLight;
    ThemeRuntimeConfig.material3Dark = _material3ColorForDark;

    notifyListeners();

    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("themeMaterial3ColorForLight", _material3ColorForLight);
    sp.setBool("themeMaterial3ColorForDark", _material3ColorForDark);
  }

  Future<bool> getMaterial3ColorForLight() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _material3ColorForLight = sp.getBool("themeMaterial3ColorForLight") ?? false;
    return _material3ColorForLight; 
  }

  Future<bool> getMaterial3ColorForDark() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _material3ColorForDark = sp.getBool("themeMaterial3ColorForDark") ?? true;
    return _material3ColorForDark; 
  }
}

//import 'package:flutter/material.dart';
//
//// How to use: Any Widget in the app can access the ThemeChanger
//// because it is an InheritedWidget. Then the Widget can call
//// themeChanger.theme = [blah] to change the theme. The ThemeChanger
//// then accesses AppThemeState by using the _themeGlobalKey, and
//// the ThemeChanger switches out the old ThemeData for the new
//// ThemeData in the AppThemeState (which causes a re-render).
//
//final _themeGlobalKey = new GlobalKey(debugLabel: 'app_theme');
//
//class AppTheme extends StatefulWidget {
//
//  final child;
//
//  AppTheme({
//    this.child,
//  }) : super(key: _themeGlobalKey);
//
//  @override
//  AppThemeState createState() => new AppThemeState();
//}
//
//class AppThemeState extends State<AppTheme> {
//
//  ThemeData _theme = new ThemeData(
//    primarySwatch: Colors.pink,
//  );
//
//  set theme(newTheme) {
//    if (newTheme != _theme) {
//      setState(() => _theme = newTheme);
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return new ThemeChanger(
//      appThemeKey: _themeGlobalKey,
//      child: new Theme(
//        data: _theme,
//        child: widget.child,
//      ),
//    );
//  }
//}
//
//class ThemeChanger extends InheritedWidget {
//
//  static ThemeChanger of(BuildContext context) {
//    return context.inheritFromWidgetOfExactType(ThemeChanger);
//  }
//
//  final ThemeData theme;
//  final GlobalKey _appThemeKey;
//
//  ThemeChanger({
//    appThemeKey,
//    this.theme,
//    child
//  }) : _appThemeKey = appThemeKey, super(child: child);
//
//  set appTheme(AppThemeOption theme) {
//    switch (theme) {
//      case AppThemeOption.experimental:
//        (_appThemeKey.currentState as AppThemeState)?.theme = EXPERIMENT_THEME;
//        break;
//      case AppThemeOption.dev:
//        (_appThemeKey.currentState as AppThemeState)?.theme = DEV_THEME;
//        break;
//    }
//  }
//
//  @override
//  bool updateShouldNotify(ThemeChanger oldWidget) {
//    return oldWidget.theme == theme;
//  }
//
//}
