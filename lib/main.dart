import 'generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';
import 'Pages/MainView.dart';
import 'Resources/Themes.dart';
import 'Utils/States/MainState.dart';
import 'Utils/InitUtil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initialize the app config.
  int themeIndex = await InitUtil.Initialize();
  runApp(MyApp(themeIndex));
}

class MyApp extends StatefulWidget {
  final int themeIndex;

  MyApp(this.themeIndex);

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
            print("MainView rebuild.");
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (BuildContext context) => S.of(context).app_name,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate
              ],
              supportedLocales: S.delegate.supportedLocales,
              title: '南哪课表',
              theme: themeDataList[model.themeIndex != null
                  ? model.themeIndex
                  : widget.themeIndex],
              home: MainView(),
            );
          },
        ));
  }
}
