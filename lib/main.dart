import 'dart:io';

import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'Utils/HomeWidgetUtil.dart';
import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

// import 'package:talkingdata_sdk_plugin/talkingdata_sdk_plugin.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';
import 'Pages/CourseTable/CourseTableView.dart';
import 'Resources/Themes.dart';
import 'Utils/States/MainState.dart';
import 'Utils/InitUtil.dart';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return await HomeWidgetUtil().updateWidget();
  });
}

void main() async {
  bool isInDebugMode = false;

  WidgetsFlutterBinding.ensureInitialized();
  //Initialize the app config.
  int themeIndex = await InitUtil.initialize();
  //初始化组件化基础库, 所有友盟业务SDK都必须调用此初始化接口。
  UmengCommonSdk.initCommon(
      '5f8ef217fac90f1c19a7b0f3', '5f9e1efa1c520d30739d2737', 'Umeng');
  UmengCommonSdk.setPageCollectionModeAuto();
  // UmengCommonSdk.onEvent("privacy_accept", {"result":"accept"});
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
      isInDebugMode // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  if (Platform.isAndroid) {
    /// 原生安卓上去除状态栏遮罩
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
  Workmanager().registerPeriodicTask("1", "simplePeriodicTask",
      frequency: const Duration(minutes: 15));
  isInDebugMode ? Workmanager().registerOneOffTask("2", "simpleTask") : null;
  runApp(MyApp(themeIndex));
}

class MyApp extends StatefulWidget {
  final int themeIndex;

  const MyApp(this.themeIndex, {Key? key}) : super(key: key);

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
              theme: themeDataList[model.themeIndex ?? widget.themeIndex],
              home: const CourseTableView(),
            );
          },
        ));
  }
}
