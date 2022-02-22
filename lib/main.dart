import 'dart:io';

import 'package:flutter/services.dart';

import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

// import 'package:talkingdata_sdk_plugin/talkingdata_sdk_plugin.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';
import 'Pages/CourseTable/CourseTableView.dart';
import 'Resources/Themes.dart';
import 'Resources/Constant.dart';
import 'Utils/States/MainState.dart';
import 'Utils/InitUtil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initialize the app config.
  List themeConf = await InitUtil.initialize();
  //初始化组件化基础库, 所有友盟业务SDK都必须调用此初始化接口。
  UmengCommonSdk.initCommon(
      '5f8ef217fac90f1c19a7b0f3', '5f9e1efa1c520d30739d2737', 'Umeng');
  UmengCommonSdk.setPageCollectionModeAuto();
  // UmengCommonSdk.onEvent("privacy_accept", {"result":"accept"});

  /// 原生安卓上去除状态栏遮罩
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
  runApp(
      MyApp(themeConf[0], Constant.themeModeList[themeConf[1]], themeConf[2]));
}

class MyApp extends StatefulWidget {
  final int themeIndex;
  final ThemeMode themeMode;
  final String themeCustom;

  const MyApp(this.themeIndex, this.themeMode, this.themeCustom, {Key? key})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
          builder: (context, child, model) {
            // print("MainView rebuild.");
            ThemeData lightTheme;
            ThemeData darkTheme;
            int themeIndex = model.themeIndex ?? widget.themeIndex;
            String customTheme = model.themeCustomColor ?? widget.themeCustom;
            if (themeIndex < themeDataList.length || customTheme == '') {
              lightTheme = themeDataList[themeIndex];
              darkTheme = darkThemeDataList[themeIndex];
            } else {
              lightTheme = getThemeData(customTheme, Brightness.light);
              darkTheme = getThemeData(customTheme, Brightness.dark);
            }
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (BuildContext context) => S.of(context).app_name,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              title: '南哪课表',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: model.themeMode ?? widget.themeMode,
              home: const CourseTableView(),
            );
          },
        ));
  }
}
